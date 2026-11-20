# Hardware

## Machines

| Machine | Hostname | Runs | Specs |
|---|---|---|---|
| Lenovo ThinkCentre M720q | `lenovo1` | Kubernetes control plane, also runs workloads | 6 cores, 8 GB RAM, ~100 GB disk |
| Lenovo ThinkCentre M720q | `lenovo2` | Kubernetes worker | 6 cores, 8 GB RAM, ~200 GB disk |
| Raspberry Pi 5 | `pi5` | Kubernetes worker (arm64) | 4 cores, 8 GB RAM, ~480 GB disk |
| Self-built PC (MSI B250M BAZOOKA) | `pve` | Proxmox VE: TrueNAS SCALE in a VM, and LXCs for the services outside Kubernetes | Intel Core i5-7400 (4 cores), 40 GB DDR4-2133 (2× 16 GB + 2× 4 GB), 1 GbE, GeForce GTX 1060 3GB |

Node settings for the Kubernetes nodes: [nodes](../cluster/nodes.md).

## Disks

All disks are in `pve`. TrueNAS gets the three hard drives passed through
([ADR 0002](../decisions/0002-truenas-as-a-vm-on-proxmox.md)).

| Disk | Size | Used for |
|---|---|---|
| Kingston SUV400 SATA SSD | 240 GB | Proxmox itself and the guest disks (`local-lvm`) |
| WD Black SN750 NVMe | 1 TB | Not used yet |
| 3× Seagate IronWolf (ST4000VN006) | 4 TB each | TrueNAS pool `Firelink`: RAIDZ1, ~7.2 TiB usable. Layout: [storage](storage.md) |
