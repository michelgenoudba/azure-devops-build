# 0011. Automated Terraform plan-on-PR and approval-gated apply-on-merge

## Status
Accepted

## Context
Phase 05 requires the Terraform workflow to work like the app's CD pipeline
already does: a plan surfaced automatically on every PR touching `/infra`, and
an apply that only happens after merge and an explicit approval — not the ad
hoc `terraform apply` runs from a contributor's own machine that every infra
change so far (including the AKS RBAC fix) has actually gone through.

This depends on a real, working remote state backend, which already exists
(`infra/environments/dev/backend.tf`, an `azurerm` backend using Azure AD auth
rather than a storage key) but had only ever been exercised by the
maintainer's own identity — the pipeline's service connection had no role on
the state storage account at all.

Two structural questions needed deciding:
1. **Where does `terraform plan` run for PR review** — a new dedicated check,
   or extending the existing `terraform-scan.yml` (already a required PR
   check running a Trivy config scan)?
2. **How does apply consume the reviewed plan** — re-run `plan` fresh at
   merge time and apply immediately, or thread the exact plan through as an
   artifact?

A third, less obvious question came up during implementation: **where can
Terraform actually run at all?** `main.tf` provisions a Key Vault secret
(`azurerm_key_vault_secret.workload_identity_test`), and reading or writing
that secret is a Key Vault *data-plane* operation, subject to the vault's
firewall (`allowed_ip_ranges` and `allowed_subnet_ids = [snet-agents]`). A
Microsoft-hosted agent's IP is never on that list. This is a separate
constraint from why `DeployStaging`/`DeployProd` need the self-hosted agent
(those need the private AKS API server) — Terraform never talks to that
private endpoint at all, since AKS itself is managed through the public ARM
control plane — but it lands on the same answer.

## Decision
**PR-time**: extend `pipelines/terraform-scan.yml` with a second job,
`TerraformPlan`, running `terraform init` + `terraform plan` on the
`self-hosted-dev` pool, alongside the existing `SecurityScan` job (unchanged,
still on the hosted pool, since a static scan of `.tf` files needs no Azure
network access at all). Both jobs run in parallel under the one existing
required check, rather than adding a second check for the same path.

**Merge-time**: a new pipeline, `pipelines/terraform-apply.yml`, triggered on
push to `main` for `infra/**` changes, with two stages in a single run —
mirroring ADR 0008's reasoning that a value computed in one stage must be
handed to the next within the same run, not re-derived:
- `Plan` (self-hosted-dev): `terraform init` + `terraform plan -out=tfplan`,
  publishes `tfplan` as a pipeline artifact.
- `Apply` (self-hosted-dev): a `deployment:` job against a new `infra` ADO
  Environment (distinct from `prod` — approving an infrastructure change is a
  different kind of decision than approving an app promotion) with a manual
  approval check, downloads the artifact, runs `terraform apply tfplan` —
  applying the exact plan that was computed, not a fresh one that could have
  drifted in the interim. Applying a saved plan file also has a convenient
  side effect: Terraform itself skips its own interactive approval prompt
  when applying a plan file, so the ADO environment's human approval is the
  only gate, not two redundant ones.

**Auth**: both pipelines authenticate via the existing `sc-azure-devops-build`
service connection using plain `AzureCLI@2` tasks, with no extra credential
plumbing. `AzureCLI@2` already performs an `az login` with the service
connection before running the inline script; Terraform's `azurerm` provider
and the AD-authenticated backend both fall back to that active CLI session
automatically when no explicit `ARM_*` credentials are set, so `terraform`
commands just work inside the same task — consistent with every other
`AzureCLI@2` task in this project, no new marketplace extension.

**Bootstrap gap closed manually, not via Terraform**: the pipeline's service
principal had no role on the `sttfstatemichelgenoudba` storage account at
all. Granted `Storage Blob Data Contributor`, scoped to that storage account,
via a one-time `az role assignment create` — not added as a Terraform
resource, since the very first pipeline-driven `apply` would need permission
to write the state file that resource would live in. Same category of
decision as the storage account's own creation: infrastructure that supports
Terraform has to be bootstrapped outside it.

## Consequences
**Positive**
- Every infra change now goes through the same review-then-approve
  discipline as the app pipeline, closing the gap where infra applies were
  the one thing still done by hand.
- The plan that gets approved is provably the plan that gets applied — no
  window for drift between plan and merge-time apply within one run.
- No new required checks, no new marketplace tasks, no new credential
  plumbing — reuses the existing scan pipeline and the same `AzureCLI@2`
  auth pattern already used everywhere else.

**Negative**
- The PR-time plan and the merge-time plan are still two separate
  invocations against potentially-different states (another PR could merge
  in between) — the PR-time plan is for human review, not a guarantee of
  what will actually be applied. Only the merge-time `Plan`→`Apply` pair
  within one run is drift-proof.
- If `Apply` sits waiting for approval long enough for a conflicting change
  to land on top, applying the stale `tfplan` fails loudly (Terraform
  detects the state has moved) rather than silently applying something
  wrong — acceptable for a single-contributor project; a faster-moving team
  would need a shorter approval SLA or a re-plan-on-apply pattern instead.
- One more ADO Environment to maintain (`infra`), though it costs nothing
  beyond initial setup.
- Both new pipeline jobs depend on the single self-hosted agent being online,
  same constraint the app deployments already have.

## Alternatives considered
- **A second required PR check dedicated to `terraform plan`.** Rejected —
  no reason to run two separate pipelines against the same `infra/**` path
  when one already exists and already gates PRs.
- **Re-running `plan` immediately before `apply` in the same stage, without a
  separate published-artifact stage boundary.** Rejected — collapses the
  natural place for the approval gate to sit (between plan and apply) and
  reintroduces the exact risk ADR 0008 avoided: applying something other than
  what was actually reviewed.
- **Granting the pipeline's storage role via Terraform.** Rejected —
  bootstrapping paradox: the first apply would need the very permission that
  resource grants.