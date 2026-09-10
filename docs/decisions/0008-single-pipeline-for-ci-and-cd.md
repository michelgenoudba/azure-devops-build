# 0008. Single multi-stage pipeline for CI and CD

## Status
Accepted

## Context
The CD step needs to `helm upgrade --install` the exact image that CI just
built and pushed to ACR — not a re-derived guess at what CI built, the
actual tag from that actual run. Two structures were considered:

1. **One pipeline, two stages.** Extend `ci-build.yml` with a `Deploy`
   stage that runs after `Build`, in the same pipeline run. The image tag
   computed during `Build` is passed to `Deploy` as a stage output
   variable.
2. **Two separate pipelines.** Keep `ci-build.yml` as-is and add a new
   pipeline triggered on its completion via `resources: pipelines:`.

Azure Pipelines variables are scoped to the run that sets them — a
`resources: pipelines:` trigger does not hand a variable like `$(imageTag)`
across to the triggered pipeline. The triggered pipeline only gets the
triggering run's metadata (e.g. its source commit) and any artifacts the
triggering run explicitly published. So Option 2 would still need to either
recompute the tag from that source commit, or have Build publish a small
file containing the tag for Deploy to download — extra plumbing whose only
job is reconstructing information the same pipeline run already had.

## Decision
Extend `ci-build.yml` into a two-stage pipeline: `Build` (all existing
steps — validation, Lighthouse, image build, Trivy scan, ACR push)
followed by `Deploy`. The image tag flows from `Build` to `Deploy` as a
stage output variable, guaranteeing Deploy always installs the exact image
Build just produced — no separate lookup, no risk of drift between what
was built and what gets deployed.

`Build` continues running on the Microsoft-hosted `ubuntu-latest` pool
(ACR push only needs a public endpoint). `Deploy` runs on the self-hosted
agent pool (`self-hosted-dev`, on `vm-agent-dev`), since it's the only
thing with network access to the private AKS API server.

## Consequences
**Positive**
- The deployed image tag is always exactly what Build just produced — no
  possibility of the two drifting apart, by construction rather than by
  discipline.
- One pipeline file to reason about instead of two, with an explicit
  `dependsOn` making the Build → Deploy relationship visible in the YAML
  itself, not just in how they happen to be wired together.

**Negative**
- Build and Deploy are coupled into one pipeline run: a failing Deploy
  can't be retried independently of Build without re-running the whole
  pipeline (though Azure Pipelines does support re-running failed stages
  only, which mitigates this).
- Deploying a specific *older* already-built tag on demand (outside of
  "whatever Build just produced") isn't naturally supported by this
  structure and would need a separate, explicit mechanism if ever needed.

## Alternatives considered
- **Two separate pipelines with a `resources: pipelines:` trigger.**
  Rejected — solves a coordination problem (independent build/deploy
  cadence, useful when multiple consumers deploy at different times) this
  solo project doesn't have, echoing the same reasoning as ADR 0002's
  rejection of GitFlow, while adding real complexity: reconstructing the
  image tag across a pipeline boundary that doesn't share it natively.