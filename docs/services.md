# Services

Everything that runs in the homelab, and where. The details of each app are in the
linked directories and docs; this page is the overview.

Services needed to run or fix the cluster (DNS, monitoring, the network controller,
remote access) run outside Kubernetes on purpose
([ADR 0014](decisions/0014-infrastructure-services-stay-outside-kubernetes.md)).
Everything else runs in the cluster. All addresses are under `magelssen.io` and go through
the Envoy Gateway at `192.168.30.200`, also for services outside the cluster.

`scripts/check-services.py` (a pre-commit hook) fails when a directory in
`kubernetes/apps/` is missing from this page, or this page names one that does not exist.
The rows for things outside Kubernetes are kept up to date by hand.

## In Kubernetes

| Service | What it is for | Address | Data | In Git |
|---|---|---|---|---|
| Jellyfin | Watching movies and series, with Quick Sync transcoding | `jellyfin.` | Config on `local-path`, media in `DukesArchives` | `kubernetes/apps/media` |
| Radarr, Sonarr | Finding and importing movies and series | `radarr.`, `sonarr.` | Config on `local-path`, media in `DukesArchives` | `kubernetes/apps/media` |
| Prowlarr | Indexers for Radarr and Sonarr | `prowlarr.` | Config on `local-path` | `kubernetes/apps/media` |
| qBittorrent | Downloads, through NordVPN (gluetun sidecar) | `qbittorrent.` | Config on `local-path`, files in `DukesArchives/downloads` | `kubernetes/apps/media` |
| Audiobookshelf | Audiobooks | `audiobooks.` | Config on `local-path`, books in `DukesArchives/audiobooks` | `kubernetes/apps/media` |
| Immich | Photos and videos from the phones | `immich.` | `AnorLondo/immich`, `BlightTown/immich`, Postgres (CloudNativePG) on `local-path` | `kubernetes/apps/immich` |
| Home Assistant | Smart home | `ha.` | `BlightTown/home-assistant` | `kubernetes/apps/home-assistant` |
| Homarr | Start page with links to everything | `dashboard.` | SQLite on `local-path` | `kubernetes/apps/homarr` |
| restic rest-server | Backups of the laptops | `restic.` | `Catacombs/backups/restic` | `kubernetes/apps/restic` |
| Grafana, Prometheus, Alertmanager | Metrics, dashboards, and alerts to Telegram and Gmail | `grafana.` | `local-path` | `kubernetes/infrastructure/kube-prometheus-stack` |
| podinfo | Small test app for the Gateway and Flux | `podinfo.` | None | `kubernetes/apps/podinfo` |

## Outside Kubernetes

Set up by hand until Terraform and Ansible cover Proxmox (#104). The cluster only has a
route to them: an Envoy Gateway `Backend` and an HTTPRoute.

| Service | What it is for | Runs on | Address | Data | In Git |
|---|---|---|---|---|---|
| Pi-hole | DNS for the house, and the local records for `*.magelssen.io` ([ADR 0012](decisions/0012-pihole-stays-in-an-lxc.md)) | LXC 104 | `pihole.` | LXC disk | Route only: `kubernetes/apps/pihole` |
| Uptime Kuma | Checks the services from outside the cluster ([docs/uptime-kuma.md](uptime-kuma.md)) | LXC 101 | `uptime-kuma.`, or `192.168.20.10:3001` when the cluster is down | LXC disk | Route only: `kubernetes/apps/uptime-kuma` |
| Tailscale | Remote access to the LAN from outside | LXC 103 | None | LXC disk | Nothing |
| Omada controller | Manages the router, the switch and the access point | TrueNAS app | `omada.` | `Catacombs/data` (moving to `UndeadParish/omada`) | Route only: `kubernetes/apps/omada` |
| TrueNAS SCALE | NAS: NFS and SMB shares, snapshots, the pool `Firelink` ([docs/storage.md](storage.md)) | VM 100 | `truenas.` | Pool `Firelink` | Route only: `kubernetes/apps/truenas` |
| Proxmox VE | Hypervisor for TrueNAS and the LXCs | `pve` (bare metal) | `proxmox.` | `local`, `local-lvm` | Route only: `kubernetes/apps/proxmox` |

## Proxmox guests

Every VM and LXC on `pve`, so nothing there is unexplained.

| ID | Name | Kind | Purpose |
|---|---|---|---|
| 100 | TrueNAS | VM | NAS |
| 101 | uptime-kuma | LXC | Uptime Kuma |
| 103 | tailscale | LXC | Tailscale |
| 104 | PiHole | LXC | Pi-hole |
| 9000 | ubuntu-2404-template | VM template | Ubuntu 24.04 for quickly creating VMs, for example test clusters |

## Platform

The cluster add-ons that the services above use (Flux, Envoy Gateway, MetalLB,
cert-manager, External Secrets, CloudNativePG, local-path, the Intel GPU plugin and others)
are listed in [kubernetes/README.md](../kubernetes/README.md). Why each was chosen is in the
[README's technology table](../README.md#technology-choices) and the
[decision records](decisions/).
