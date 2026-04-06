# Good User Story Examples

Reference examples showing what well-written Jira stories look like. Each example demonstrates clear structure, actionable work items, and testable acceptance criteria.

---

## Example 1: Infrastructure / Terraform

```markdown
# Jira Story Draft - AKS Network Policy

## Title
Enable Calico network policies on AKS staging cluster

Deploy and configure Calico network policies on the staging AKS cluster to restrict pod-to-pod communication. Only explicitly allowed traffic should be permitted between namespaces.

## Why are we carrying this out?

A recent security review identified that all pods in the staging cluster can communicate freely across namespaces. This means a compromised workload in one namespace could reach databases and internal services in another. Enabling network policies is a prerequisite for achieving namespace-level isolation before we promote this pattern to production.

This work is part of the epic: Kubernetes Security Hardening.

## Work to complete

* Enable the Calico network policy provider on the staging AKS cluster via Terraform
* Create a default-deny ingress policy for all non-system namespaces
* Define allow policies for known service-to-service communication paths (API to database, frontend to API)
* Test that cross-namespace traffic is blocked unless explicitly allowed
* Document the network policy patterns in the infrastructure runbook

## Additional Information

**Links:**
* [AKS Terraform module](https://github.com/example/aks-terraform)
* [Calico network policy documentation](https://docs.tigera.io/calico/latest/network-policy)

**Points of Contact:**
* Platform Team - for AKS cluster configuration
* Security Team - for reviewing the network policy rules

**Related Work:**
* Follow-on story: Enable network policies on production AKS cluster
* Follow-on story: Add network policy monitoring and alerting

## Acceptance Criteria

* Calico is enabled on the staging AKS cluster and pods can resolve the network policy controller
* A default-deny ingress policy exists for all application namespaces
* The API namespace can reach the database namespace on port 5432 only
* Cross-namespace traffic not covered by an allow policy is dropped
```

---

## Example 2: CI/CD Pipeline

```markdown
# Jira Story Draft - Pipeline Caching

## Title
Add dependency caching to CI pipeline to reduce build times

Introduce dependency caching for npm and Docker layers in the CI pipeline. Current builds download all dependencies from scratch on every run, adding 4-6 minutes to each build.

## Why are we carrying this out?

Average CI build time has increased to 12 minutes, with dependency installation accounting for roughly 40% of that. This slows down developer feedback loops and increases our hosted runner costs. Caching dependencies between runs will reduce build times and runner usage significantly.

This work is part of the epic: Developer Experience Improvements.

## Work to complete

* Add npm cache configuration to the CI workflow using the runner's cache directory
* Configure Docker layer caching for the application image build step
* Ensure cache keys include the lock file hash so caches invalidate when dependencies change
* Add cache hit/miss metrics to the pipeline summary output
* Validate that a cache miss still produces a correct build (no stale dependency issues)

## Additional Information

**Links:**
* [CI pipeline repository](https://github.com/example/ci-pipelines)
* [GitHub Actions caching documentation](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)

**Points of Contact:**
* DevOps Team - for pipeline configuration and runner management

**Related Work:**
* Previous story: Migrate CI from Jenkins to GitHub Actions
* Follow-on story: Add build time tracking dashboard

## Acceptance Criteria

* npm dependencies are cached between pipeline runs using the package-lock.json hash as the cache key
* Docker image builds use layer caching and skip unchanged layers
* A clean build with no cache still completes successfully
* Average build time for cache-hit runs is under 6 minutes
```

---

## Example 3: Monitoring / Observability

```markdown
# Jira Story Draft - Database Alerting

## Title
Configure alerting for PostgreSQL connection pool exhaustion

Set up monitoring and alerting for the production PostgreSQL connection pool. The team should be notified before the pool reaches capacity so they can investigate before users are affected.

## Why are we carrying this out?

Last week the production database hit its connection pool limit of 100 connections, causing HTTP 500 errors for approximately 15 minutes until the team was alerted by a customer complaint. There was no proactive alerting in place. Adding connection pool monitoring and tiered alerts will allow the team to respond before users are impacted.

This work is part of the epic: Production Reliability Improvements.

## Work to complete

* Create a Grafana dashboard panel showing active versus available connections over time
* Configure a warning alert at 75% pool utilisation (75/100 connections)
* Configure a critical alert at 90% pool utilisation (90/100 connections)
* Route alerts to the on-call Slack channel and PagerDuty
* Add a runbook entry documenting how to investigate and resolve connection pool issues

## Additional Information

**Links:**
* [Grafana instance](https://monitoring.example.com)
* [PostgreSQL monitoring queries](https://wiki.example.com/pg-monitoring)

**Points of Contact:**
* SRE Team - for alert routing and PagerDuty configuration
* Backend Team - for connection pool tuning guidance

**Related Work:**
* Follow-on story: Investigate PgBouncer for connection pooling

## Acceptance Criteria

* A Grafana panel displays active and available PostgreSQL connections in real time
* A warning alert fires when connection usage exceeds 75% and routes to the on-call Slack channel
* A critical alert fires at 90% and pages the on-call engineer via PagerDuty
* A runbook entry exists with steps to diagnose and mitigate connection pool exhaustion
```

---

## Example 4: Security / Access Management

```markdown
# Jira Story Draft - Service Account Rotation

## Title
Implement automated rotation for CI/CD service account credentials

Set up automated credential rotation for the service accounts used by CI/CD pipelines. Credentials should rotate on a 90-day schedule without requiring manual intervention or causing pipeline downtime.

## Why are we carrying this out?

An internal audit found that CI/CD service account credentials have not been rotated in over 12 months. Long-lived static credentials increase the blast radius if they are leaked. Automating rotation reduces this risk and brings us in line with our security policy, which requires rotation every 90 days.

This work is part of the epic: Credential Management Overhaul.

## Work to complete

* Create a scheduled workflow that generates new service account credentials every 90 days
* Store rotated credentials in the secrets manager (Azure Key Vault / AWS Secrets Manager)
* Update CI/CD pipelines to pull credentials from the secrets manager at runtime rather than using static secrets
* Send a notification to the security channel when rotation completes successfully
* Add a failure alert if rotation does not complete within the expected window

## Additional Information

**Links:**
* [Secrets management policy](https://wiki.example.com/security/secrets-policy)
* [CI/CD pipeline repository](https://github.com/example/ci-pipelines)

**Points of Contact:**
* Security Team - for policy requirements and audit compliance
* DevOps Team - for pipeline and secrets manager configuration

**Related Work:**
* Follow-on story: Rotate database credentials on the same schedule
* Follow-on story: Remove all static secrets from CI/CD environment variables

## Acceptance Criteria

* Service account credentials are rotated automatically every 90 days
* Pipelines retrieve credentials from the secrets manager at runtime and do not use static environment secrets
* A Slack notification confirms successful rotation with the new expiry date
* Rotation failure triggers an alert to the security and DevOps channels within 1 hour
```

---

## What Makes These Stories Good

| Quality | How it is demonstrated |
|---------|----------------------|
| **Clear title** | Action verb + specific scope, under 80 characters |
| **Concise description** | 1-2 sentences explaining what and why |
| **Strong justification** | Links to a real problem, risk, or incident — not just "we should do this" |
| **Actionable work items** | Each bullet is a distinct task an engineer can pick up and complete |
| **Testable acceptance criteria** | Pass/fail outcomes, no vague language like "works correctly" |
| **Right size** | Each story is a meaningful unit of work, completable in a sprint |
| **Context provided** | Links, contacts, and related work help the assignee get started quickly |
