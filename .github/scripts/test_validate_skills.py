#!/usr/bin/env python3
"""
Unit tests for validate_skills.py.

Each test builds a synthetic mini-repo on disk, runs the validator, and
asserts it raises (or does not raise) the expected error. Run with:

    python3 -m unittest .github/scripts/test_validate_skills.py
"""

from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import validate_skills as vs  # noqa: E402


SKILL_TEMPLATE = """\
---
name: {name}
description: {description}
---
# Heading

## When to Use
Test fixture body.
"""

BUNDLE_TEMPLATE = """\
name: {name}-skills
version: 1.0.0
description: Bundle for tests.
author: test
license: MIT
target: all
dependencies:
  apm:
{deps}
"""

ROOT_TEMPLATE = """\
name: agent-skills
version: 0.0.0
description: test root
author: test
license: MIT
target: all
dependencies:
  apm:
{bundles}
"""


def make_repo(tmp: Path, skills: dict, bundles: dict, root_bundles: list) -> Path:
    repo = tmp / "repo"
    (repo / ".github" / "skills").mkdir(parents=True)
    (repo / "packages").mkdir(parents=True)

    for skill_name, content in skills.items():
        skill_dir = repo / ".github" / "skills" / skill_name
        skill_dir.mkdir(parents=True, exist_ok=True)
        (skill_dir / "SKILL.md").write_text(content, encoding="utf-8")

    for bundle_name, content in bundles.items():
        bundle_dir = repo / "packages" / bundle_name
        (bundle_dir / ".apm").mkdir(parents=True, exist_ok=True)
        (bundle_dir / ".apm" / ".gitkeep").touch()
        (bundle_dir / "apm.yml").write_text(content, encoding="utf-8")

    deps = "\n".join(f"    - okaneconnor/agent-skills/packages/{b}" for b in root_bundles)
    (repo / "apm.yml").write_text(ROOT_TEMPLATE.format(bundles=deps), encoding="utf-8")
    return repo


def standard_skill(name: str, description: str = None) -> str:
    description = description or (
        f"This is a long enough description for the {name} skill that meets "
        f"the minimum length requirement. Use when running unit tests against "
        f"the validator script."
    )
    return SKILL_TEMPLATE.format(name=name, description=description)


def standard_bundle(name: str, skill_names: list) -> str:
    deps = "\n".join(
        f"    - okaneconnor/agent-skills/.github/skills/{s}" for s in skill_names
    )
    return BUNDLE_TEMPLATE.format(name=name, deps=deps)


class ValidatorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="validate-skills-test-"))

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def run_validator(self, repo: Path) -> vs.Result:
        skills, bundles = vs.discover(repo)
        known = {s.name for s in skills}
        overall = vs.Result()
        seen = {}
        referenced = set()

        for s in skills:
            r = vs.validate_skill(s)
            if s.name in seen:
                r.errors.append(f"[{s.name}] duplicate skill name")
            seen[s.name] = True
            overall.merge(r)
        for b in bundles:
            r, refs = vs.validate_bundle(b, known)
            referenced |= refs
            overall.merge(r)
        overall.merge(vs.validate_root(repo, bundles))
        for o in sorted(known - referenced):
            overall.errors.append(f"[orphan] skill '{o}' is not listed in any bundle")
        return overall

    def assert_error_contains(self, result: vs.Result, fragment: str):
        self.assertTrue(
            any(fragment in e for e in result.errors),
            f"expected an error containing {fragment!r}, got: {result.errors}",
        )

    def assert_no_errors(self, result: vs.Result):
        self.assertEqual(result.errors, [], f"unexpected errors: {result.errors}")

    # ---------- happy path ----------

    def test_minimal_valid_repo_passes(self):
        repo = make_repo(
            self.tmp,
            skills={"foo": standard_skill("foo")},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_no_errors(self.run_validator(repo))

    # ---------- frontmatter ----------

    def test_missing_name_field_is_error(self):
        skill = "---\ndescription: Use when running tests on the validator script. Padding to clear the eighty char minimum.\n---\n## When to Use\nx\n"
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "missing frontmatter field: name")

    def test_empty_name_value_is_error(self):
        skill = '---\nname: ""\ndescription: Long enough description with use when triggers and additional padding for the minimum length requirement.\n---\n## When to Use\nx\n'
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "'name' is empty or null")

    def test_null_description_is_error(self):
        skill = "---\nname: foo\ndescription: ~\n---\n## When to Use\nx\n"
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "'description' is empty or null")

    def test_short_description_is_error(self):
        skill = "---\nname: foo\ndescription: too short\n---\n## When to Use\nx\n"
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "min 80")

    def test_name_directory_mismatch_is_error(self):
        skill = standard_skill("not-foo")
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "does not match directory")

    def test_codefence_wrapped_frontmatter_is_error(self):
        skill = "```yaml\n---\nname: foo\ndescription: " + "x" * 100 + "\n---\n```\n## When to Use\nx\n"
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "wrapped in a code block")

    # ---------- body ----------

    def test_missing_when_to_use_is_error(self):
        skill = (
            "---\nname: foo\ndescription: Long enough description with use when triggers "
            "and additional padding for the minimum length requirement.\n---\n# foo\nbody\n"
        )
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "## When to Use")

    def test_oversize_skill_is_error(self):
        body = "## When to Use\n" + ("padding line\n" * 600)
        skill = (
            "---\nname: foo\ndescription: Long enough description with use when triggers "
            "and additional padding for the minimum length requirement.\n---\n" + body
        )
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "max 500")

    def test_broken_reference_link_is_error(self):
        skill = (
            "---\nname: foo\ndescription: Long enough description with use when triggers "
            "and additional padding for the minimum length requirement.\n---\n## When to Use\n"
            "See [missing](references/missing.md) for details.\n"
        )
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "broken reference link")

    # ---------- vendored ----------

    def test_vendored_skill_without_notice_is_error(self):
        repo = make_repo(
            self.tmp,
            skills={"foo": standard_skill("foo")},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        # Add LICENSE.txt without NOTICE.md → should fail
        (repo / ".github" / "skills" / "foo" / "LICENSE.txt").write_text("Apache 2.0", encoding="utf-8")
        self.assert_error_contains(self.run_validator(repo), "missing NOTICE.md")

    def test_vendored_skill_with_notice_passes_when_to_use_relaxed(self):
        # Vendored skills don't need '## When to Use' — verify exemption works
        skill = (
            "---\nname: foo\ndescription: Vendored skill description that is long enough to clear the eighty character minimum length requirement comfortably.\n"
            "---\n# foo\nupstream content has no When to Use heading\n"
        )
        repo = make_repo(
            self.tmp,
            skills={"foo": skill},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        (repo / ".github" / "skills" / "foo" / "LICENSE.txt").write_text("Apache 2.0", encoding="utf-8")
        (repo / ".github" / "skills" / "foo" / "NOTICE.md").write_text("# Notice\nVendored.", encoding="utf-8")
        self.assert_no_errors(self.run_validator(repo))

    # ---------- bundle ----------

    def test_bundle_referencing_missing_skill_is_error(self):
        repo = make_repo(
            self.tmp,
            skills={"foo": standard_skill("foo")},
            bundles={"a": standard_bundle("a", ["foo", "ghost"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "non-existent skill 'ghost'")

    def test_bundle_dep_with_trailing_path_is_error(self):
        bundle = BUNDLE_TEMPLATE.format(
            name="a",
            deps="    - okaneconnor/agent-skills/.github/skills/foo/SKILL.md",
        )
        repo = make_repo(
            self.tmp,
            skills={"foo": standard_skill("foo")},
            bundles={"a": bundle},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "must reference the skill directory")

    def test_bundle_missing_required_field_is_error(self):
        bundle = (
            "name: a-skills\nversion: 1.0.0\nauthor: test\nlicense: MIT\ntarget: all\n"
            "dependencies:\n  apm:\n    - okaneconnor/agent-skills/.github/skills/foo\n"
        )
        repo = make_repo(
            self.tmp,
            skills={"foo": standard_skill("foo")},
            bundles={"a": bundle},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "missing field: description")

    # ---------- repo wiring ----------

    def test_orphan_skill_is_error(self):
        repo = make_repo(
            self.tmp,
            skills={"foo": standard_skill("foo"), "orphan": standard_skill("orphan")},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a"],
        )
        self.assert_error_contains(self.run_validator(repo), "[orphan] skill 'orphan'")

    def test_bundle_on_disk_not_in_root_is_error(self):
        repo = make_repo(
            self.tmp,
            skills={"foo": standard_skill("foo")},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=[],  # root doesn't list any bundles
        )
        self.assert_error_contains(self.run_validator(repo), "exists on disk but is not in root apm.yml")

    def test_bundle_in_root_not_on_disk_is_error(self):
        repo = make_repo(
            self.tmp,
            skills={"foo": standard_skill("foo")},
            bundles={"a": standard_bundle("a", ["foo"])},
            root_bundles=["a", "ghost"],
        )
        self.assert_error_contains(self.run_validator(repo), "'packages/ghost'")


if __name__ == "__main__":
    unittest.main()
