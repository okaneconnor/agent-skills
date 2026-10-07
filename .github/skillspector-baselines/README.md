# SkillSpector baselines

The `scan-skills.yml` workflow scans each changed skill with
[NVIDIA SkillSpector](https://github.com/NVIDIA/SkillSpector). Some skills carry
findings that have been **reviewed and accepted** — for example the vendored
`mcp-builder` and `skill-creator` skills ship a `scripts/` directory that a
scanner will flag as executable / network-capable code.

To stop those known findings from re-failing or re-noising every PR, commit a
**baseline** for the skill here. The workflow applies it automatically when a
file named `<skill-name>.json` exists in this directory, after which only **new**
findings (not present in the baseline) are reported.

## Creating / updating a baseline

Generate a baseline with SkillSpector's `baseline` command, then commit it:

```bash
uv tool install git+https://github.com/NVIDIA/skillspector.git   # if not installed

# Replace <skill> with the directory name, e.g. mcp-builder
skillspector baseline .github/skills/<skill> --no-llm \
  --reason "Reviewed: <why these findings are acceptable>" \
  --output .github/skillspector-baselines/<skill>.json

# Confirm the gate now passes (exit 0, findings reported as suppressed)
skillspector scan .github/skills/<skill> --no-llm \
  --baseline .github/skillspector-baselines/<skill>.json
```

Use `skillspector baseline`, not `skillspector scan --format json`: a scan report
is not a baseline file, and passing one to `--baseline` suppresses nothing.

Review the file before committing — you are explicitly accepting every finding it
contains. Re-run the command to refresh it when the skill changes and new findings
are genuinely acceptable.

> Verify the exact baseline flag/format against `skillspector scan --help` for the
> version you install; this repo pins to `main` (latest), so behaviour can evolve.
