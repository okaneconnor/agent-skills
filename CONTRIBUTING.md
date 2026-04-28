# Contributing to agent-skills

Thanks for proposing a new skill, bundle, or fix. This document is the source of truth for what CI enforces on every PR — keep your change inside these lines and the `Validate Agent Skills` workflow will go green.

The validator lives at [`.github/scripts/validate_skills.py`](.github/scripts/validate_skills.py) and runs via [`.github/workflows/validate-skills.yml`](.github/workflows/validate-skills.yml). Run it locally before opening a PR:

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install pyyaml
python3 .github/scripts/validate_skills.py
```

---

## Repository layout

```
.github/
├── skills/<skill-name>/
│   ├── SKILL.md          # required
│   ├── references/       # optional, use for progressive disclosure
│   ├── LICENSE.txt       # required for vendored skills only
│   └── NOTICE.md         # required for vendored skills only
├── scripts/validate_skills.py
└── workflows/validate-skills.yml
packages/<bundle-name>/
├── apm.yml               # required
└── .apm/.gitkeep         # required (matches APM convention)
apm.yml                   # root meta-package, lists every bundle
```

---

## What CI enforces

### Skills (`.github/skills/<name>/SKILL.md`)

| Rule | Why |
|---|---|
| `SKILL.md` exists | Without it, the skill cannot load. |
| File starts with `---` (no code-fence wrapping) | Wrapping breaks frontmatter parsing. |
| Frontmatter parses as valid YAML | Ditto. |
| `name` and `description` fields present | Both are required by the Agent Skills specification. |
| `name` matches the directory name | Stops divergence between the on-disk path and the loaded identity. |
| Description ≥ 80 characters | Short descriptions invoke unreliably. Include trigger phrases. |
| Description ≤ 1024 characters (warning) | Descriptions live in every prompt that lists available skills — keep them lean. |
| Description contains *"Use when ..."* triggers (warning) | Reliable invocation depends on trigger phrasing in the description. |
| `## When to Use` section present in the body | Convention used across this repo so users / agents can scan quickly. |
| ≤ 500 lines and ≤ ~5 000 tokens | Spec recommendation. Move detail into `references/<file>.md`. |
| Every `references/<file>` link in `SKILL.md` resolves | Broken links waste a tool call when the agent tries to load. |

#### Vendored skills

If a skill carries an upstream `LICENSE.txt`, it is treated as **vendored** — we do not modify the upstream content, so we relax the body checks:

- `## When to Use` and the size limit are **not** enforced
- `NOTICE.md` is **required** alongside `LICENSE.txt`, citing the upstream commit
- Frontmatter, name-matches-directory, description bounds, and broken-link checks all still apply

### Bundles (`packages/<bundle>/apm.yml`)

Required fields: `name`, `version`, `description`, `author`, `license`, `target`, `dependencies`.

`dependencies.apm` must be a non-empty list. Every entry that points at this repo (`okaneconnor/agent-skills/.github/skills/<name>`) must reference a skill that actually exists on disk.

### Repository wiring

- Skill names are unique across the repo
- Every skill in `.github/skills/` is referenced by at least one bundle
- Every bundle in `packages/` is listed in the root `apm.yml` `dependencies.apm`

---

## Authoring a new first-party skill

1. **Pick the unit of work.** A skill should be a coherent, independently-useful capability. If you find yourself writing two unrelated workflows in one skill, split it.

2. **Create the skill folder:**

   ```
   .github/skills/<skill-name>/
   ├── SKILL.md
   └── references/                # optional
   ```

3. **Write the frontmatter** at the top of `SKILL.md`:

   ```yaml
   ---
   name: <skill-name>           # must equal the directory name
   description: <one paragraph, ≥80 chars, includes "Use when ..." triggers>
   ---
   ```

4. **Lead with `## When to Use`.** First section after the title. Tell the reader (and the agent) when this skill fires and when it should be skipped. Concrete trigger phrases beat abstract criteria.

