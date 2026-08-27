# 0003. Use a single VNet with two subnets, no further segmentation

## Status
Accepted — 2026-08-27

## Context
Azure networking supports arbitrarily deep segmentation — multiple VNets,
peering, hub-and-spoke topologies, dedicated subnets per workload tier,
network security groups per subnet, private endpoints, and so on. Real
production environments often need much of this, particularly once
compliance, multi-team isolation, or hybrid connectivity enter the picture.

This project has none of those drivers. It is a single-developer learning
and portfolio environment with one workload (a static site behind nginx,
eventually running on AKS), one environment actively used at a time (dev —
prod is defined in Terraform but not necessarily kept running, per the
destroy/rebuild-for-cost-control practice), and no compliance or
multi-tenant requirements. Over-engineering the network topology here would
add real complexity — more resources to reason about, more places for a
misconfiguration to hide — without teaching anything AZ-400 actually tests,
which focuses on IaC and pipeline practice, not deep Azure networking
design.

## Decision
Use a single Virtual Network per environment, with exactly two subnets:

- `snet-aks` — reserved for the AKS cluster's nodes (and, with Azure CNI,
  pod IPs), sized `/24` to leave comfortable headroom for pod scaling
  without needing to resize later.
- `snet-services` — reserved for anything else the project needs a subnet
  for later (e.g. a private endpoint for Key Vault or ACR, if that becomes
  worth doing), also sized `/24`.

The networking module is written generically (subnets are passed in as a
map, not hardcoded), so this decision can be revisited later without
rewriting the module itself — only the values passed into it from the
environment configuration would change.

No network security groups, route tables, or peering are configured at
this stage. The AKS module in phase 03 will decide whether NSGs are
needed for cluster-specific rules; nothing here rules that out later.

## Consequences

**Positive:**
- Minimal surface area to understand and reason about while learning
  Terraform itself — the goal of this phase.
- The module's generic subnet-map design means adding a third subnet later
  (if a real need appears) is a small, additive change, not a rewrite.

**Trade-offs:**
- No network-level isolation between the AKS workload and anything else
  that lands in `snet-services` — acceptable here since there is currently
  nothing else, and this is not a multi-tenant environment.
- If this project ever needed to demonstrate deeper networking competence
  (NSGs, private endpoints, hub-and-spoke) for a specific interview or
  exam-prep purpose, that would be a deliberate, separate addition — not
  something this phase's scope silently prevents.

## Alternatives considered
- **Hub-and-spoke or multi-VNet topology**: rejected — solves problems
  (shared services across many workloads/teams, centralized egress control)
  this project doesn't have.
- **A single flat subnet with no segmentation at all**: rejected — even a
  minimal two-subnet split costs nothing extra to set up now and keeps the
  door open for a private endpoint later without needing to redesign the
  address space.