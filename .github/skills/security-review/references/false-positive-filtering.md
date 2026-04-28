# False-Positive Filtering

The signal-quality bar for this skill is deliberately strict. Better to ship a short, high-confidence report than a long, noisy one. Every candidate finding from Phase 3 must pass through this filter via a parallel sub-task before it lands in the final report.

You do **not** need to run code to reproduce a vulnerability. Read the cited code, apply the rules below, and re-score confidence on a 1–10 scale.

---

## Hard Exclusions

Automatically drop any finding that matches one of these:

1. Denial of Service (DoS) or resource exhaustion attacks
2. Secrets or credentials stored on disk if otherwise secured (handled by other processes)
3. Rate limiting concerns or service overload scenarios
4. Memory consumption or CPU exhaustion issues
5. Lack of input validation on non-security-critical fields with no proven security impact
6. Input sanitisation concerns in GitHub Actions workflows unless clearly triggerable via untrusted input
7. A lack of hardening measures — code is not expected to implement every best practice; only flag concrete vulnerabilities
8. Race conditions or timing attacks that are theoretical rather than concretely problematic
9. Outdated third-party libraries (managed separately)
10. Memory safety issues in memory-safe languages (Rust, Go, managed .NET, JVM, etc.) — buffer overflows and use-after-free do not apply
11. Findings in unit-test files or files only used by tests
12. Log spoofing — outputting un-sanitised user input to logs is not a vulnerability
13. SSRF vulnerabilities that only control the path (SSRF requires control of host or protocol)
14. Including user-controlled content in AI system prompts
15. Regex injection — injecting untrusted content into a regex is not a vulnerability
16. Regex DoS (ReDoS) concerns
17. Findings in documentation or markdown files
18. A lack of audit logs

---

## Precedents

These have been adjudicated previously — apply them without re-litigating:

1. Logging high-value secrets in plaintext is a vulnerability. Logging URLs is assumed safe.
2. UUIDs can be assumed unguessable and do not need to be validated.
3. Environment variables and CLI flags are trusted in a secure environment. Attacks that rely on controlling them are invalid. **Exception:** secrets committed as IaC defaults or pipeline `env:` literals — those are sourced from the repo and are valid findings.
4. Resource management issues (memory leaks, FD leaks) are not valid.
5. Subtle / low-impact web vulnerabilities — tabnabbing, XS-Leaks, prototype pollution, open redirects — only report if extremely high confidence with a concrete attack path.
6. React and Angular are generally XSS-safe. Do not report XSS in `.tsx` / Angular components unless `dangerouslySetInnerHTML`, `bypassSecurityTrustHtml`, `v-html`, `innerHTML`, or equivalent unsafe API is in use.
7. Most GitHub Actions workflow vulnerabilities are not exploitable in practice. Validate a concrete, specific attack path before reporting one. (`pull_request_target` + checkout of PR head **is** a concrete attack path — see `security-categories.md`.)
8. A lack of permission checking or auth in client-side JS/TS is not a vulnerability — client code is untrusted; the server is responsible for those checks. Same applies to anything sending data to a backend.
9. Only include MEDIUM findings if they are obvious and concrete.
10. Vulnerabilities in IPython notebooks (`*.ipynb`) are usually not exploitable in practice. Require a concrete attack path with untrusted input.
11. Logging non-PII data is not a vulnerability even if the data feels sensitive. Only report log-exposure findings for secrets, passwords, or PII.
12. Command injection in shell scripts is generally not exploitable — shell scripts rarely run with untrusted user input. Require a concrete attack path before reporting.
13. **Cloud / IaC specific:** wildcard scopes, public network exposure, and disabled-encryption findings should only be reported when the project's baseline pattern is the secure variant and the diff regresses it. If the repo never used private endpoints / CMK / least-privilege roles to begin with, that's a hardening gap, not a vulnerability introduced by this branch.
14. **Cloud / IaC specific:** federated credentials, OIDC trust policies, and managed-identity role assignments must be validated against the actual `sub` claim or scope — wildcard subjects (`repo:org/*:*`) are valid HIGH findings; pinned subjects are not.

---

## Signal Quality Criteria

For each remaining finding, ask:

1. Is there a concrete, exploitable vulnerability with a clear attack path?
2. Does this represent a real security risk vs a theoretical best practice?
3. Are there specific code locations and reproduction steps?
4. Would this finding be actionable for a security team?

If any answer is "no" or "kind of", drop the finding.

---

## Confidence Scoring

After applying exclusions and precedents, re-score on a 1–10 scale:

- **1–3** Low confidence, likely false positive or noise → drop
- **4–6** Medium confidence, needs investigation → drop (this skill only emits high-confidence)
- **7–10** High confidence, likely true vulnerability → keep

The skill emits **only findings with final confidence ≥ 8.** Anything below that is filtered out.
