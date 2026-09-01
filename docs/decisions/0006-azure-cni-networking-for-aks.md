# 0006: Azure CNI Networking for AKS

## Status
Accepted

## Context
AKS supports two main networking models: kubenet, where pods get IPs from
an internal address space separate from the VNet and reach it through NAT,
and Azure CNI, where every pod gets a real, routable IP directly from a
VNet subnet. The choice affects pod addressability, compatibility with
some AKS features (e.g. certain network policy and monitoring
integrations), and subnet IP consumption.

## Decision
Use Azure CNI (`network_plugin = "azure"`), with pods and nodes sharing
the dedicated `snet-aks` subnet (10.0.1.0/24, provisioned in the
networking module in Phase 02 specifically with this in mind). The
Kubernetes Service (ClusterIP) address range is set explicitly to
10.100.0.0/16 — outside the VNet's own 10.0.0.0/16 space — since Azure
CNI's service CIDR must not overlap any VNet-routable range, even though
service addresses are virtual and never actually routed on the VNet.

## Consequences
**Positive**
- Pods are first-class VNet citizens: reachable directly, subject to NSGs,
  compatible with Azure-native network policy and monitoring features.
- Matches the modern, more "real-world" AKS networking pattern — kubenet
  is the simpler legacy option and is being phased toward deprecation.

**Negative**
- Every pod consumes a real subnet IP, requiring the subnet to be sized
  with real headroom. A /24 (251 usable IPs) is comfortable for this
  small dev cluster but would need reconsidering at meaningfully larger
  scale.
- Requires explicit, non-overlapping CIDR planning (service CIDR, DNS
  service IP) rather than accepting all defaults — a real source of
  first-time deployment friction (see TROUBLESHOOTING.md).

## Alternatives considered
- **kubenet.** Rejected as the less modern option, with real feature
  gaps and a deprecation trajectory, despite being simpler to set up
  (no explicit CIDR planning required).