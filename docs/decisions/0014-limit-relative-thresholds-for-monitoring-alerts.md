# 0014. Limit-relative thresholds and log-query alerts for Phase 07 monitoring

## Status
Accepted

## Context
Phase 07 build step 2 validated five KQL queries against real workspace data
(latency, JS exceptions, HTTP error rate, pod health, CPU/memory) and built
them into the `azure-devops-build-monitoring` workbook. Build step 3 turns
those into actual alert rules, which means picking real threshold numbers
rather than arbitrary ones.

The observed 30-day baseline (Sept 2026) is:
- Page load latency: p95 ~300-320ms, p99 ~320-370ms.
- HTTP error rate: a solid 0% across every sampled hour, including one hour
  with 5,404 real requests.
- Container CPU/memory (`static-site` container): peaks around 1.8M
  `cpuUsageNanoCores` (1.8m core) and a flat ~3MB working set.

That last number is the crux of this decision. The Helm chart
(`helm/static-site/values.yaml`) sets `resources.requests` at `cpu: 50m` /
`memory: 32Mi` and `resources.limits` at `cpu: 200m` / `memory: 128Mi`. The
observed peak is under 4% of the *request* and under 1% of the *limit* — the
container is essentially idle relative to its own budget, because it's a
static nginx page under light study-session traffic. A "baseline + margin"
threshold (the approach used for latency and error rate below) would
therefore produce a number so far below the limit that it carries no real
signal about resource pressure, and would need re-deriving every time
traffic patterns change.

Separately, three of the five signals (latency, JS exceptions, HTTP error
rate) only exist as Application Insights / container log data — there is no
equivalent platform metric to alert on directly — while CPU/memory *does*
have a native Azure Monitor metric alert path via AKS Insights.

## Decision
1. **Implement all five alerts as `azurerm_monitor_scheduled_query_rules_alert_v2`
   resources against the Log Analytics workspace**, reusing the exact KQL
   already validated in build step 2, rather than splitting CPU/memory off
   onto a native metric alert. One alerting mechanism for all five signals
   is simpler to reason about than two, and it reuses queries that already
   account for this project's specific schema quirks (legacy `ContainerLog`
   over `ContainerLogV2`, workspace-level `App*` table names) instead of
   re-deriving equivalent logic against a different query surface.

2. **Set the CPU/memory alert threshold as a percentage of the Helm chart's
   own resource *limits* (80% of `cpu: 200m` / `memory: 128Mi`), not as a
   margin above the observed baseline.** Limit-relative headroom is what
   actually predicts throttling or OOMKill risk, independent of how much
   traffic the site is currently getting. It also means the threshold
   doesn't need to be revisited if usage grows — it already means the same
   thing at any traffic level.

3. **Set the other four thresholds baseline-relative**, since those baselines
   are meaningful on their own terms:
   - Latency: p95 `DurationMs` > 1000ms (~3x the observed p95) — absorbs
     normal variance from the small sample while still catching a real
     regression.
   - HTTP error rate: non-probe 5xx rate > 5%, only evaluated when at least
     10 real requests occurred in the window — a standard SRE default,
     guarded against a quiet window reading as a false 100%.
   - JS exceptions and pod health: any occurrence at all — both baselines
     are exactly zero, and at this scale zero tolerance is cheap and
     meaningful.

4. **Single action group with one email receiver** (`michelgenoudba@hotmail.fr`)
   — this is a single-maintainer study project, not a team rotation, so
   additional receivers or routing rules would be complexity with no
   corresponding benefit.

## Consequences
**Positive**
- All five alerts share one mechanism (scheduled query rules) and reuse
  already-verified, already-debugged queries — no second query dialect or
  schema investigation needed.
- The CPU/memory threshold stays correct as traffic grows, since it's
  anchored to the pod's own resource envelope rather than a snapshot of
  current usage.
- Every threshold in this ADR is traceable to either a real observed number
  or a real configured limit — none are round numbers picked without
  justification.

**Negative**
- Log-query alerts have coarser evaluation granularity (5-minute frequency,
  15-minute window) than native metric alerts, which can evaluate faster.
  Not a concern at this project's scale.
- If the Helm chart's `resources.limits` change, the CPU/memory alert
  thresholds are computed inline in the KQL (hardcoded to 200000000
  nanocores / 134217728 bytes) and must be updated by hand to match —
  there's no single source of truth shared between the Helm values and the
  Terraform alert query.

## Alternatives considered
- **Native `azurerm_monitor_metric_alert` for CPU/memory, log-query alerts
  for the rest.** Rejected — splits the alerting logic across two
  mechanisms for one modest consistency cost, in exchange for faster
  evaluation this project doesn't need.
- **CPU/memory threshold set as a margin above observed baseline (same
  pattern as latency).** Rejected — the baseline is too small a fraction of
  the limit for any multiple of it to mean "at risk of throttling."
- **Zero-tolerance (>0%) for HTTP error rate, matching JS exceptions and pod
  health.** Rejected — occasional single-request blips are expected noise
  even in healthy systems; 5% is a widely used, defensible threshold rather
  than an arbitrary stricter one.