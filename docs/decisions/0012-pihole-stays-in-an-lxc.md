---
status: accepted
date: 2026-11-18
---

# Pi-hole stays in an LXC on Proxmox, not in Kubernetes

## Context

The goal is to move the services on Proxmox into Kubernetes. Pi-hole (LXC 104,
`192.168.20.20`) is the DNS server for the whole home network: it answers internet
lookups for every client, and it holds the local records that point the Kubernetes
hostnames (`*.magelssen.io`) to the Envoy Gateway at `192.168.30.200`. Unlike the
other services, the cluster itself depends on it.

The cluster has one control plane node (lenovo1) and is upgraded and changed often on
purpose, to practise for Kubernetes certifications.

## Options

- **Pi-hole in Kubernetes**: managed by Flux like everything else. But DNS for the whole
  house would then depend on the cluster: when the cluster is down (an upgrade, an etcd
  problem, a bad merge), nobody has DNS, at exactly the time it is needed to fix the
  cluster (image pulls, Flux reaching GitHub, cert-manager reaching Route53). It also
  needs a MetalLB IP for port 53 over UDP and TCP, `externalTrafficPolicy: Local` to keep
  client IPs in the query log, and a persistent volume that pins the single pod to one
  node, so it gets little out of Kubernetes.
- **Pi-hole in Kubernetes, with a second Pi-hole outside it**: no single point of failure,
  but two instances to keep in sync, and the one outside the cluster is still needed.
- **Pi-hole stays in an LXC on Proxmox** (chosen).

## Decision

Chosen: Pi-hole stays in an LXC on Proxmox, because DNS is a dependency of the cluster
and should not run on it. The Proxmox host is already the infrastructure layer the
cluster depends on (TrueNAS runs there), so this adds no new point of failure. Pi-hole
is an exception to the goal of moving services into Kubernetes.

## Consequences

- Good: DNS for the home network keeps working when the cluster is down or being rebuilt.
- Good: Pi-hole keeps the real client IPs and needs no port 53 load balancer in the
  cluster.
- Bad: Pi-hole is not managed by Flux. Until Terraform and Ansible cover Proxmox, the LXC
  and its records are managed by hand, and its version is tracked in
  [versions.md](../versions.md).
- Bad: the Proxmox host is a single point of failure for DNS. A second Pi-hole (for
  example in the cluster, kept in sync) can be added later as secondary DNS if this
  becomes a problem.
- Open: the local records for the Kubernetes hostnames are added by hand. Whether to
  automate them (external-dns, a wildcard record, or as it is) is a separate decision.

## More information

[kubernetes/README.md](../../kubernetes/README.md) (how a hostname reaches the gateway),
[ADR 0002](0002-truenas-as-a-vm-on-proxmox.md).
