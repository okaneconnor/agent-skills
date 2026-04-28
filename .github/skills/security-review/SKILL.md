---
name: security-review
description: Conduct a focused, low-noise security review of the pending changes on the current git branch. Use when the user asks to "do a security review", "security review this branch", "review this PR for vulnerabilities", "scan this diff for security issues", or asks for a pre-merge security check. Acts as a senior security engineer, examines only the diff against `origin/HEAD`, and surfaces only high-confidence (>80%) exploitable vulnerabilities across application code (input validation, authn/authz, crypto and secrets, injection and code execution, data exposure) **and** cloud / infrastructure code (Azure, AWS, Kubernetes, Terraform / Bicep / CloudFormation, GitHub Actions and CI/CD pipelines). Produces a structured markdown report with file, line, severity, exploit scenario, and fix. Do NOT use for general code review, style review, dependency audits, DoS or rate-limiting concerns, or for reviewing code outside the current branch's diff.
---

# Branch Security Reviewer

Conduct a focused security review of the changes on the current git branch. Behave as a senior security engineer doing a pre-merge review: surface only **high-confidence, exploitable** vulnerabilities introduced by the diff, with a clear attack path and fix recommendation.

This skill is **diff-scoped**. It reviews what changed on this branch versus `origin/HEAD`, never the whole repo, and never pre-existing issues.

## When to Use

Use this skill when:

- The user asks to security-review the current branch / PR / diff
- The user wants a pre-merge security check before opening or merging a PR
- The user says "scan for vulns", "look for security issues in this change", or similar
- A reviewer wants a second pass on a branch they've already authored

Do **not** use this skill when:

- The user wants a general code review (correctness, style, design) — this skill ignores those
- The user wants a full-repo security audit — scope is limited to the branch diff
- The user wants a dependency / SBOM / outdated-library audit — those are handled separately
- The user wants DoS, rate-limiting, or resource-exhaustion findings — explicitly excluded
- There is no git repository, or the branch has no diff against `origin/HEAD`

## Configuration

- **Scope:** The diff between the current branch and `origin/HEAD` only. Never review files unchanged by this branch.
- **Confidence bar:** Only report findings where you're >80% confident of real exploitability. Better to miss a theoretical issue than emit false positives.
- **Severity floor:** Report HIGH and MEDIUM findings only. LOW / defence-in-depth / hardening suggestions are out of scope.
- **Output:** A markdown report. Each finding: file, line, severity, category, description, exploit scenario, fix recommendation.
- **Tools:** Read-only. Use `Read`, `Glob`, `Grep`, `Bash` for git inspection only, and sub-agents (`Task`) for parallel false-positive filtering. Do **not** modify files or run code.

## Workflow

```
Review Progress:
- [ ] Step 1: Gather diff context
- [ ] Step 2: Phase 1 — repository context research
- [ ] Step 3: Phase 2 — comparative analysis vs existing patterns
- [ ] Step 4: Phase 3 — vulnerability assessment (sub-task)
- [ ] Step 5: Parallel false-positive filtering (sub-tasks)
- [ ] Step 6: Drop findings with confidence < 8
- [ ] Step 7: Emit final markdown report
```

### Step 1: Gather diff context

Run these git commands and capture the output:

```bash
git status
git diff --name-only origin/HEAD...
git log --no-decorate origin/HEAD...
git diff --merge-base origin/HEAD
```

If the branch has no diff against `origin/HEAD`, stop and tell the user there's nothing to review.

### Step 2: Phase 1 — Repository context research

Before analysing the diff, understand the project's existing security posture so you can spot deviations rather than re-flagging conventions:

- Identify security frameworks and libraries already in use
- Note established sanitisation, validation, and authn/authz patterns
- Skim the project's threat model if one exists (look for `SECURITY.md`, `THREAT_MODEL.md`, ADRs)

Use `Glob` and `Grep` for this — never review files outside the diff for findings, only for context.

### Step 3: Phase 2 — Comparative analysis

For each modified file, compare new code against the existing patterns identified in Phase 1:

