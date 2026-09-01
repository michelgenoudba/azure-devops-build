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
| [0003](0003-minimal-network-topology.md) | Accepted | 
| [0004](0004-keyvault-purge-protection-disabled.md) | Accepted | 
| [0005](0005-environment-separation-strategy.md) | Accepted | 
| [0006](0006-azure-cni-networking-for-aks.md) | Accepted |
## Conventions

- Numbered sequentially, zero-padded to 4 digits (`0001-`, `0002-`, ...).
- Filename is the number plus a short kebab-case slug of the decision.
- Status is one of: `Proposed`, `Accepted`, `Superseded by 000X`, `Rejected`.
- A decision that gets reversed later isn't deleted — a new ADR supersedes
  it, and the old one's Status is updated to point to the new one. The
  history of *why* something changed is as valuable as the current state.