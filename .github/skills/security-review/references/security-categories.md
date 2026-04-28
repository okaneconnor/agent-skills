# Security Categories

The taxonomy of vulnerabilities to look for in the diff. These are the **only** categories in scope. Anything outside this list is either covered by a different process (deps, secrets-at-rest) or explicitly excluded (DoS, rate limiting, hardening).

The first half covers application-level patterns. The second half covers cloud, IaC, and platform patterns relevant to Azure, AWS, Kubernetes, and Terraform — which is where most real exploitable findings sit on infrastructure-heavy branches.

---

## Application-Level

### Input Validation

- **SQL injection** via unsanitised user input concatenated into queries or query builders
- **Command injection** in `subprocess`, `os.system`, `exec`, shell pipelines, or any `child_process` call
- **XXE injection** in XML parsers without external-entity disabled
- **Template injection** in Jinja2 / Handlebars / ERB / Go templates rendered with user input
- **NoSQL injection** in MongoDB / Elasticsearch / DynamoDB queries built from user input
- **Path traversal** in file reads/writes/serves that accept user-controlled paths

### Authentication & Authorisation

- Authentication bypass logic (e.g. comparing tokens with `==` against attacker-controlled values, missing `verify=true`)
- Privilege escalation paths — role checks that miss a code path, or rely on client-supplied claims
- Session management flaws — predictable session IDs, missing rotation on privilege change, fixation
- JWT vulnerabilities — `alg: none`, missing signature verification, weak HMAC keys, `kid` injection
- Authorisation bypasses — IDOR, forced browsing, missing tenancy / org checks

### Crypto & Secrets Management

- Hardcoded API keys, passwords, tokens, or certificates in source
- Weak algorithms — MD5/SHA1 for security-sensitive hashing, ECB mode, DES, RC4
- Improper key storage — keys in env vars logged, written to disk in plaintext, committed to source
- Cryptographic randomness — `Math.random()` / `rand()` for security tokens, predictable seeds
- Certificate validation bypasses — `verify=False`, `InsecureSkipVerify: true`, custom trust managers that accept everything

### Injection & Code Execution

- Unsafe deserialisation — `pickle.loads`, `yaml.load` without `SafeLoader`, Java `ObjectInputStream`, .NET `BinaryFormatter`
- `eval` / `exec` / `Function()` on user input
- Server-side template injection leading to RCE
- XSS — reflected, stored, or DOM-based — only when raw HTML rendering is involved (`dangerouslySetInnerHTML`, `bypassSecurityTrustHtml`, `v-html`, `innerHTML`)

### Data Exposure

