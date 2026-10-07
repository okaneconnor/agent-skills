# Notice

This skill is vendored from [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/systematic-debugging).

- **Upstream:** `github.com/obra/superpowers`
- **Path:** `skills/systematic-debugging`
- **Commit:** `8ca22dba9a94f28898bbce59f2537ff4d87c747d` (2026-09-25)
- **License:** MIT — see `LICENSE.txt` in this directory

The skill content is preserved verbatim from upstream so that updates can be merged cleanly. To refresh, re-copy from the upstream path and bump the commit SHA above.

## Running without the Superpowers plugin

This repo ships the skill on its own, without the Superpowers plugin harness: the `SessionStart` hook and the `using-superpowers` bootstrap skill are deliberately not vendored. Upstream text refers to sibling skills with the plugin namespace (e.g. `superpowers:test-driven-development`); here each sibling is the plain skill of the same name, installed by the `packages/workflow` bundle.

## SkillSpector baseline

Static findings for this skill are accepted in `.github/skillspector-baselines/systematic-debugging.json`. Each was reviewed and judged benign (scanner pattern matches on documentation text, or expected behaviour of the bundled helper scripts); the pull request that added this skill lists every finding and why it was accepted.
