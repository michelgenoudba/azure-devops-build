# 0012. Decouple Terraform-managed authorization from the identity running Terraform

## Status
Accepted

## Context
ADR 0011 automated Terraform via a pipeline for the first time. Two existing
resources — `aks_rbac_cluster_admin_self` and `self_kv_secrets_officer` —
granted access to `data.azurerm_client_config.current.object_id`: whoever
happens to be authenticated when Terraform runs. That was always the
maintainer's own identity, until the pipeline started running Terraform too.

The first pipeline-driven apply exposed the problem: `data.azurerm_client_config.current`
now resolved to the pipeline's service principal instead, and both `_self`
resources tried to replace their existing (maintainer-owned) role assignment
with one for the pipeline — colliding with role assignments that were already
explicit about which identity they were for (`aks_rbac_cluster_admin_pipeline`,
and a manually bootstrapped Key Vault grant from ADR 0011's own bootstrap
step). Azure correctly rejected the duplicate creates with
`409 RoleAssignmentExists`. The AKS-side old assignment had already been
destroyed by the time the create failed, leaving the maintainer briefly
without Cluster Admin access until the fix below was applied.

## Decision
Stop granting standing access based on "whoever is currently running
Terraform." Add an explicit `maintainer_object_id` variable (same pattern as
`pipeline_service_principal_object_id`), and give every authorization
resource one clearly-named target instead of an ambient one:
- `aks_rbac_cluster_admin_self` → renamed `aks_rbac_cluster_admin_maintainer`,
  now targets `var.maintainer_object_id` explicitly.
- `self_kv_secrets_officer` → renamed `kv_secrets_officer_maintainer`
  (`var.maintainer_object_id`), plus a new `kv_secrets_officer_pipeline`
  (`var.pipeline_service_principal_object_id`) mirroring the AKS pattern.

The Key Vault side's manually-bootstrapped grant (ADR 0011) already *was*
what `kv_secrets_officer_pipeline` represents, so it was reconciled with
`terraform import` rather than destroy-then-recreate — avoiding a repeat of
the exact secret-read chicken-and-egg problem ADR 0011 already hit once.
The AKS side needed no import: its old assignment was already destroyed
cleanly, so the renamed resource was just a fresh create.

## Consequences
**Positive**
- Every Terraform-managed role assignment now has one stable, explicit
  owner. Whoever runs `terraform apply` — maintainer or pipeline — no
  longer changes what gets granted to whom.
- Closes this entire class of bug permanently, rather than just this one
  instance of it.

**Negative**
- One more required variable to keep in sync across `terraform.tfvars`,
  `terraform.tfvars.example`, and the pipeline's variables/`env:` block.
- The fix itself required a real, if brief, gap in the maintainer's own
  Cluster Admin / Key Vault access, and a one-time manual `terraform import`
  to reconcile with the earlier manual bootstrap grant.

## Alternatives considered
- **Leave `data.azurerm_client_config.current` in place, accept the churn.**
  Rejected — the collision would recur any time the applying identity
  changes, and a future occurrence might not resolve as cleanly as this one
  did (e.g. if the destroy step also failed, leaving state inconsistent).
- **Destroy and recreate the Key Vault duplicate instead of importing.**
  Rejected — would reopen the exact plan-time secret-read 403 from ADR 0011
  during the gap between destroy and create.