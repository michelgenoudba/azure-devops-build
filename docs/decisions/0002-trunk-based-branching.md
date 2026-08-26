# 0002. Use trunk-based development with short-lived feature branches

## Status
Accepted — 2026-08-26

## Context
A source control strategy needs to be chosen and documented, not just
defaulted into. The two mainstream candidates are GitFlow (long-lived
`develop`/`release`/`hotfix` branches alongside `main`) and trunk-based
development (a single long-lived branch, `main`, with short-lived feature
branches merged in frequently via pull request).

This is a solo project with no parallel team streams, no need to support
multiple released versions simultaneously, and no formal release-train
cadence. GitFlow's extra branch types exist specifically to solve
coordination problems between multiple contributors and multiple
in-flight release versions — problems this project does not have.

GitHub's branch protection model also has a specific limitation worth
noting up front: a required PR reviewer cannot approve their own pull
request. On a solo repository, requiring human approval before merge would
permanently block every PR, since there is no second person to approve it.

## Decision
This project uses trunk-based development:

- `main` is the single source of truth and is always deployable.
- All work happens on short-lived feature branches (`feature/<short-name>`,
  `fix/<short-name>`), branched from `main` and merged back via pull request
  within a day or two — no branch stays open long enough to drift
  significantly from `main`.
- `main` is protected: direct pushes are disabled, a pull request is
  required to merge, and the pipeline's build/status check must pass before
  merge is allowed.
- Human-approval review is deliberately **not** required as a merge gate,
  since GitHub blocks self-approval and this is a single-contributor
  repository. The automated status check (pipeline passing) substitutes for
  review as the enforced quality gate. This is recorded here explicitly so
  it reads as a deliberate trade-off rather than a missing control.
- Commit messages follow the Conventional Commits format
  (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) to keep history
  readable and to make the eventual changelog/versioning story
  straightforward if this project ever needs one.

## Consequences

**Positive:**
- No long-lived divergent branches to reconcile; `main` always reflects the
  latest working state.
- The branch-protection + required-status-check combination gives a real,
  enforced quality gate (nothing merges without the pipeline passing) even
  without a second human reviewer.
- Conventional Commits make it easy to scan history for what changed and
  why, and set up cleanly for the DORA-metrics/Azure Boards traceability
  work planned for phase 08.

**Trade-offs:**
- No human code review happens before merge. In a team context this would
  be a real gap; here it is an accepted and documented consequence of
  working solo, not an oversight.
- If this project ever gains a second contributor, this decision should be
  revisited — human-approval review becomes both possible and valuable at
  that point, and this ADR's reasoning would no longer hold.

## Alternatives considered
- **GitFlow**: rejected — its release/hotfix branch machinery solves
  multi-contributor, multi-version coordination problems this project does
  not have, and would add process overhead with no corresponding benefit.
- **Required PR approval as a merge gate**: rejected as unworkable for a
  solo repository, since GitHub does not allow a PR author to approve their
  own pull request.
