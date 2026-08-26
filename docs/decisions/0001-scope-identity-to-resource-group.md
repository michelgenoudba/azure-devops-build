# 0001. Scope the Azure DevOps service connection identity to the resource group, not the subscription

## Status
Accepted — 2026-08-26

## Context
Azure DevOps needs an identity to authenticate against Azure and provision/manage
resources on behalf of the pipelines in this project. Azure DevOps' Azure Resource
Manager service connection wizard offers three scope levels for this identity:
Subscription, Management Group, or (via a separate Resource group picker)
a single resource group.

Defaulting to subscription-wide access is the path of least resistance — it is
the pre-selected option in the wizard, and it avoids ever having to touch the
scope again as new resources are added later in the project (AKS, ACR, Key
Vault, storage for Terraform state, etc.).

However, this project is a personal learning/portfolio environment, actively
built and rebuilt over several months, with pipeline definitions, scripts, and
logs that are iterated on quickly and not always reviewed as carefully as
production code would be. A credential (or in this case, a federated identity)
with subscription-wide Contributor rights that leaks — through a misconfigured
pipeline log, a copy-pasted output, or a mistake in a script — has a blast
radius covering every resource in the subscription, not just this project.

## Decision
The Azure DevOps service connection (`sc-azure-devops-build`) is granted
**Contributor** access scoped only to the `rg-azure-devops-build` resource
group, not the subscription.

This was implemented using workload identity federation (OIDC) rather than a
classic service principal with a stored secret, so there is no long-lived
credential to leak in the first place — Azure DevOps exchanges a short-lived
federated token for an access token at pipeline run time.

Because every resource this project provisions (AKS cluster, ACR, Key Vault,
Log Analytics workspace, Terraform state storage account, etc.) will live
inside `rg-azure-devops-build`, this scope is sufficient for the full project
without ever needing to widen it.

## Implementation notes (troubleshooting log)
Setting this up did not go entirely smoothly, and the friction itself is worth
recording:

- The Azure DevOps "New service connection" wizard's automatic resource-group
  picker (Identity type: App registration (automatic), Credential: Workload
  identity federation (automatic)) got stuck indefinitely on "Loading resource
  groups," and once it stopped loading, the dropdown only ever offered "All
  resource groups" — even though the resource group existed, the subscription
  ID matched exactly what `az account show` reported locally, and there was no
  account mismatch between the Azure DevOps browser session and the Azure CLI
  session. This appears to be a flaky spot in Azure DevOps' automatic resource
  group enumeration for this identity/credential combination, not a
  configuration error on the project's side.
- Fallback path: created the app registration (`sc-azure-devops-build`)
  manually in Microsoft Entra ID, then used Azure DevOps' "App registration or
  managed identity (manual)" + "Workload identity federation (manual)" flow.
  In this flow, Azure DevOps itself generates the Issuer
  (`https://login.microsoftonline.com/{tenantId}/v2.0`) and Subject identifier
  (an `/eid1/c/pub/t/.../a/.../sc/...` formatted string tied to the specific
  service connection), which then have to be registered as a federated
  credential on the app registration in Entra ID — the reverse of what most
  walkthroughs describe (constructing an `sc://{org}/{project}/{connection}`
  subject and a `vstoken.dev.azure.com/{orgId}` issuer by hand). Both formats
  are valid; which one applies depends on which identity/credential type is
  selected in the wizard.
- The Contributor role assignment on the resource group had to be made
  explicitly via IAM (Access control → Add role assignment → Contributor →
  the app registration), since the manual flow does not grant any RBAC role
  automatically the way the (working) automatic flow would have.
- Verified end-to-end by adding a temporary `AzureCLI@2` pipeline step running
  `az account show` and `az group show --name rg-azure-devops-build`, and
  confirming the pipeline log shows a genuine
  `az login --service-principal ... --federated-token ***` token exchange
  (no secret) followed by a successful resource group lookup.

## Consequences

**Positive:**
- A leaked pipeline log, script mistake, or compromised pipeline can, at
  worst, affect resources inside `rg-azure-devops-build` — it cannot read,
  modify, or delete anything else in the subscription.
- No stored secret exists anywhere for this connection; the credential is a
  short-lived federated token issued per pipeline run.
- The scoping decision and its RBAC assignment are auditable independently of
  the service connection itself, via the resource group's IAM blade.

**Trade-offs:**
- Any resource this project ever needs outside `rg-azure-devops-build` (for
  example, a shared/central Log Analytics workspace, or a second resource
  group for a genuinely separate environment) will require either a second,
  similarly-scoped service connection, or a deliberate, documented decision to
  widen this one — not a silent default.
- The manual workload-identity-federation setup required understanding both
  the Entra ID federated credential model and Azure DevOps' two different
  subject-identifier formats, which took longer than accepting the
  subscription-wide default would have. This cost was accepted as the price
  of least-privilege access and is now documented here so it does not need to
  be re-discovered later.

## Alternatives considered
- **Subscription-wide Contributor** (the wizard's default): rejected due to
  blast-radius concerns described above.
- **Classic service principal with a stored secret**: rejected in favor of
  workload identity federation, since it introduces a long-lived credential
  that has to be rotated and can be leaked, for no practical benefit over
  OIDC in this setup.
- **Owner role instead of Contributor**: rejected — Owner additionally grants
  the ability to manage role assignments (RBAC) on the resource group, which
  the pipelines have no need for. Contributor is sufficient to create, update,
  and delete resources.