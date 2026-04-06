# Codebase Analysis Workflow

A repeatable, citation-first process for extracting an architecture model from a codebase. This is the Step 2 + Step 3 expansion of the main SKILL.md workflow.

The single rule: **every claim you make about the architecture must end in a `file:line` citation.** If you cannot cite it, you do not know it.

## Phase 1 — Orient (every diagram type)

Before you decide what to look at, build a baseline picture of the repo. Spend ~5–10 tool calls here, no more.

1. **Read the surface**
   - `README.md`
   - `ARCHITECTURE.md`, `docs/architecture/`, `docs/adr/`, `docs/design/`
   - `CONTRIBUTING.md` (often has the dev loop, which leaks topology)
   - Top-level `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `*.csproj`, `pom.xml`, `build.gradle` — each names the language, framework, and direct dependencies
2. **Map the directory tree** to one level deep, two for `src/` and `infra/`. You are looking for the seams: `api/`, `web/`, `worker/`, `infra/`, `terraform/`, `k8s/`, `helm/`, `charts/`, `docker/`, `migrations/`.
3. **Identify the stack** — language, web framework, ORM, queue, cache, IaC tool, container runtime, CI tool. Write these down. They drive every later decision.
4. **Find entry points**
   - Web: `main.*`, `app.*`, `server.*`, `index.*`, `cmd/*/main.go`, `Program.cs`, `wsgi.py`, `asgi.py`
   - Workers: anything that calls `consume`, `subscribe`, `poll`, `Worker`, `Job`, `cron`
   - CLIs: `bin/`, `scripts/`, files with a `__main__` block
5. **Find infrastructure manifests**
   - Terraform: `*.tf`, especially `main.tf`, `providers.tf`, `variables.tf`
   - Bicep / ARM: `*.bicep`, `azuredeploy.json`
   - Kubernetes: anything under `k8s/`, `manifests/`, `deploy/`, `helm/`, `charts/`, plus loose `*.yaml` with `kind:`
   - Containers: `Dockerfile`, `docker-compose.yml`, `Containerfile`
   - Serverless: `serverless.yml`, `template.yaml`, `host.json`, `function.json`
   - CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `azure-pipelines.yml`, `Jenkinsfile`

If the user pointed at a monorepo, do this once per package boundary, not once for the whole thing.

## Phase 2 — Discover (per diagram type)

Each diagram type has its own evidence checklist. Use the matching section.

### Architecture overview

You are looking for **services, data stores, queues, and external dependencies**, plus the edges between them.

- **Services** — every entry point you found in Phase 1 is a candidate service node. Confirm by looking at how it is built/deployed (its `Dockerfile`, its k8s `Deployment`, its `terraform` `azurerm_*_app` block).
- **Data stores** — grep for connection-string env var names: `DATABASE_URL`, `DB_HOST`, `MONGO_URI`, `REDIS_URL`, `POSTGRES_*`, `MYSQL_*`, `STORAGE_ACCOUNT`, `S3_BUCKET`. Then trace where those env vars come from in IaC.
- **Queues / topics / event buses** — grep for `kafka`, `rabbitmq`, `sqs`, `sns`, `service.?bus`, `event.?hub`, `pubsub`, `nats`, `bullmq`, `celery`, `sidekiq`. Each producer and consumer becomes an edge.
- **External dependencies** — grep imports/requires for HTTP clients (`axios`, `httpx`, `requests`, `fetch`, `HttpClient`) and look at the URLs / config keys they read.
- **Caches** — `redis`, `memcached`, `cdn`, `cloudfront`, `front.?door`.

For each finding, record `name — purpose — file:line`.

### Auth flow

You are reconstructing the **token lifecycle**: who issues it, who holds it, who validates it.

- **Identity provider** — grep `oauth`, `oidc`, `openid`, `saml`, `cognito`, `auth0`, `okta`, `entra`, `azuread`, `keycloak`, `firebase.?auth`. Find the issuer URL in config.
- **Client registrations** — `client_id`, `client_secret`, `redirect_uri`, `callback_url`, `audience`, `scope`. Often in env files or IaC.
- **Token type** — JWT (`jsonwebtoken`, `pyjwt`, `System.IdentityModel.Tokens.Jwt`), opaque sessions (`express-session`, `flask-session`, `iron-session`), API keys (`X-Api-Key`, `Authorization: Bearer`).
- **Validation point** — where is the token checked? Look for middleware: `authMiddleware`, `requireAuth`, `[Authorize]`, `@login_required`, `passport.authenticate`, `verifyJwt`.
- **Session storage** — cookies (find the `Set-Cookie` headers / cookie config), Redis, JWT-in-localStorage, signed sessions.
- **Logout / token refresh** — find the refresh endpoint and the revocation path.

Lay these out as actors (User, Browser, App, IdP, Resource API) and number the messages between them. The auth flow diagram is a sequence diagram.

### Security model

You are mapping **trust boundaries, secrets, and access control**.

- **Network boundaries**
  - Terraform: `azurerm_virtual_network`, `azurerm_subnet`, `aws_vpc`, `aws_subnet`, `aws_security_group`, `network_security_group`, `nat_gateway`, `private_endpoint`
  - Kubernetes: `NetworkPolicy`, `Ingress`, `Service` types (`ClusterIP` vs `LoadBalancer`)
- **Ingress points** — load balancers, API gateways, application gateways, Cloudflare/Front Door, ingress controllers. Each is a public-facing edge.
- **Secrets storage** — `key_vault`, `secrets.?manager`, `parameter.?store`, `sealed.?secret`, `external.?secret`, `sops`, `.env` (and how the .env is fed in)
- **IAM / RBAC**
  - Cloud: `azurerm_role_assignment`, `aws_iam_role`, `aws_iam_policy`, `google_project_iam_member`
  - Kubernetes: `Role`, `ClusterRole`, `RoleBinding`, `ServiceAccount`
  - App: `@authorize`, `requires_role`, `casbin`, `oso`
- **Encryption** — TLS termination point, encryption at rest config, KMS / customer-managed key references
- **Workload identity** — managed identities, IRSA, Workload Identity Federation, service account tokens

Group findings into trust zones: `public internet`, `dmz`, `app subnet`, `data subnet`, `management plane`. Every arrow that crosses a zone boundary deserves a label.

### Data flow

You are tracing **a record from producer to final resting place**.

- **Sources** — HTTP handlers that accept writes, file uploads, webhook receivers, scheduled jobs that pull data
- **Validation / transform layers** — DTOs, schemas, parsers, mappers
- **Hops** — every persistence call (`INSERT`, `repo.save`, `db.write`, queue `publish`, `producer.send`)
- **Sinks** — the database tables, blob containers, event archives, search indices, downstream APIs
- **Schemas** — find the migration files, the protobuf / avro / openapi schemas, the DDL

Pick **one record type** (e.g. "an order", "a user signup", "an audit event") and follow it end to end. A data flow diagram that tries to show every record type is unreadable.

### Deployment topology

You are mapping **where the code runs**.

- **Environments** — `terraform/environments/`, `helm/values-*.yaml`, `*.tfvars`, env var presets in CI
- **Regions / availability zones** — provider region settings, replication config
- **Compute hosts** — VMs, containers (ECS / ACA / GKE / AKS / EKS), serverless (Lambda / Functions / Cloud Run)
- **Scaling units** — replica counts, HPA, VMSS, autoscale rules
- **Networking** — VNets / VPCs, subnets, peering, NAT, load balancers
- **Pipelines** — what builds it, what deploys it, what gates it (env approvals, manual approvals)

A deployment topology diagram is **layered**: cloud → region → network → host → container.

### Sequence flow

A sequence flow is the right diagram type when the user asks "walk me through what happens when X". Reuse the auth flow technique:

1. Identify the actors (left to right is fine, but pick a stable order)
2. For each actor, find the entry point that participates in this flow
3. Number the messages in time order
4. For each message, cite the file:line that sends or handles it

Sequence flows are particularly good for: webhook handling, background job lifecycles, deploy pipelines, login flows, payment captures.

### Module dependency

For library or monorepo authors. Every package gets a node; every `import`/`require` from one package to another gets an edge.

- Use the package manager as the source of truth: `package.json` `dependencies`, `go.mod` `require`, `pyproject.toml` `dependencies`, `*.csproj` `<ProjectReference>`
- Do **not** infer module dependencies from a directory tree alone; that lies about indirect imports

## Phase 3 — Build the cited model

Once Phase 2 is done, write the model as plain markdown directly in the conversation. The structure is fixed:

```
## Components
- <name> — <one-line purpose> — <file:line>

## Edges
- <from> -> <to> : <label> — <file:line>

## Trust boundaries / zones (security & topology diagrams only)
- <name> — what is inside it — <file:line>

## Open questions
- <thing you could not verify and want the user to confirm>
```

If a fact came from documentation rather than code, mark it `(docs)` and treat it as lower confidence — docs drift, code does not. Where a doc and the code disagree, the code wins, full stop.

## Tactical tips

- **Use the Explore subagent** for any repo where you cannot enumerate the relevant files in 5–10 Glob/Grep calls. It saves your context for the diagram itself.
- **Prefer Grep with file globs** over reading whole directories. `*.tf`, `**/Dockerfile`, `**/*.yaml` are your friends.
- **Read the IaC before the application code** — infrastructure manifests are the most accurate map of the architecture. They are the source of truth for what runs and how it connects.
- **When the architecture is ambiguous, read the tests.** Integration tests reveal what talks to what.
- **Stop discovering when the model stops growing.** Two consecutive Grep calls that add nothing new = you have enough.