5. **Keep the body inside the size budget.** ≤ 500 lines, ≤ ~5 000 tokens. If the topic is genuinely larger, use progressive disclosure — split detail into `references/<topic>.md` and link it from the body with a sentence that tells the agent *when* to load it (e.g. *"see [api-errors.md](references/api-errors.md) if the API returns a non-200"*).

6. **Spend context on what the agent doesn't already know.** Skip the things the agent has from training (what HTTP is, what a database migration is). Spend tokens on project-specific conventions, gotchas, defaults, and the exact tools to use.

7. **Pick defaults, not menus.** When several approaches could work, name one and mention alternatives briefly. Long lists of equally-weighted options leave the agent paralysed.

8. **Write procedures, not single-shot answers.** A skill should teach the agent *how to approach* a class of problems, not solve one specific instance.

9. **Include a gotchas section** when there are environment-specific facts that defy reasonable assumptions. These are some of the highest-value lines in any skill.

10. **Add the skill to a bundle.** Either drop it into an existing `packages/<bundle>/apm.yml` `dependencies.apm` list, or create a new bundle (see below).

## Authoring a new bundle

Use a new bundle when the skill represents a new domain that doesn't fit any existing one, or when it brings its own MCP server.

1. Create the directory and required files:

   ```bash
   mkdir -p packages/<bundle>/.apm
   touch packages/<bundle>/.apm/.gitkeep
   ```

2. Write `packages/<bundle>/apm.yml`:

   ```yaml
   name: <bundle>-skills
   version: 1.0.0
   description: >
     One paragraph describing the bundle and the skills it ships.
   author: <your-handle>
   license: MIT
   target: all

   dependencies:
     apm:
       - okaneconnor/agent-skills/.github/skills/<skill-name>
     mcp:                                        # only if needed
       - name: <name>
         registry: false
         transport: http
         url: "<mcp-server-url>"
   ```

3. **Wire into the root.** Add the bundle to `apm.yml` under `dependencies.apm`:

   ```yaml
   dependencies:
     apm:
       - okaneconnor/agent-skills/packages/<bundle>
   ```

4. If the bundle adds an MCP server, mirror it in [`.vscode/mcp.json`](.vscode/mcp.json) so local development works.

5. Update [`README.md`](README.md):
   - Structure tree
   - Skills table (a section per domain)
   - Install commands
   - Bundle "what's included" table

## Vendoring an upstream skill

When pulling a skill in from an external repository (e.g. `anthropics/skills`):

1. Copy the entire upstream skill directory into `.github/skills/<skill-name>/` verbatim, including `LICENSE.txt`. **Do not edit the upstream content** so future updates can be merged cleanly.

2. Add a `NOTICE.md` next to `LICENSE.txt` citing the upstream repo, the path, and the commit SHA you copied from. Example:

   ```markdown
   # Notice

   This skill is vendored from [<upstream-repo>](<url>).

   - **Upstream:** `<upstream-repo>`
   - **Path:** `skills/<name>`
   - **Commit:** `<sha>` (<date>)
   - **License:** see `LICENSE.txt`

   Content preserved verbatim so updates can be merged cleanly. To refresh,
   re-copy from the upstream path and bump the commit SHA above.
   ```

3. Add the vendored skill to a bundle whose `license:` field reflects the upstream license (use `Apache-2.0` for the `mcp-builder` / `skill-creator` family).

## Versioning

The root `apm.yml` `version:` does **not** bump on every PR. Multiple changes accumulate under the same version; only bump when there's a milestone or breaking change. Per-bundle `apm.yml` versions are independent — bump those when the bundle's contents materially change.

## Submitting the PR

- Run the validator locally and confirm it exits 0.
- Use a descriptive branch name (`add-<skill-name>-skill`, `fix-<bundle>-mcp-url`, etc.).
- The PR template will walk you through what changed and how to verify it. CI will re-run the validator on every push.

## Further reading

- [Agent Skills specification — best practices](https://agentskills.io/skill-creation/best-practices)
- [Agent Skills specification — progressive disclosure](https://agentskills.io/specification#progressive-disclosure)
- [APM (Agent Package Manager)](https://github.com/microsoft/apm)
