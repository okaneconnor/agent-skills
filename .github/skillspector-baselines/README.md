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

Generate a baseline by scanning the skill and saving the report, then commit it:

```bash
uv tool install git+https://github.com/NVIDIA/skillspector.git   # if not installed

# Replace <skill> with the directory name, e.g. mcp-builder
skillspector scan .github/skills/<skill> --no-llm \
  --format json --output .github/skillspector-baselines/<skill>.json
```

Review the file before committing — you are explicitly accepting every finding it
contains. Re-run the command to refresh it when the skill changes and new findings
are genuinely acceptable.

> Verify the exact baseline flag/format against `skillspector scan --help` for the
> version you install; this repo pins to `main` (latest), so behaviour can evolve.
