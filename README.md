# Agent Skills

A growing collection of agent skills for AI coding assistants (Claude Code, GitHub Copilot, Cursor) packaged as installable bundles via [APM (Agent Package Manager)](https://github.com/microsoft/apm). Skills are domain-specific knowledge + workflow definitions that the assistant loads automatically when relevant.

## Structure

```
.github/
└── skills/
    ├── jira-skill/
    ├── excalidraw-diagram/
    ├── security-review/
    ├── coding-guidelines/
    ├── mcp-builder/        ← vendored from anthropics/skills (Apache-2.0)
    ├── skill-creator/      ← vendored from anthropics/skills (Apache-2.0)
    └── brainstorming/                    ← vendored from obra/superpowers (MIT)
packages/
├── jira/                ← Jira bundle (skill + Atlassian MCP)
│   ├── .apm/
│   └── apm.yml
├── diagramming/         ← Diagramming bundle (skill + Excalidraw MCP)
│   ├── .apm/
│   └── apm.yml
├── security/            ← Security bundle (skill, no MCP required)
│   ├── .apm/
│   └── apm.yml
├── builders/            ← Builder bundle (mcp-builder + skill-creator, no MCP required)
│   ├── .apm/
│   └── apm.yml
├── coding/              ← Coding-discipline bundle (no MCP required)
│   ├── .apm/
│   └── apm.yml
└── workflow/            ← Development-workflow bundle (vendored from obra/superpowers, no MCP required)
    ├── .apm/
    └── apm.yml
.vscode/mcp.json         ← MCP server config for VS Code / Copilot
apm.yml                  ← Top-level meta-package (installs all bundles)
```

## Prerequisites

### Always required

- A supported AI coding assistant: **Claude Code**, **GitHub Copilot Chat** (in VS Code), or **Cursor**
- [APM CLI](https://github.com/microsoft/apm) installed locally

### MCP servers

Some skills require an MCP server to be running. This repository's `.vscode/mcp.json` already wires up the required servers, and `apm install` will register them in any project where you install a bundle.

| MCP server | Skills that use it | Setup |
|---|---|---|
| **Atlassian MCP** (`https://mcp.atlassian.com/v1/mcp`) | `jira-skill` | Auto-registered by the `jira` bundle. Browser opens for OAuth on first use — no API tokens stored. |
| **Excalidraw MCP** (`https://mcp.excalidraw.com`) | `excalidraw-diagram` | Auto-registered by the `diagramming` bundle. No auth required. |

## Skills

Skills are invoked automatically by the assistant based on relevance, or explicitly by name in chat (e.g. *"use the excalidraw-diagram skill on this repo"*).

### Jira

| Skill | Description |
|---|---|
| `jira-skill` | Drafts, validates, and posts structured Jira user stories from natural language requirements. Six-section template (title, short description, why, work to complete, additional information, acceptance criteria), self-validation, explicit user approval before posting. Uses **Atlassian MCP**. |

### Diagramming

| Skill | Description |
|---|---|
| `excalidraw-diagram` | Analyses a software or infrastructure codebase and produces a cited, accurate Excalidraw diagram (architecture overview, auth flow, security model, data flow, deployment topology, sequence flow, module dependency). Every shape and arrow traces to a `file:line` in the repo before rendering. Uses **Excalidraw MCP**. |

### Security

| Skill | Description |
|---|---|
| `security-review` | Branch-scoped security review. Acts as a senior security engineer, reviews only the diff against `origin/HEAD`, and surfaces high-confidence (>80%) exploitable vulnerabilities across **application code** (SQLi, command injection, authn/authz, crypto and secrets, unsafe deserialisation, XSS, data exposure) **and cloud / IaC code** (Azure, AWS, Kubernetes, Terraform / Bicep / CloudFormation, GitHub Actions). Emits a structured markdown report with file, line, severity, exploit scenario, and fix. No MCP required. |

### Builders

Meta-skills for authoring agent infrastructure. Both are vendored from [anthropics/skills](https://github.com/anthropics/skills) and retain their upstream Apache-2.0 license — see `NOTICE.md` and `LICENSE.txt` inside each skill directory.

| Skill | Description |
|---|---|
| `mcp-builder` | Guide for creating high-quality MCP (Model Context Protocol) servers. Covers FastMCP (Python) and the official Node/TypeScript SDK, tool design, evaluation harness, and connection patterns. Use when building an MCP server to integrate an external API or service. |
| `skill-creator` | Guide for creating, validating, packaging, and benchmarking new agent skills. Includes evaluation tooling (`run_eval.py`, `aggregate_benchmark.py`), a description-improvement loop, and a quick-validate script. Use when authoring a new skill or improving an existing one. |

### Coding

| Skill | Description |
|---|---|
| `coding-guidelines` | Behavioural guidelines that combine **KISS** and **DRY (with restraint)** with concrete rules for reducing common LLM coding mistakes — overcomplication, premature abstraction, ungrounded assumptions, scope creep, and silent edits to unrelated code. Five principles: KISS, DRY-with-restraint, Surface-don't-assume, Surgical Changes, Goal-Driven Execution. Use whenever the assistant is writing or modifying code. No MCP required. |

### Workflow

Development-workflow skills vendored from [obra/superpowers](https://github.com/obra/superpowers) under its MIT license — see `LICENSE.txt` and `NOTICE.md` inside each skill directory. They ship as plain skills **without the Superpowers plugin harness**: no `SessionStart` hook and no `using-superpowers` bootstrap forcing a skill check before every response, so each skill loads only when its own description matches the task. Upstream text still names siblings as `superpowers:<skill>`; here that is simply the skill `<skill>` from this bundle. No MCP required.

| Skill | Description |
|---|---|
| `brainstorming` | Turns an idea into an approved design before any code is written. Sizes how much process the request needs, pins down intent one focused question at a time, proposes 2–3 approaches with a recommendation, and writes the agreed spec to `docs/superpowers/specs/`. Optional local browser "visual companion" for mockups. |

## Getting Started

### Option A — APM (recommended)

Install all bundles at once or pick individual ones using [APM (Agent Package Manager)](https://github.com/microsoft/apm).

**Install APM:**
```bash
brew install microsoft/apm/apm        # macOS (Homebrew)
curl -sSL https://aka.ms/apm-unix | sh  # macOS / Linux
irm https://aka.ms/apm-windows | iex    # Windows
```

**Install bundles:**
```bash
# Everything (all bundles + all MCP servers)
apm install okaneconnor/agent-skills

# Or pick a single bundle
apm install okaneconnor/agent-skills/packages/jira
apm install okaneconnor/agent-skills/packages/diagramming
apm install okaneconnor/agent-skills/packages/security
apm install okaneconnor/agent-skills/packages/builders
apm install okaneconnor/agent-skills/packages/coding
apm install okaneconnor/agent-skills/packages/workflow
```

| Bundle | What's included |
|---|---|
| `packages/jira` | `jira-skill` + Atlassian MCP — draft, validate, and post Jira user stories from natural language. |
| `packages/diagramming` | `excalidraw-diagram` skill + Excalidraw MCP — analyse a codebase and produce a cited architecture / auth / security / data-flow diagram. |
| `packages/security` | `security-review` skill — branch-scoped security review covering app code and cloud / IaC (Azure, AWS, K8s, Terraform, GitHub Actions). No MCP required. |
| `packages/builders` | `mcp-builder` + `skill-creator` skills — vendored from anthropics/skills. Build new MCP servers and author/benchmark new skills. No MCP required. Apache-2.0. |
| `packages/coding` | `coding-guidelines` skill — KISS / DRY-with-restraint / surgical changes / goal-driven execution. Loads when the assistant is writing or modifying code. No MCP required. |
| `packages/workflow` | Development-workflow skills from the **Workflow** table above — vendored from obra/superpowers, without the plugin harness. No MCP required. MIT. |

APM installs skills to the directory your assistant expects (`.claude/skills/`, `.cursor/skills/`, `.github/skills/`, `.agents/skills/`) and writes the required MCP servers into the matching MCP config file automatically.

> Pin a specific version with `#vX.Y.Z` (e.g. `apm install okaneconnor/agent-skills#v2.0.0`) to prevent drift. Run `apm install --update` to refresh the lockfile.

---

### Option B — Clone directly

1. Clone or fork this repository.
2. Open the folder in your assistant of choice.
3. The skills under `.github/skills/` are loaded automatically by Claude Code / Copilot / Cursor.
4. Ensure the relevant MCP server is running if needed (`.vscode/mcp.json` is pre-wired for Atlassian and Excalidraw; the `security-review` skill needs no MCP server).
5. Invoke a skill explicitly by name — e.g. *"use the excalidraw-diagram skill on `~/repos/foo` and draw the auth flow"*, or *"use the security-review skill on this branch"*.

## Adding a new skill

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full author guide and the rules CI enforces. Quick summary:

1. Create `.github/skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`).
2. Lead the body with `## When to Use`, keep it under 500 lines / ~5 000 tokens, and split detail into `references/` if needed.
3. Add the skill to the relevant bundle's `dependencies.apm` list in `packages/<bundle>/apm.yml` (or create a new bundle).
4. If the skill needs an MCP server, add it under `dependencies.mcp` in the same bundle's `apm.yml` and mirror the entry in `.vscode/mcp.json` so local development works.
5. Update this README's skill table.
6. Run the validator locally (`python3 .github/scripts/validate_skills.py`) — the same check runs in CI on every PR.

> Tip: the vendored `skill-creator` skill in `packages/builders` walks through this end-to-end and includes an evaluation harness — invoke it with *"use the skill-creator skill to draft a new skill for X"*.

## CI checks on every PR

Two workflows gate changes under `.github/skills/**` and `packages/**`:

| Workflow | What it does |
| --- | --- |
| `validate-skills.yml` | Structural validation — frontmatter, naming, size, bundle wiring (`validate_skills.py`). |
| `scan-skills.yml` | Security scan with [NVIDIA SkillSpector](https://github.com/NVIDIA/SkillSpector). Scans the skill directories changed in the PR — **one `--format json` scan per skill** (SkillSpector's documented CI contract: exit code gates, JSON is the detail). **Fails the job if any skill scores risk > 50 (DO_NOT_INSTALL)**, renders a markdown report to the run summary **and as a sticky PR comment**, and uploads the JSON as a downloadable artifact. Static-only by default; runs LLM analysis when `OPENAI_API_KEY` is set. Accepted findings can be suppressed per skill via `.github/skillspector-baselines/<skill>.json`. |

The scan runs static-only (`--no-llm`) by default — deterministic, no secrets. To additionally enable LLM semantic analysis, set the repo secret `OPENAI_API_KEY` (optionally the variable `SKILLSPECTOR_MODEL`, defaulting to `gpt-4.1-mini`); the workflow falls back to static-only when the key is absent. If the key is set but the LLM provider fails (rate limit, exhausted quota, outage), that skill is re-scanned static-only instead of failing the PR; the row is flagged *static-only (LLM failed)*, and the failed LLM report is kept in the artifact.

## Refreshing vendored skills

`mcp-builder` and `skill-creator` are vendored verbatim from [anthropics/skills](https://github.com/anthropics/skills). To pull updates:

```bash
git clone --depth=1 https://github.com/anthropics/skills.git /tmp/anthropics-skills
cp -R /tmp/anthropics-skills/skills/mcp-builder/.   .github/skills/mcp-builder/
cp -R /tmp/anthropics-skills/skills/skill-creator/. .github/skills/skill-creator/
# Then bump the commit SHA in NOTICE.md inside each skill directory.
```

The Workflow skills are vendored from [obra/superpowers](https://github.com/obra/superpowers). Every one carries a `NOTICE.md` naming that upstream, so refresh them together:

```bash
git clone --depth=1 https://github.com/obra/superpowers.git /tmp/superpowers
for notice in $(grep -l "obra/superpowers" .github/skills/*/NOTICE.md); do
  skill=$(basename "$(dirname "$notice")")
  cp -R "/tmp/superpowers/skills/$skill/." ".github/skills/$skill/"
done
# Then bump the commit SHA in each NOTICE.md and re-apply anything it lists
# under "Local modifications".
```

The upstream license (Apache-2.0 or MIT) travels with each vendored skill folder. Do not modify upstream content — local additions belong in a sibling skill directory.

## Learn More

- [APM Documentation](https://microsoft.github.io/apm/)
- [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server)
- [Excalidraw](https://excalidraw.com)
- [Agent Skills Specification](https://agentskills.io/specification)
- [Anthropic Skills (upstream for `mcp-builder`, `skill-creator`)](https://github.com/anthropics/skills)
- [Superpowers (upstream for the Workflow skills)](https://github.com/obra/superpowers)