- Does this change deviate from the project's established secure pattern?
- Does it introduce a new attack surface (new endpoint, new deserialisation site, new shell-out, new SQL builder)?
- Does it cross a privilege boundary unsafely?

### Step 4: Phase 3 — Vulnerability assessment (sub-task)

Spawn a sub-task (`Task` tool) to identify candidate vulnerabilities. Pass the sub-task **everything** in this skill — the categories, the methodology, the false-positive rules, and the diff context. The sub-task's job is to enumerate candidates with confidence scores. See [security-categories.md](references/security-categories.md) for the full taxonomy of what to look for.

### Step 5: Parallel false-positive filtering

For **each** candidate from Step 4, spawn a separate sub-task **in parallel** to validate it against the false-positive rules. Each sub-task must:

- Read the actual code at the cited line
- Apply the hard exclusions list
- Apply the precedents list
- Re-score confidence on a 1–10 scale

See [false-positive-filtering.md](references/false-positive-filtering.md) for the full rules. The filtering pass is non-negotiable — the original prompt explicitly designs around false-positive minimisation.

### Step 6: Drop findings below the confidence floor

Discard any finding with a final confidence < 8. Better to ship a short, high-signal report than a long noisy one.

### Step 7: Emit final markdown report

The final reply must contain **only** the markdown report — no preamble, no summary of process. See [output-format.md](references/output-format.md) for the exact format and a worked example.

## What to Examine

See [security-categories.md](references/security-categories.md) for the full list. The headline categories split across application and infrastructure code:

**Application-level**

- **Input validation** — SQL/command/XXE/template/NoSQL injection, path traversal
- **Authentication & authorisation** — bypass logic, privilege escalation, session and JWT flaws
- **Crypto & secrets** — hardcoded credentials, weak algorithms, bad key handling, RNG misuse, cert validation bypass
- **Injection & code execution** — unsafe deserialisation (pickle, YAML), `eval`, RCE sinks, XSS
- **Data exposure** — sensitive data in logs, PII handling, endpoint leakage, debug info

**Cloud & infrastructure**

- **Azure** — over-privileged service principals / managed identities, federated credentials with wildcard subjects, public network access on Key Vault / Storage / SQL / Cosmos / AKS API, NSG `0.0.0.0/0` on management ports, blob containers with public access, missing private endpoints where the project standard
- **AWS** — IAM policies with `Action: *` / `Resource: *`, OIDC trust with wildcard `sub`, S3 buckets with public access or weak policies, security groups exposing 22/3389/DB ports to the internet, KMS key policies allowing `kms:*` to `Principal: *`, RDS / EKS publicly accessible
- **Kubernetes** — privileged / hostNetwork / hostPID pods, root containers, `cluster-admin` to namespaced workloads, NetworkPolicies removed, secrets baked into ConfigMaps
- **Terraform / IaC** — secrets in variable defaults or outputs, `sensitive = false` on secret outputs, unencrypted/unlocked remote state, unpinned providers and modules, `local-exec` with attacker-influenced input
- **CI/CD** — `pull_request_target` + checkout of PR head, untrusted PR input in `run:` blocks, third-party actions pinned by tag instead of SHA when secrets are in scope, `permissions: write-all`

Local-network-only exploitability does not downgrade severity. A vuln reachable only inside a VPC / VNet can still be HIGH.

## What NOT to Report

Hard exclusions (full list in [false-positive-filtering.md](references/false-positive-filtering.md)):

- DoS, rate limiting, resource exhaustion
- Secrets at rest (handled by other processes)
- Outdated dependencies (handled separately)
- Memory safety in memory-safe languages (Rust, Go, etc.)
- Findings in unit-test files, documentation, or markdown
- Log spoofing, regex injection, regex DoS
- SSRF that only controls the path
- User-controlled content in AI system prompts
- Theoretical race conditions or timing attacks
- Lack of audit logs / hardening / defence-in-depth

## Output

The final reply is **only** the markdown report. No commentary, no methodology recap, no "I reviewed N files" preamble. See [output-format.md](references/output-format.md) for the format.

If there are zero findings after filtering, say so explicitly and stop.
