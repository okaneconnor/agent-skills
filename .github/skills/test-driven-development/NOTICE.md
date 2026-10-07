# Notice

This skill is vendored from [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/test-driven-development).

- **Upstream:** `github.com/obra/superpowers`
- **Path:** `skills/test-driven-development`
- **Commit:** `8ca22dba9a94f28898bbce59f2537ff4d87c747d` (2026-09-25)
- **License:** MIT — see `LICENSE.txt` in this directory

The skill content is preserved verbatim from upstream except for the local modification listed below. To refresh, re-copy from the upstream path, bump the commit SHA above, and re-apply it.

## Local modifications

- `SKILL.md` frontmatter `description` extended from 79 to 90 characters to meet this repo's 80-character minimum (`validate_skills.py`). Upstream: *"Use when implementing any feature or bugfix, before writing implementation code"*. Here: *"Use when implementing any feature, bugfix, or refactor, before writing implementation code"* (refactoring is already listed under the skill's own **When to Use**). Re-apply after refreshing.

## Running without the Superpowers plugin

This repo ships the skill on its own, without the Superpowers plugin harness: the `SessionStart` hook and the `using-superpowers` bootstrap skill are deliberately not vendored. Upstream text refers to sibling skills with the plugin namespace (e.g. `superpowers:test-driven-development`); here each sibling is the plain skill of the same name, installed by the `packages/workflow` bundle.
