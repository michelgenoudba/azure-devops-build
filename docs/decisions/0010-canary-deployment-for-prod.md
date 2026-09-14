# 0010. Canary deployment strategy for prod via shared Service selector

## Status
Accepted

## Context
Phase 05 requires a real (not just described) deployment strategy — blue-green or
canary — beyond a plain rolling `helm upgrade`, plus (item 4) a rollback procedure
that's actually been exercised. The cluster has no ingress controller, no service
mesh, and Kubernetes Deployments have an immutable `spec.selector`, which rules out
lightweight traffic-splitting tools and constrains how any strategy can be
retrofitted onto the already-running `app-staging`/`app-prod` Deployments created in
the previous phase.

Two realistic options were considered:
1. **Canary via a second Deployment sharing the existing Service's selector.** A
   small number of new-version pods run alongside the existing stable Deployment;
   the Service (which selects only on `app.kubernetes.io/name`/`instance`)
   naturally load-balances across both, splitting traffic roughly by replica ratio.
2. **Blue-green via Service selector swap.** A full-capacity parallel Deployment is
   created, verified, and traffic is switched atomically by repointing the
   Service's selector at it.

## Decision
Implement canary via a second Deployment. The existing stable `Deployment`/`Service`
in the `static-site` Helm chart are left completely unchanged — `spec.selector` is
immutable, and both `app-staging` and `app-prod` already have live Deployments
created before this decision, so any approach requiring a selector change on the
existing resources would mean deleting and recreating them. Instead, a new,
conditionally-rendered `<release>-canary` Deployment is added to the chart with a
superset selector (`name`+`instance`+`track: canary`); the existing Service's
broader selector (`name`+`instance` only) matches pods from both Deployments
automatically, with no Service change required. Kubernetes' controller ownership
references prevent the stable Deployment from ever adopting or counting the
canary's pods, so the two coexist safely despite the selector overlap.

The CD pipeline's `DeployProd` stage becomes two: `CanaryProd` (a plain job, no
environment/approval — deploys a single canary pod running the new image, via
`helm upgrade --reuse-values` so the stable Deployment's image tag is left
untouched) followed by `PromoteProd` (a `deployment:` job against the existing
`prod` environment, keeping its manual approval — promotes the new image to the
full stable Deployment and disables the canary). This repositions the existing
approval gate to mean "approve promoting the observed canary to 100%," rather than
"approve releasing at all."

Staging is unchanged — a plain full rolling deploy — since its purpose is pre-prod
validation, not production risk mitigation.

## Consequences
**Positive**
- No new infrastructure, ingress controller, or service mesh required.
- Real traffic (however coarse the ratio) exercises the new version in prod before
  full promotion — a genuine early-warning signal, not a simulated one.
- Rollback is close to free: if the canary looks unhealthy, disabling it
  (`canary.enabled=false` without touching `image.tag`) leaves the stable
  Deployment exactly as it was, never having been touched. This doubles as the
  tested rollback procedure for item 4.
- The approval gate's meaning is now more precise and arguably more realistic than
  before.

**Negative**
- Traffic split is approximate (replica-count ratio), not a precise percentage — a
  real limitation without a mesh or ingress-level canary support.
- The stable Deployment's selector was deliberately left broader than the canary's
  rather than making both symmetric (`track: stable` / `track: canary`), which
  would be the more "textbook" design — done to avoid recreating already-running
  Deployments; a fresh project without this constraint would design selectors
  symmetrically from the start.
- Two Helm-templated Deployments to reason about instead of one, though the chart
  change is small and mostly additive.

## Alternatives considered
- **Blue-green via Service selector swap.** Rejected for this phase — needs
  slot-tracking logic (which Deployment is "live" right now) that Helm's release
  model doesn't provide natively, and gives no observation window under live
  traffic before cutover, unlike canary.
- **Symmetric `track` labels on both Deployments (redesigning the stable
  Deployment's selector).** Rejected — would require deleting and recreating the
  already-running `app-staging`/`app-prod` Deployments, an avoidable disruption for
  a cosmetic/consistency benefit only.