---
status: accepted
date: 2026-11-19
---

# Services needed to run or fix the cluster stay outside Kubernetes

## Context

The goal has been to move the services on Proxmox into Kubernetes. Two exceptions were made
one at a time: Pi-hole ([ADR 0012](0012-pihole-stays-in-an-lxc.md)) and Uptime Kuma
([ADR 0011](0011-alerting-with-alertmanager-and-telegram.md)). The next candidate was the
Omada controller (issue #102), which manages the router, the switch and the access point.
It raised the same question a third time, so this record turns the exceptions into a rule.

The cluster has one control plane node and is changed and upgraded often on purpose, to
practise for Kubernetes certifications. On 2026-11-17 a MetalLB problem made every site
unreachable while the cluster itself looked healthy: a network problem, found and fixed
with tools outside the cluster.

The Omada controller in particular:

- Is where network problems are looked at and fixed (VLANs, ports, device status). The
  router, switch and access point keep forwarding traffic without it, but changing
  settings, statistics and adopting devices need it.
- Is found by the devices through broadcasts on several UDP ports and reached on one fixed
  IP. In the cluster that needs `hostNetwork` pinned to a node, or a MetalLB IP with many
  ports.
- Runs MongoDB inside and needs about 1.5 GB of RAM, on nodes that are already the
  tightest resource.
- Keeps all its settings in its own database, changed in its UI. Flux would manage only the
  container, not the configuration.

## Options

- **Move everything into Kubernetes**, Omada included: one way to run things, managed by
  Flux. But DNS, monitoring and the network controller would be down exactly when the
  cluster is, which is when they are needed to fix it.
- **Decide service by service**: what happened so far. Each case repeats the same
  reasoning, and the stated goal stays wrong.
- **A rule** (chosen): services the cluster depends on, or that are needed to find and fix
  problems with it, run outside Kubernetes. Everything else moves in.

## Decision

Chosen: the rule, because the cluster is meant to be broken and rebuilt for practice, and
the services used to repair it cannot depend on it. Today this covers:

| Service | Why it stays out | Where it runs |
|---|---|---|
| Pi-hole | DNS for the house and the cluster (ADR 0012) | LXC on Proxmox |
| Uptime Kuma | Checks the services from outside the cluster (ADR 0011) | LXC on Proxmox |
| Omada controller | Manages the network the cluster runs on | TrueNAS app |
| Tailscale | Remote access to the LAN, also when the cluster is down | LXC on Proxmox |

Omada stays a TrueNAS app as it is today. Its data moves from `Catacombs/data` to
`UndeadParish/omada` (storage phase 6), so `Catacombs` only holds backups.

## Consequences

- Good: DNS, monitoring, the network controller and remote access keep working when the
  cluster is down or being rebuilt.
- Good: a new service is placed with one question: is it needed to run or fix the cluster?
- Bad: these services are not managed by Flux. Until Terraform and Ansible cover Proxmox
  (#104) they are set up by hand, documented in `docs/`, and their versions are tracked in
  [versions.md](../operations/versions.md).
- Bad: they depend on the single Proxmox host, like TrueNAS already does.
- Issue #102 (Omada controller in Kubernetes) is closed as not planned.

## More information

[ADR 0011](0011-alerting-with-alertmanager-and-telegram.md),
[ADR 0012](0012-pihole-stays-in-an-lxc.md), issue #102.
