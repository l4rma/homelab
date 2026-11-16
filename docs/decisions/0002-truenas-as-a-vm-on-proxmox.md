---
status: accepted
date: 2025-03-16 (written down 2026-11-16)
---

# TrueNAS as a VM on Proxmox

## Context

One machine had to hold the disks (NAS) and also run VMs and containers for the
services that are not in Kubernetes (Docker images, Pi-hole, Plex, Tailscale,
the Omada controller). Either the NAS runs the VMs, or a hypervisor runs the
NAS.

## Options

- **TrueNAS on the bare machine, running VMs and apps itself**: TrueNAS sees the disks
  directly. But VMs and apps are not what TrueNAS is built for, and they have
  changed a lot between releases. Tried out TrueNAS on the bare machine, but had
  problems with a lot of the apps (vms).
- **Proxmox only, with ZFS and NFS/SMB set up by hand**: one layer less, but no NAS interface
  for shares, users, snapshot tasks, replication and disk health. All of it by hand on the
  hypervisor.
- **Proxmox on the bare machine, TrueNAS in a VM** (chosen).

## Decision

Chosen: Proxmox with TrueNAS in a VM, because each does what it is built for. Proxmox is a
full hypervisor with LXCs, backups, an API and a Terraform provider, and TrueNAS is a full NAS.
The disks are passed through to the TrueNAS VM, so the pool (`Firelink`) belongs to TrueNAS
and could move to another machine.

## Consequences

- Good: the services on Proxmox and the NAS are managed with the right tool each, and Proxmox
  can be managed as code later.
- Bad: the storage depends on a VM. When Proxmox restarts, guests and SMB mounts that use the
  NAS can start before TrueNAS is up.
- Bad: the disks are passed through one by one (`/dev/disk/by-id/...` as SCSI disks), not as
  the whole disk controller. TrueNAS recommends passing through the controller, so TrueNAS
  talks to the disks directly. With single disks, SMART data may not reach TrueNAS, and disk
  health has to be checked on the Proxmox host.
- Bad: TrueNAS takes 20 GB of the host's RAM for itself (ZFS uses RAM as cache).

## More information

[docs/storage.md](../storage.md), [README: Hardware](../../README.md#hardware).
