# 0009. Shared cluster, namespace-based environment separation for staging/prod

## Status
Accepted

## Context
Phase 05 requires demonstrating a staging validation step followed by an
approved promotion to prod, with real Azure DevOps Environments and a manual
approval gate before prod. ADR 0005 already decided against provisioning a
real, physically separate `prod` environment at the Terraform/infrastructure
level, for cost and rebuild-effort reasons specific to this being a
single-contributor learning project rather than a production system.

The same tension applies one layer up, at the ADO Environment / Kubernetes
deployment level: a genuinely separate prod would mean a second AKS cluster,
a second self-hosted agent VM (with its own SSH key and manual systemd
registration), both Azure RBAC layers (ARM Contributor and Kubernetes RBAC
Cluster Admin) redone against a new cluster resource, and a new
federated identity credential tied to the new cluster's own OIDC issuer.
Estimated ongoing cost is roughly $10-15/month at moderate usage, with
roughly half of that billing continuously regardless of the project's
existing stop/deallocate discipline (Standard SKU public IPs bill hourly
even while unattached).

None of that rebuild teaches a new concept for this phase — it's the same
Terraform modules, the same role assignment patterns, and the same agent
registration steps already exercised for `dev`. What Phase 05 is actually
testing (per the AZ-400 Coverage mapping) is the pipelines-and-deployments
domain: approval gates, promotion flow, deployment strategy — none of which
requires physically separate infrastructure to demonstrate authentically.

## Decision
Staging and prod share the single existing AKS cluster
(`aks-azure-devops-build-mg`), separated by Kubernetes namespace rather than
by cluster:

- The existing `dev` ADO Environment and `app` namespace are retired and
  replaced by `staging` / `app-staging` — the validation step already being
  performed this week is renamed to reflect what it actually is.
- A new `prod` ADO Environment is created, targeting a new `app-prod`
  namespace on the same cluster, with a manual approval check attached.
- The CD pipeline's single `Deploy` stage becomes two sequential stages,
  `DeployStaging` and `DeployProd`, both deploying the exact same
  pipeline-built image tag (a real promotion of one validated artifact,
  not a rebuild) via `helm upgrade --install` against their respective
  namespaces.
- No new Azure infrastructure, no second agent VM, no second RBAC setup.

## Consequences

**Positive:**
- Zero additional infrastructure cost or rebuild effort beyond this week's
  work.
- The approval-gate mechanics, promotion flow, and deployment YAML are
  identical to what a physically separate prod would require — the actual
  exam-relevant skill is demonstrated authentically.
- Consistent with ADR 0005's existing reasoning; the two decisions now form
  one coherent story rather than contradicting each other.

**Trade-offs:**
- No real infrastructure blast-radius isolation between staging and prod —
  a mistake in one namespace's manifests could theoretically affect cluster-
  level resources shared by both (though not the other namespace's own
  workloads).
- Doesn't exercise genuine multi-environment Terraform state management, or
  cross-resource-group service connection scoping, in practice — both
  remain documented-but-unproven decisions, same as ADR 0005 already
  acknowledged for the Terraform layer.
- If this project ever needed to demonstrate real infrastructure-level
  environment isolation (e.g., for an actual production workload), this
  decision would need revisiting.

## Alternatives considered
- **Fully separate prod environment** (second AKS cluster, agent VM, and
  RBAC setup): rejected — cost and rebuild effort with no corresponding
  learning value for this phase, per the analysis above.
- **Reuse `dev`/`app` unchanged and bolt `prod` on as a third target**:
  rejected in favor of renaming `dev`→`staging`, since the validation work
  already happening there is conceptually staging, not a separate
  standalone environment — keeping it as "dev" would misdescribe its actual
  role once a real promotion flow exists.