- Logging secrets, tokens, passwords, PII in plaintext
- API endpoints returning more data than the caller is authorised for (over-fetching)
- Debug endpoints / verbose error messages that leak stack traces, file paths, internal hostnames
- PII handling that violates a stated policy (only flag if there's a concrete exposure path)

---

## Cloud & Infrastructure

Infrastructure findings often have a higher real-world blast radius than app findings — a public storage bucket or an over-permissive role can compromise an entire workload. The diff context (Bicep, Terraform, ARM, CloudFormation, K8s manifests, GitHub Actions, pipeline YAML) gets the same scrutiny as application code.

### Azure

**Identity & access**
- Service principals or managed identities with `Owner`, `Contributor`, or `User Access Administrator` at subscription/management-group scope when a narrower role would suffice
- Custom RBAC roles granting `*/write` or wildcard `Microsoft.Authorization/*`
- Storage / Key Vault / SQL access keys committed in code, pipelines, or `*.tfvars` instead of using Managed Identity + RBAC or Key Vault references
- Federated credentials with overly broad subject claims (e.g. `repo:org/*:ref:refs/heads/*`) — must pin branch/environment exactly
- App registrations with implicit-grant flow enabled, or client secrets where certificate auth is feasible
- Cross-tenant access without `allowedTenants` restriction

**Networking**
- NSGs, Azure Firewall rules, or App Service / Function `ipSecurityRestrictions` allowing `0.0.0.0/0` (or `Internet` service tag) on management ports (22, 3389, 5985/6, 1433, 5432, 6379, etc.)
- Public IP attached to resources that should be private (databases, AKS API server, internal load balancers)
- Storage accounts / Key Vaults / Cosmos / SQL with `publicNetworkAccess: Enabled` and no firewall, when private endpoints are the established pattern
- AKS clusters with public API server and no `authorizedIpRanges`
- Service endpoints used in place of private endpoints for sensitive data planes (acceptable but flag if the project standard is private endpoints)

**Storage & data**
- Blob containers with `publicAccess: Blob` or `Container`
- Storage accounts with `allowBlobPublicAccess: true` or `allowSharedKeyAccess: true` when MI/RBAC is the pattern
- Soft-delete or versioning disabled on storage holding security-critical data
- SAS tokens with long TTLs, broad permissions (`rwdl`), or no IP scoping in code that emits them to clients
- Cosmos DB / SQL with key-based auth where AAD auth is the project standard

**Key Vault & secrets**
- Key Vault with `publicNetworkAccess: Enabled` and no firewall when private endpoint is the standard
- Purge protection or soft-delete disabled
- Access policies (legacy) used in a project that has migrated to RBAC, granting broad permissions
- Secrets referenced via portal-paste literal value rather than `keyVaultReference` in App Service / Function / Container Apps

**Compute & containers**
- AKS without RBAC, with `--disable-rbac`, or running pods as root with `hostNetwork`/`hostPID`/privileged containers introduced by the diff
- Container Apps / App Service with `identity: SystemAssigned` granted `Contributor` at RG scope when scoped roles would do
- VMs with `disablePasswordAuthentication: false` plus weak password, or with managed disks unencrypted (no CMK where CMK is the pattern)

**Logging & policy**
- Diagnostic settings removed from a security-critical resource (Key Vault, Storage, NSG flow logs, Activity Log)
- Defender for Cloud plans disabled in the diff
- Azure Policy assignments removed or scoped down without justification

### AWS

**IAM**
- IAM policies with `"Action": "*"` and `"Resource": "*"`, or `iam:PassRole` with `"Resource": "*"`
- `AssumeRolePolicyDocument` trusting `"AWS": "*"` or trusting an account/role outside the org without external-id condition
- Long-lived access keys committed or generated in code where IAM Roles / IRSA / OIDC federation is feasible
- GitHub Actions OIDC trust with `token.actions.githubusercontent.com:sub` set to `repo:org/*:*` — must pin `ref:refs/heads/<branch>` or `environment:<env>`
- Inline policies attached at user level rather than role/group, or `AdministratorAccess` granted by default

**S3**
- `BlockPublicAcls`, `BlockPublicPolicy`, `IgnorePublicAcls`, `RestrictPublicBuckets` set to false
- Bucket policy with `"Principal": "*"` and no `aws:SourceVpc` / `aws:SourceArn` / `aws:PrincipalOrgID` condition
- Bucket ACLs (legacy) granting `AllUsers` or `AuthenticatedUsers`
- Server-side encryption disabled or set to AES256 where a project standard mandates KMS CMK
- Bucket versioning / object lock removed on data subject to retention requirements

**Networking & compute**
- Security groups with `0.0.0.0/0` ingress on 22 / 3389 / 1433 / 3306 / 5432 / 6379 / 9200 / 27017
- RDS / ElastiCache / OpenSearch with `PubliclyAccessible: true`
- EKS public API endpoint without `publicAccessCidrs`, or with both public and private endpoint enabled when private-only is the standard
- EC2 instance profiles with policies far broader than the workload requires
- Lambda function URLs with `AuthType: NONE` exposing sensitive operations

**KMS / Secrets Manager**
- KMS key policies allowing `kms:*` to `Principal: *` or to the entire account root without further conditions
- Customer-managed keys disabled where the project mandates them (RDS, S3, EBS, EFS)
- Secrets Manager / Parameter Store SecureString values written in plaintext via `default = "..."` in Terraform

**Logging & guardrails**
- CloudTrail / GuardDuty / Config disabled in the diff
- VPC flow logs removed from a sensitive subnet
- Service Control Policies relaxed without justification

### Kubernetes (any cloud)

- Pods with `privileged: true`, `hostNetwork: true`, `hostPID: true`, `hostIPC: true`, `allowPrivilegeEscalation: true`, or running as root (`runAsUser: 0`)
- ServiceAccount with `automountServiceAccountToken: true` on a workload that doesn't need it, plus a wide-scoped RoleBinding
- ClusterRoleBinding granting `cluster-admin` to a namespaced workload
- Secrets mounted via env vars where files would do — and especially secrets baked into ConfigMaps
- NetworkPolicies removed or replaced with `allow-all` ingress/egress
- Ingress controllers exposing internal services without auth
- Container images pulled by mutable tag (`:latest`) for production workloads

### Terraform & IaC

- `sensitive = false` (or omitted) on outputs that contain secrets, connection strings, or keys
- Secrets in `variable "..." { default = "..." }` or hard-coded in `main.tf`
- Remote backend without encryption (`encrypt = false` on S3 backend) or without state locking (no DynamoDB table / no Azure Storage lease)
- State files committed to the repo (`terraform.tfstate`, `*.tfstate.backup`)
- Provider version unpinned (no `required_providers` block, or `version = ">= 0"`) on a security-critical provider
- `local-exec` / `remote-exec` provisioners running shell with interpolated variables that could be attacker-influenced
- `count`/`for_each` patterns that silently widen IAM/RBAC scope (e.g. iterating over a list that includes `"*"`)
- Modules sourced from arbitrary git refs (`?ref=main`) instead of pinned tags/SHAs — supply-chain risk
- Resources with `lifecycle { prevent_destroy = false }` on irreplaceable security resources (KMS keys, root CA, audit log sinks)

### CI/CD & Pipelines

- GitHub Actions with `pull_request_target` plus `actions/checkout` of the PR head — classic poisoned-pipeline RCE
- Workflows using untrusted PR input (`github.event.pull_request.title`, `body`, `head_ref`) directly in `run:` blocks without quoting/escaping
- Third-party actions pinned by tag (`@v3`) instead of full SHA on workflows that have access to secrets or `id-token: write`
- `permissions:` defaulting to `write-all` instead of least-privilege
- Self-hosted runners on public repos without isolation
- Pipeline secrets echoed (e.g. `echo $SECRET`, `set -x` with secret env vars) in a way that lands in logs

---

## General Notes

- Local-network-only exploitability is still HIGH if the impact is high. A vuln reachable only inside a VPC / VNet can absolutely be HIGH.
- React, Angular, Vue are XSS-safe **except** when using `dangerouslySetInnerHTML`, `bypassSecurityTrustHtml`, `v-html`, or equivalent. Do not flag plain JSX interpolation.
- Logging URLs is assumed safe. Logging high-value secrets in plaintext is not.
- UUIDs are unguessable enough — do not require additional validation on them.
- Environment variables and CLI flags are trusted inputs in a secure environment — but **secrets baked into IaC defaults or pipeline `env:` blocks** are not, since the source is committed.
- For cloud findings, always anchor severity to blast radius: a wildcard role at subscription/account scope is HIGH; the same wildcard scoped to a single resource group with no production data may be MEDIUM or out of scope.
