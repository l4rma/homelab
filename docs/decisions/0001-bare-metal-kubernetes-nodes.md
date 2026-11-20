---
status: accepted
date: 2025
---

# Kubernetes on bare-metal nodes, not VMs

## Context

The cluster needed nodes. Proxmox was already there to run VMs, so the nodes could be VMs on
it, or separate physical machines. The lab is for learning Kubernetes the way it runs on real
hardware, and for the Kubernetes certifications.

## Options

- **VMs on Proxmox**: cheap to make and throw away, with snapshots before risky upgrades. But
  the NAS, the hypervisor and the whole cluster would share one machine, so one hardware
  failure or Proxmox upgrade takes everything down. The iGPU (for video transcoding) would
  need passthrough to one VM.
- **Kubernetes on the TrueNAS or Proxmox host itself**: mixes the cluster with the storage.
  Rejected for the same reason.
- **Separate physical machines** (chosen): two Lenovo ThinkCentre M720q and a Raspberry Pi 5.

## Decision

Chosen: separate physical machines, because the NAS, the hypervisor and the cluster can then
be rebuilt or restarted without touching each other, and the cluster deals with real nodes:
real disks, a real iGPU and two CPU architectures.

## Consequences

- Good: a cluster problem does not affect the NAS or the services on Proxmox, and the other
  way around.
- Good: the iGPU on the Lenovos is used directly through the Intel GPU device plugin.
- Good: mixed amd64 and arm64 (`pi5`), as many real clusters are now. Images must be
  multi-arch.
- Bad: no snapshots before an upgrade. A broken node is reinstalled by hand until Ansible can
  rebuild it.
- Bad: the nodes have 8 GB RAM each, and growing means buying hardware.
- Bad: a throwaway test cluster is not free. It can still be made as VMs on Proxmox when
  needed.

## More information

[docs/cluster/nodes.md](../cluster/nodes.md), [Hardware](../architecture/hardware.md).
