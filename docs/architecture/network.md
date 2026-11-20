# Network

TP-Link Omada, managed from the Omada controller (a TrueNAS app).

| Device | Model | Role |
|---|---|---|
| Router | TP-Link ER7206 | Gateway and routing between the VLANs |
| Switch | TP-Link SG2210MP | 8 gigabit PoE+ ports and 2 SFP slots, VLAN trunks to the hosts |
| Access point | TP-Link EAP653 | Wi-Fi 6 |

## VLANs

The network is split into VLANs by purpose:

| VLAN | Name | Purpose |
|---|---|---|
| 10 | Core | Network management and core services |
| 20 | Servers | Proxmox, NAS and services outside Kubernetes |
| 30 | Kubernetes | Cluster nodes and MetalLB load balancer IPs |
| 42 | Trusted clients | Personal devices on Wi-Fi |
| 90 | Guests | Guest Wi-Fi, isolated |
| 107 | IoT | Smart home devices |
