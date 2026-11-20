# Architecture

Four kinds of machines, each with its own job, so one can be rebuilt without touching the
others ([ADR 0001](../decisions/0001-bare-metal-kubernetes-nodes.md)):

- **The Kubernetes cluster**: three bare-metal nodes, managed by Flux from Git. Most
  services run here ([Kubernetes cluster](../cluster/README.md)).
- **Proxmox VE**: a hypervisor on its own machine. It runs TrueNAS SCALE in a VM
  ([ADR 0002](../decisions/0002-truenas-as-a-vm-on-proxmox.md)), and LXCs for the services
  that stay outside the cluster.
- **TrueNAS SCALE**: all storage, in one ZFS pool. The cluster uses it over NFS
  ([storage](storage.md)).
- **The network**: TP-Link Omada, split into VLANs by purpose ([network](network.md)).

All services are reached at `<name>.magelssen.io` through Envoy Gateway (Gateway API)
in the cluster, with a Let's Encrypt wildcard certificate. Services that still run on
Proxmox are exposed through the cluster with an Envoy Gateway `Backend`, so they get the
same entry point and TLS as everything else. Services needed to run or fix the cluster
(DNS, monitoring, the network controller, remote access) stay outside it on purpose
([ADR 0014](../decisions/0014-infrastructure-services-stay-outside-kubernetes.md)). Which
service runs where: [services](../services/README.md).

## In this section

- [Hardware](hardware.md): the machines and disks.
- [Network](network.md): the Omada devices and the VLANs.
- [Storage](storage.md): the ZFS pool, its datasets, and how the cluster uses them.
- [Technology choices](technology.md): what is used, and why.
