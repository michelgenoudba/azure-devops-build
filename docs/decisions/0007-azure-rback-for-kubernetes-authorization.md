# 0007: Azure RBAC for Kubernetes Authorization

## Status
Accepted

## Context
The AKS module originally used local Kubernetes RBAC only, meaning
`az aks get-credentials` handed out a static, cluster-admin kubeconfig
with no per-user identity, no audit trail, and no way to grant narrower
permissions — the "raw admin access" this step exists to remove.

AKS offers two ways to layer AAD identity on top: AAD-integrated
Kubernetes RBAC (`azure_rbac_enabled = false`), where permissions are
still granted via native Kubernetes `RoleBinding` objects referencing
AAD identities as subjects; or Azure RBAC for Kubernetes Authorization
(`azure_rbac_enabled = true`), where permissions are granted through
Azure role assignments — the same `azurerm_role_assignment` pattern
already used for Storage Blob Data Contributor and AcrPull elsewhere in
this project.

## Decision
Enable Azure AD integration with `azure_rbac_enabled = true`. Access is
granted per-identity via `azurerm_role_assignment`, scoped to the
cluster. The project's own identity (via
`data.azurerm_client_config.current.object_id`) is granted "Azure
Kubernetes Service RBAC Cluster Admin," appropriate for a solo operator
managing every namespace.

`local_account_disabled` is deliberately left at its default (`false`)
for now. AAD RBAC access was verified working end-to-end — a real
device-code login, a genuine 403 Forbidden before any role assignment
existed, and successful access after granting one — before considering
whether to remove the local admin fallback entirely. That removal is
tracked as a separate, deliberate follow-up decision, not bundled here.

## Consequences
**Positive**
- Every `kubectl` action is tied to a real Azure AD identity, not an
  anonymous static credential.
- Authorization is managed identically to every other resource in this
  project: explicit, scoped, versioned Azure role assignments.
- Verified end-to-end, not just applied.

**Negative**
- Adds `kubelogin` as a required local tool for anyone using `kubectl`
  against this cluster.
- The static admin credential still exists as a live fallback, so "raw
  admin access" isn't fully eliminated yet — only layered alongside
  proper AAD RBAC. Full removal is a deliberate follow-up.

## Alternatives considered
- **AAD-integrated Kubernetes RBAC (`azure_rbac_enabled = false`).**
  Rejected to keep this project's access-control pattern consistent:
  every other resource is governed by Azure role assignments, not a
  resource-specific permission model.