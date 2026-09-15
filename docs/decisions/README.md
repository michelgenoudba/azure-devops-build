# Architecture Decision Records

This folder records the significant technical and process decisions made
during this project, in the lightweight ADR format: Status, Context,
Decision, Consequences, and (where relevant) Alternatives considered.

Not every choice gets an ADR — only the ones with real trade-offs worth
justifying later, whether in an interview, on the exam, or to a future
version of myself who's forgotten why something was done a certain way.

## Index

| # | Title | Status |
|---|---|---|
| [0001](0001-scope-identity-to-resource-group.md) | Scope the Azure DevOps service connection identity to the resource group, not the subscription | Accepted |
| [0002](0002-trunk-based-branching.md) | Use trunk-based development with short-lived feature branches | Accepted |
| [0003](0003-minimal-network-topology.md) | Use a single VNet with two subnets, no further segmentation | Accepted |
| [0004](0004-keyvault-purge-protection-disabled.md) | Disable purge protection on the dev Key Vault | Accepted |
| [0005](0005-environment-separation-strategy.md) | Environment separation strategy | Accepted |
| [0006](0006-azure-cni-networking-for-aks.md) | Azure CNI networking for AKS | Accepted |
| [0007](0007-azure-rback-for-kubernetes-authorization.md) | Azure RBAC for Kubernetes authorization | Accepted |
| [0008](0008-single-pipeline-for-ci-and-cd.md) | Single multi-stage pipeline for CI and CD | Accepted |
| [0009](0009-shared-cluster-namespace-environments.md) | Shared cluster, namespace-based environment separation for staging/prod | Accepted |
| [0010](0010-canary-deployment-for-prod.md) | Canary deployment strategy for prod via shared Service selector | Accepted |
| [0011](0011-terraform-plan-apply-automation.md) | Automated Terraform plan-on-PR and approval-gated apply-on-merge | Accepted |
| [0012](0012-decouple-terraform-authorization-from-running-identity.md) | Decouple Terraform-managed authorization from the identity running Terraform | Accepted |

## Conventions

- Numbered sequentially, zero-padded to 4 digits (`0001-`, `0002-`, ...).
- Filename is the number plus a short kebab-case slug of the decision.
- Status is one of: `Proposed`, `Accepted`, `Superseded by 000X`, `Rejected`.
- A decision that gets reversed later isn't deleted — a new ADR supersedes
  it, and the old one's Status is updated to point to the new one. The
  history of *why* something changed is as valuable as the current state.