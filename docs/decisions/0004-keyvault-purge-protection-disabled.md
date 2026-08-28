# 0004. Disable purge protection on the dev Key Vault

## Status
Accepted — 2026-08-27

## Context
Azure Key Vault's purge protection prevents a deleted vault (or its
contents) from being permanently removed until the soft-delete retention
period expires — up to 90 days, regardless of the intent to delete it
sooner. This is Azure's recommended default for any vault holding real
production secrets, since it protects against accidental or malicious
permanent deletion.

This project follows a deliberate destroy/rebuild discipline for its dev
environment between working sessions, to control cost (see the roadmap's
Portfolio Evidence practices). Purge protection is directly incompatible
with that discipline: with it enabled, running `terraform destroy` would
not actually free the vault's name, and recreating a same-named vault in a
later session would fail until the retention window passed or someone
manually purged it via the Azure CLI/portal (a step outside Terraform's
control, and easy to forget or get wrong).

## Decision
The Key Vault module defaults `purge_protection_enabled = false` for this
project's dev environment, and sets `soft_delete_retention_days = 7` (the
minimum allowed), rather than leaving a longer retention period as the
default.

Both are exposed as module variables specifically so this can be
overridden per environment — if this project ever provisions a genuinely
long-lived environment (e.g. a real "prod" holding real secrets rather
than portfolio placeholders), that environment's configuration should
explicitly set `purge_protection_enabled = true`.

Soft delete itself cannot be disabled — Azure has made it mandatory for
all Key Vaults regardless of this decision. This ADR only concerns purge
protection and the retention window length.

## Consequences

**Positive:**
- `terraform destroy` in dev genuinely removes the vault, keeping the
  destroy/rebuild cost-control discipline workable without manual
  workarounds.
- The 7-day minimum retention (rather than the 90-day default) means even
  an accidental deletion is recoverable for a short window, without
  standing in the way of intentional teardown.

**Trade-offs:**
- A real accidental or malicious deletion of the dev vault is only
  protected for 7 days, not up to 90. Acceptable here because nothing
  stored in this vault is a production secret with real-world
  consequences — it's a learning/portfolio environment.
- This decision must be deliberately reversed (not just left as a
  forgotten default) if this project's Key Vault ever starts holding
  anything that matters beyond this project itself.

## Alternatives considered
- **Leave Azure's default settings** (purge protection off, but 90-day
  retention): rejected — the long retention window has no benefit here and
  only adds friction if a same-named recreate is ever needed sooner.
- **Enable purge protection**: rejected — actively breaks the
  destroy/rebuild workflow this project depends on for cost control.