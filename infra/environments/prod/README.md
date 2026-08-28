# Prod Environment — Not Yet Provisioned

This directory is a placeholder. No prod infrastructure has been created for
this project — see [ADR 0005](../../decisions/0005-environment-separation-strategy.md)
for the intended structure if a prod environment is ever added.

Following the pattern established in `dev/`, a prod environment would include
its own `backend.tf` (separate state file key), `main.tf` (wiring the shared
modules under `infra/modules/`), and `outputs.tf`.