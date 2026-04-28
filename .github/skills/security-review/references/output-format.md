# Output Format

The final reply must contain the markdown report and **nothing else** — no preamble, no methodology recap, no "I reviewed N files" header, no closing summary. The report itself stands alone.

If there are zero findings after filtering, the entire reply is:

```
No high-confidence security findings on this branch.
```

Stop there. Do not pad with reassurance, methodology, or "things to consider".

---

## Report Structure

One `# Vuln <N>:` heading per finding, in order of severity (HIGH first, then MEDIUM). Each finding has the same six fields, in the same order.

```
# Vuln 1: <Category>: `<file>:<line>`

* Severity: <High | Medium>
* Category: <snake_case_category>
* Description: <one paragraph — what the vulnerability is>
* Exploit Scenario: <one paragraph — how an attacker exploits it, end-to-end>
* Recommendation: <one paragraph — the concrete fix, citing the right API or pattern>
* Confidence: <8–10>/10
```

---

## Worked Examples

### App-level finding

```
# Vuln 1: SQL Injection: `api/users.py:42`

* Severity: High
* Category: sql_injection
* Description: The `username` query parameter is concatenated directly into a raw SQL string passed to `cursor.execute()`, bypassing the parameterised-query API used elsewhere in this module.
* Exploit Scenario: An unauthenticated attacker sends `GET /users?username=admin'--` and receives the admin row, or `GET /users?username='; DROP TABLE users;--` to destroy data. The endpoint is exposed on the public ingress (see `routes.py:118`), so this is reachable from the internet.
* Recommendation: Replace the f-string interpolation on line 42 with a parameterised query: `cursor.execute("SELECT * FROM users WHERE username = %s", (username,))`. The same pattern is already used at `api/orders.py:88`.
* Confidence: 10/10
```

### Cloud / IaC finding

```
# Vuln 2: Over-Privileged Federated Credential: `infra/identity.tf:67`

* Severity: High
* Category: azure_federated_credential
* Description: The federated credential added for the `deploy` workflow uses subject `repo:okaneconnor/foo:ref:refs/heads/*`, allowing any branch in the repo to assume the identity. The identity has Contributor at subscription scope (`infra/role-assignments.tf:14`).
* Exploit Scenario: A contributor opens a branch named anything (e.g. `feature/x`) and pushes a workflow that calls `az` against the subscription, obtaining Contributor across every resource group. Existing CODEOWNERS does not gate workflow files in this repo.
* Recommendation: Pin the federated subject to the exact branch the deploy workflow runs on, e.g. `repo:okaneconnor/foo:ref:refs/heads/main`, or scope to a deployment environment (`repo:okaneconnor/foo:environment:prod`). Mirrors the pattern in `infra/identity.tf:34` for the `plan` credential.
* Confidence: 9/10
```

### Public storage finding

```
# Vuln 3: Public Blob Container: `infra/storage.bicep:88`

* Severity: High
* Category: azure_storage_public_access
* Description: The new `audit-logs` blob container is created with `publicAccess: 'Container'`, making every blob world-readable over the public storage endpoint. Audit logs include user emails and source IPs (verified at `app/audit.go:24`).
* Exploit Scenario: Any unauthenticated client requests `https://<account>.blob.core.windows.net/audit-logs/?comp=list` and enumerates the audit log, leaking PII and operational metadata. Storage account is on the public endpoint (no `publicNetworkAccess: Disabled` on line 41).
* Recommendation: Set `publicAccess: 'None'` on the container and access via SAS or AAD with RBAC. The other containers in this file already use `'None'` — this looks like a copy-paste error.
* Confidence: 10/10
```

---

## What NOT to Do

- Do not include a "Files Reviewed" or "Methodology" section.
- Do not summarise findings at the end.
- Do not include LOW-severity findings, hardening tips, or "things to consider".
- Do not output the report inside a code fence — it's the body of the message.
- Do not include findings with confidence < 8.
- Do not invent line numbers — every finding must cite a real `file:line` from the diff.
