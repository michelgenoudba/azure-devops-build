# Security Plan — Azure DevOps Build

A one-page summary of how this project handles identity/access, secrets, and
image/IaC scanning. Consolidates decisions and audits already made across
earlier phases and ADRs, rather than introducing new controls.

## Access

- **Pipeline → Azure**: federated OIDC via the `sc-azure-devops-build`
  service connection (workload identity federation) — no service principal
  secret is stored anywhere. `AzureCLI@2` tasks perform an `az login` with
  the connection, and Terraform's `azurerm` provider and AD-authenticated
  backend both fall back to that active session.
- **AKS cluster access**: Azure AD RBAC (`azure_rbac_enabled = true`,
  `tenant_id` sourced from `data.azurerm_client_config.current`) — every
  `kubectl`/`helm` operation is authorized against a real AAD identity, not a
  static kubeconfig or cluster-admin certificate.
- **In-cluster workload identity**: the one workload that reaches an Azure
  resource (the Key Vault test secret) uses per-pod OIDC federation
  (service-account annotation + `AZURE_CLIENT_ID`/`AZURE_TENANT_ID`/
  `AZURE_FEDERATED_TOKEN_FILE`) — no client secret in a Kubernetes `Secret`.
- **Source control**: `main` is branch-protected on GitHub — PR + passing
  pipeline checks required, no direct pushes (ADR 0002).
- **Agent VM**: SSH locked down by NSG (`allowed_ip_ranges`, empty list =
  deny-all by default); its private key is Terraform-generated and stored in
  Key Vault, never committed (`agent-vm-key.pem` is `.gitignore`'d, confirmed
  never tracked via a git-history audit).
- **Terraform state**: `azurerm` backend using Azure AD auth, not a storage
  account key; the pipeline's service principal holds `Storage Blob Data
  Contributor` scoped to only that one storage account.

## Secret Management

- Zero secrets committed: verified by full-repo grep sweeps
  (password/secret/token/key patterns and GUID-shaped strings) plus a
  targeted git-history check confirming `*.pem` and the real
  `terraform.tfvars` were never tracked.
- Real environment values (subscription/tenant/object IDs, the SSH key, the
  IP allowlist) live only in the gitignored `terraform.tfvars` locally and in
  the pipeline's service connection/variable groups. The committed
  `terraform.tfvars.example` uses dummy placeholders only.
- Key Vault stores the one real secret this project generates (the agent
  VM's SSH private key), firewalled to the agent subnet and maintainer IP.
- No secret ever appears in pipeline YAML — access flows through the service
  connection's implicit `az login` or Key Vault references only.

## Image & IaC Scanning

- **Container images**: Trivy scans every image in `ci-build`
  (`--severity CRITICAL,HIGH --ignore-unfixed --exit-code 1`) before it's
  pushed to ACR; a failing scan blocks the pipeline.
- **Terraform**: a required PR check (`terraform-scan-gate`) runs a config
  scan plus a real `terraform plan` on every infra change before it can
  merge; `apply` only runs after merge, behind a separate human-approved
  gate (ADR 0011).
- **Dependencies**: Dependabot (`docker` + `terraform` ecosystems, weekly).
  Two real PRs were reviewed and merged, including a major
  `hashicorp/azurerm` version bump that required fixing two genuine v5
  breaking schema changes, verified against a real merge-time plan before
  approval.
- **Application code**: GitHub CodeQL default setup is enabled; it currently
  reports no supported language in this repo (Terraform/YAML/Helm/static
  HTML are out of its scope), left on as a no-cost default that
  self-activates if application code is ever added.
- **Centralized posture**: Microsoft Defender for Cloud DevOps Security
  (GitHub connector, Foundational tier, free during preview) — connector
  created, agentless scanners (eslint, bandit, templateanalyzer, checkov,
  trivy) enabled; first-scan findings pending review.

## Known Gaps

- Defender for Cloud findings not yet reviewed — connector was only just
  created.
- CodeQL is a placeholder until application code exists in this repo.
- No formal periodic access review yet — acceptable for a single-contributor
  project; would need one before adding a second contributor.