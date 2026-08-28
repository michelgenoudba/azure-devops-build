# 0005: Environment Separation Strategy

## Status
Accepted

## Context
All infrastructure currently lives under `infra/environments/dev`, with a single
Terraform state file and hardcoded dev-specific values (resource group, naming,
tags). As the project's Terraform modules (networking, ACR, Key Vault, Log
Analytics) have matured, it's worth deciding — before it's actually needed — how
a second environment such as `prod` would be structured, so the pattern is a
deliberate decision rather than something bolted on ad hoc later.

Two realistic approaches exist:

1. **Separate environment directories.** `infra/environments/dev/` and
   `infra/environments/prod/`, each with its own `backend.tf` pointing at a
   dedicated state file key, each with its own `main.tf` wiring up the shared
   modules under `infra/modules/` with environment-specific values.
2. **Single environment directory, parameterized by `.tfvars`.** One shared
   `main.tf` and backend, with `dev.tfvars` / `prod.tfvars` files supplying
   different values, switched via `-var-file` or Terraform workspaces.

## Decision
Adopt separate environment directories per environment. Each environment gets
its own directory under `infra/environments/<env>/` with its own `backend.tf`
(dedicated state file key), its own `main.tf` calling the shared modules in
`infra/modules/`, and its own `outputs.tf`.

This project will not provision a real `prod` environment at this time,
consistent with the destroy/rebuild-for-cost-control approach used throughout
this build. `infra/environments/prod/` exists only as a placeholder directory
with a README documenting the intended structure, so the decision is recorded
even though it isn't exercised.

## Consequences
**Positive**
- Full state isolation between environments — a mistake in one environment's
  plan or apply can never touch another environment's state file.
- Matches how most real teams structure multi-environment Terraform once
  environments diverge in more than just variable values.
- Each environment can be destroyed and rebuilt independently with no risk of
  side effects on another environment.

**Negative**
- Some duplication of environment wiring (`main.tf`, `outputs.tf`) between
  `dev/` and any future `prod/` — mitigated by both calling the same versioned
  modules, so the duplication is mostly variable values, not logic.
- No prod environment currently exists to validate the pattern end-to-end; the
  placeholder documents intent rather than proven practice within this project.

## Alternatives considered
- **Single environment directory + `.tfvars` per environment.** Rejected
  because it implies a single shared state file (or workspace-partitioned
  state within one backend) across all environments, which increases blast
  radius if a plan/apply is run against the wrong var-file, and because
  workspace-based state partitioning is a common source of accidental
  cross-environment applies on real teams.