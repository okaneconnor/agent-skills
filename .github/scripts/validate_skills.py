#!/usr/bin/env python3
"""
Validate the agent-skills repository on every PR and on push to main.

Errors fail the build. Warnings are logged but do not fail.

Per skill at .github/skills/<name>/SKILL.md
  - SKILL.md exists and is not wrapped in a code fence
  - YAML frontmatter parses cleanly and starts with '---'
  - Required frontmatter fields: name, description
  - Frontmatter `name` matches the directory name
  - Description length within bounds
  - Description contains "Use when ..." trigger phrasing
  - SKILL.md size within the 500-line / ~5 000-token window
  - '## When to Use' section present in the body
  - Every references/<file> link inside SKILL.md resolves
  - Vendored skills (those carrying LICENSE.txt) must also carry NOTICE.md

Per bundle at packages/<bundle>/apm.yml
  - apm.yml exists and parses
  - Required fields: name, version, description, author, license, target, dependencies
  - dependencies.apm references skills that exist on disk

Repository
  - Skill names are unique
  - Every skill is referenced by at least one bundle
  - Every bundle in packages/ is wired into the root apm.yml

Thresholds and conventions follow the published Agent Skills specification
recommendations on SKILL.md size, description quality, and progressive
disclosure via the references/ directory.

Usage:
    python3 .github/scripts/validate_skills.py [--repo-root .]
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is required. Install with `pip install pyyaml`.", file=sys.stderr)
    sys.exit(2)


# ---------- Tunable thresholds ----------

# Hard upper bounds aligned with the Agent Skills specification.
MAX_SKILL_LINES = 500
WARN_SKILL_LINES = 400
# Token approximation used by the spec: ~4 chars per token, so ~20 000 chars.
MAX_SKILL_CHARS = 20_000

# Description must be rich enough to disambiguate; not so long it dominates context.
MIN_DESCRIPTION_CHARS = 80
MAX_DESCRIPTION_CHARS = 1_024

REQUIRED_BUNDLE_FIELDS = ("name", "version", "description", "author", "license", "target", "dependencies")
REQUIRED_SKILL_FIELDS = ("name", "description")

# Repository-relative dependency prefix used by APM in this repo.
REPO_OWNER_PREFIX = "okaneconnor/agent-skills/"

# ----------------------------------------


@dataclass
class Result:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    def merge(self, other: "Result") -> None:
        self.errors.extend(other.errors)
        self.warnings.extend(other.warnings)

    @property
    def ok(self) -> bool:
        return not self.errors


def split_frontmatter(text: str) -> tuple[dict | None, str, str | None]:
    if not (text.startswith("---\n") or text.startswith("---\r\n")):
        return None, text, "must start with '---' frontmatter delimiter"

    parts = re.split(r"^---\s*$", text, maxsplit=2, flags=re.MULTILINE)
    if len(parts) < 3:
        return None, text, "frontmatter is not closed with a second '---'"

    fm_raw = parts[1]
    body = parts[2].lstrip("\n")

    try:
        fm = yaml.safe_load(fm_raw) or {}
    except yaml.YAMLError as exc:
        return None, body, f"frontmatter YAML parse error: {exc}"

    if not isinstance(fm, dict):
        return None, body, "frontmatter must be a mapping"

    return fm, body, None


def collapse_whitespace(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def is_vendored_skill(skill_dir: Path) -> bool:
    return (skill_dir / "LICENSE.txt").exists()


def validate_skill(skill_dir: Path) -> Result:
    res = Result()
    label = skill_dir.name
    skill_md = skill_dir / "SKILL.md"
    vendored = is_vendored_skill(skill_dir)

    if not skill_md.exists():
        res.errors.append(f"[{label}] missing SKILL.md")
        return res

    text = skill_md.read_text(encoding="utf-8")

    if text.lstrip().startswith("```"):
        res.errors.append(f"[{label}] SKILL.md frontmatter is wrapped in a code block")
        return res

    fm, body, err = split_frontmatter(text)
    if err or fm is None:
        res.errors.append(f"[{label}] {err}")
        return res

    for field_name in REQUIRED_SKILL_FIELDS:
        if field_name not in fm:
            res.errors.append(f"[{label}] missing frontmatter field: {field_name}")
        elif fm[field_name] is None or (isinstance(fm[field_name], str) and not fm[field_name].strip()):
            res.errors.append(f"[{label}] frontmatter field '{field_name}' is empty or null")

    fm_name = fm.get("name")
    if isinstance(fm_name, str) and fm_name.strip() and fm_name != skill_dir.name:
        res.errors.append(
            f"[{label}] frontmatter name '{fm_name}' does not match directory '{skill_dir.name}'"
        )

    desc = fm.get("description")
    if isinstance(desc, str) and desc.strip():
        desc_norm = collapse_whitespace(desc)
        if len(desc_norm) < MIN_DESCRIPTION_CHARS:
            res.errors.append(
                f"[{label}] description is {len(desc_norm)} chars (min {MIN_DESCRIPTION_CHARS}). "
                f"Short descriptions invoke unreliably — include trigger phrases."
            )
        elif len(desc_norm) > MAX_DESCRIPTION_CHARS:
            res.warnings.append(
                f"[{label}] description is {len(desc_norm)} chars (recommended max {MAX_DESCRIPTION_CHARS})"
            )

        if not vendored and not re.search(r"\buse\s+(when|this skill when)\b", desc_norm, re.IGNORECASE):
            res.warnings.append(
                f"[{label}] description does not contain 'Use when ...' triggers — invocation may be unreliable"
            )
    elif "description" in fm and fm["description"] is not None and not isinstance(fm["description"], str):
        res.errors.append(f"[{label}] frontmatter 'description' must be a string")

    if vendored:
        # Vendored skills are owned upstream — we validate licensing/attribution
        # and link integrity, but we do not enforce our convention on their body.
        if not (skill_dir / "NOTICE.md").exists():
            res.errors.append(
                f"[{label}] vendored skill (LICENSE.txt present) is missing NOTICE.md attribution"
            )
        for match in re.finditer(r"\(\.{0,2}/?references/([^)#]+?)(#[^)]+)?\)", body):
            rel = match.group(1)
            target = skill_dir / "references" / rel
            if not target.exists():
                res.errors.append(f"[{label}] broken reference link: references/{rel}")
        return res

    # First-party skill: full size + structural checks.
    line_count = text.count("\n") + 1
    char_count = len(text)
    if line_count > MAX_SKILL_LINES:
        res.errors.append(
            f"[{label}] SKILL.md is {line_count} lines (max {MAX_SKILL_LINES}). "
            f"Move detail to a references/ directory."
        )
    elif line_count > WARN_SKILL_LINES:
        res.warnings.append(
            f"[{label}] SKILL.md is {line_count} lines (warn at {WARN_SKILL_LINES}, hard limit {MAX_SKILL_LINES})"
        )

    if char_count > MAX_SKILL_CHARS:
        res.errors.append(
            f"[{label}] SKILL.md is ~{char_count // 4} tokens (max ~{MAX_SKILL_CHARS // 4}). "
            f"Move detail to a references/ directory."
        )

    if not re.search(r"^##\s+When to Use\b", body, re.MULTILINE | re.IGNORECASE):
        res.errors.append(
            f"[{label}] missing '## When to Use' section in body — required for reliable invocation"
        )

    for match in re.finditer(r"\(\.{0,2}/?references/([^)#]+?)(#[^)]+)?\)", body):
        rel = match.group(1)
        target = skill_dir / "references" / rel
        if not target.exists():
            res.errors.append(f"[{label}] broken reference link: references/{rel}")

    return res


def validate_bundle(bundle_dir: Path, known_skills: set[str]) -> tuple[Result, set[str]]:
    res = Result()
    referenced: set[str] = set()
    label = bundle_dir.name
    apm_yml = bundle_dir / "apm.yml"

    if not apm_yml.exists():
        res.errors.append(f"[bundle:{label}] missing apm.yml")
        return res, referenced

    try:
        data = yaml.safe_load(apm_yml.read_text(encoding="utf-8")) or {}
    except yaml.YAMLError as exc:
        res.errors.append(f"[bundle:{label}] apm.yml parse error: {exc}")
        return res, referenced

    if not isinstance(data, dict):
        res.errors.append(f"[bundle:{label}] apm.yml is not a mapping")
        return res, referenced

    for fld in REQUIRED_BUNDLE_FIELDS:
        if fld not in data:
            res.errors.append(f"[bundle:{label}] apm.yml missing field: {fld}")

    deps = data.get("dependencies") or {}
    apm_deps = deps.get("apm") or []
    if not isinstance(apm_deps, list) or not apm_deps:
        res.errors.append(f"[bundle:{label}] dependencies.apm must be a non-empty list")
        return res, referenced

    for dep in apm_deps:
        if not isinstance(dep, str):
            res.errors.append(f"[bundle:{label}] non-string entry in dependencies.apm: {dep!r}")
            continue
        if not dep.startswith(REPO_OWNER_PREFIX):
            res.warnings.append(
                f"[bundle:{label}] dependency '{dep}' does not start with '{REPO_OWNER_PREFIX}' — "
                f"intentional cross-repo reference?"
            )
            continue

        rel = dep[len(REPO_OWNER_PREFIX):].rstrip("/")
        if rel.startswith(".github/skills/"):
            tail = rel[len(".github/skills/"):]
            if "/" in tail:
                res.errors.append(
                    f"[bundle:{label}] dependency '{dep}' must reference the skill directory, "
                    f"not a path inside it (drop everything after '/.github/skills/<name>')"
                )
                continue
            skill_name = tail
            referenced.add(skill_name)
            if skill_name not in known_skills:
                res.errors.append(
                    f"[bundle:{label}] dependency '{dep}' points to non-existent skill '{skill_name}'"
                )
        elif rel.startswith("packages/"):
            pass
        else:
            res.warnings.append(f"[bundle:{label}] unrecognised dependency path shape: {dep}")

    return res, referenced


def validate_root(root: Path, bundle_dirs: list[Path]) -> Result:
    res = Result()
    root_yml = root / "apm.yml"
    if not root_yml.exists():
        res.errors.append("[root] apm.yml missing at repo root")
        return res

    try:
        data = yaml.safe_load(root_yml.read_text(encoding="utf-8")) or {}
    except yaml.YAMLError as exc:
        res.errors.append(f"[root] apm.yml parse error: {exc}")
        return res

    deps = (data.get("dependencies") or {}).get("apm") or []
    referenced_bundles: set[str] = set()
    for dep in deps:
        if not isinstance(dep, str):
            continue
        if dep.startswith(REPO_OWNER_PREFIX + "packages/"):
            referenced_bundles.add(dep.split("packages/", 1)[1].split("/", 1)[0])

    on_disk = {b.name for b in bundle_dirs}
    missing_in_root = on_disk - referenced_bundles
    extra_in_root = referenced_bundles - on_disk
    for bundle in sorted(missing_in_root):
        res.errors.append(f"[root] bundle 'packages/{bundle}' exists on disk but is not in root apm.yml")
    for bundle in sorted(extra_in_root):
        res.errors.append(f"[root] root apm.yml references 'packages/{bundle}' but the directory does not exist")

    return res


def discover(root: Path) -> tuple[list[Path], list[Path]]:
    skills_root = root / ".github" / "skills"
    packages_root = root / "packages"
    skills = sorted(p for p in skills_root.iterdir() if p.is_dir()) if skills_root.exists() else []
    bundles = sorted(p for p in packages_root.iterdir() if p.is_dir()) if packages_root.exists() else []
    return skills, bundles


def print_section(title: str) -> None:
    print(f"\n=== {title} ===")


def print_result(label: str, res: Result) -> None:
    status = "PASS" if res.ok else "FAIL"
    print(f"  {status:4}  {label}")
    for e in res.errors:
        print(f"    x {e}")
    for w in res.warnings:
        print(f"    ! {w}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", help="Path to repo root (default: cwd)")
    args = parser.parse_args()
    root = Path(args.repo_root).resolve()

    skills, bundles = discover(root)
    known_skill_names = {s.name for s in skills}

    overall = Result()

    print_section("Skills")
    if not skills:
        print("  (no skills found)")
    seen_names: dict[str, str] = {}
    for skill_dir in skills:
        res = validate_skill(skill_dir)
        if skill_dir.name in seen_names:
            res.errors.append(
                f"[{skill_dir.name}] duplicate skill name (also at {seen_names[skill_dir.name]})"
            )
        seen_names[skill_dir.name] = str(skill_dir)
        print_result(skill_dir.name, res)
        overall.merge(res)

    print_section("Bundles")
    if not bundles:
        print("  (no bundles found)")
    referenced_skills: set[str] = set()
    for bundle_dir in bundles:
        res, refs = validate_bundle(bundle_dir, known_skill_names)
        referenced_skills |= refs
        print_result(bundle_dir.name, res)
        overall.merge(res)

    print_section("Repository")
    res = validate_root(root, bundles)
    print_result("root apm.yml <-> packages/", res)
    overall.merge(res)

    orphans = known_skill_names - referenced_skills
    orphan_res = Result()
    if orphans:
        for o in sorted(orphans):
            orphan_res.errors.append(f"[orphan] skill '{o}' is not listed in any bundle's dependencies.apm")
    print_result("every skill listed in some bundle", orphan_res)
    overall.merge(orphan_res)

    print_section("Summary")
    print(f"  {len(skills)} skills, {len(bundles)} bundles")
    print(f"  errors:   {len(overall.errors)}")
    print(f"  warnings: {len(overall.warnings)}")

    if overall.errors:
        print("\nValidation FAILED.\n")
        return 1
    print("\nValidation PASSED.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
