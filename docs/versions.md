# Versions

What runs in the homelab, what is newest upstream, and when each version last changed.
Everything is pinned and nothing updates by itself, so this list is how updates get noticed.

**Last check: 2026-10-31.** Next check: first weekend of each month.

## Monthly check

1. Compare the running versions with the sources below, and update the tables and the
   **Last check** date, also when nothing changed.
2. Read the release notes before updating anything that is behind, and move newly found
   problems to [Needs attention](#needs-attention).
3. Update one thing per PR, and add a line to the [update log](#update-log) in the same PR.

Claude can do steps 1 and 2 with its read-only access, except for the versions marked
"check by hand" below.

Rules for updating:

- Security fixes and end-of-life versions come first.
- Back up or snapshot anything stateful first. Jellyfin has no downgrade path.
- Kubernetes moves one minor version at a time, control plane first (kubeadm's skew rules).
  Check that the add-ons support the new version before starting.
- Keep the matching Immich server and machine learning versions together.
- Images must stay multi-arch, because `pi5` is arm64.

## Needs attention

| What | Why | Next step |
|---|---|---|
| Proxmox VE 8.4 | Past end of life (Proxmox EOL 2026-08, Debian 12 EOL 2026-07) | Plan the upgrade to 9, using Proxmox's `pve8to9` checklist. TrueNAS runs on this host, so plan for the downtime |
| Kubernetes 1.36.1 | 5 patch releases behind | Update to 1.36.6, and then consider 1.37 |
| Jellyfin 10.11.6 | Newest is 12.4, and there is no downgrade path | Pinned on purpose for the move. Upgrade in its own PR after a config backup |
| Omada controller | TrueNAS reports an app update (chart 1.2.12 to 1.4.19) | Read the notes, and back up the controller first |

## Host and platform

| Component | Running | Newest found | Last changed | Where to check |
|---|---|---|---|---|
| Proxmox VE | 8.4.18 | 9 | Unknown | [Proxmox FAQ](https://pve.proxmox.com/wiki/FAQ), node version in the Proxmox API |
| TrueNAS SCALE | 25.10.7 (Goldeye) | 25.10.7 | 2026-10-23 | `update.status` in the TrueNAS API |
| Ubuntu on `lenovo2`, `pi5` | 24.04.4 | Check by hand | Unknown | `kubectl get nodes -o wide`, `apt` on the node |
| Ubuntu on `lenovo1` | 24.04.3 | Check by hand | Unknown | `kubectl get nodes -o wide`, `apt` on the node |
| Kernel on `lenovo1`, `lenovo2` | 6.8.0-138-generic | Check by hand | Unknown | `kubectl get nodes -o wide` |
| Kernel on `pi5` | 6.8.0-1061-raspi | Check by hand | Unknown | `kubectl get nodes -o wide` |

## Outside Kubernetes

Claude cannot read versions inside the LXCs, so these need a check by hand.

| Component | Running | Newest found | Last changed | Where it runs |
|---|---|---|---|---|
| Omada controller | `5.15_1.2.12` | Chart 1.4.19 | Unknown | TrueNAS app |
| Pi-hole | Check by hand | 6.5 | Unknown | LXC 104 |
| Plex | Check by hand | Check by hand | Unknown | LXC 101 |
| Tailscale | Check by hand | Check by hand | Unknown | LXC 103 |
| GitHub runner | Check by hand | Check by hand | Unknown | LXC 105 (stopped) |

## Kubernetes core

Not in Git. kubeadm, the node packages and upstream manifests installed by hand decide these.

| Component | Running | Newest found | Last changed |
|---|---|---|---|
| Kubernetes (kubeadm, kubelet) | v1.36.1 | v1.36.6, v1.37.2 | Unknown |
| etcd (follows kubeadm) | 3.6.8-0 | Comes with kubeadm | Unknown |
| CoreDNS (follows kubeadm) | v1.14.2 | Comes with kubeadm | Unknown |
| containerd | 2.2.1 | 2.4.2 | Unknown |
| Flannel | v0.27.4 | v0.28.10 | Unknown |

## Cluster infrastructure

Chart versions are in each `helmrelease.yaml`, under `kubernetes/infrastructure/`. "Last
changed" is when Git first shows this version, so it can be when the component was added.

| Component | Running | Newest found | Last changed | Where to check |
|---|---|---|---|---|
| Flux | v2.7.5 | v2.10.0 | 2026-01-18 | [fluxcd/flux2](https://github.com/fluxcd/flux2/releases) |
| cert-manager (chart) | v1.19.2 | v1.21.3 | 2026-01-21 | [cert-manager](https://github.com/cert-manager/cert-manager/releases) |
| external-secrets (chart) | 1.3.1 | 2.14.0 | 2026-01-25 | [external-secrets](https://github.com/external-secrets/external-secrets/releases) |
| MetalLB (chart) | 0.15.3 | 0.16.1 | 2026-01-28 | [metallb](https://github.com/metallb/metallb/releases) |
| Envoy Gateway (chart) | v1.9.3 | v1.9.3 | 2026-10-29 | [envoyproxy/gateway](https://github.com/envoyproxy/gateway/releases) |
| CloudNativePG (chart / operator) | 0.29.1 / 1.30.1 | 0.29.1 / 1.30.1 | 2026-10-29 | [cloudnative-pg/charts](https://github.com/cloudnative-pg/charts/releases) |
| kube-prometheus-stack (chart) | 92.14.1 | 92.17.0 | 2026-10-29 | [helm-charts](https://github.com/prometheus-community/helm-charts/releases) |
| metrics-server (chart / app) | 3.14.0 / 0.9.0 | 3.14.0 / 0.9.1 | 2026-10-29 | [metrics-server](https://github.com/kubernetes-sigs/metrics-server/releases) |
| local-path-provisioner | v0.0.37 | v0.0.37 | 2026-10-29 | [local-path-provisioner](https://github.com/rancher/local-path-provisioner/releases) |
| Intel GPU plugin | 0.37.1 | 0.37.1 | 2026-10-29 | [intel-device-plugins](https://github.com/intel/intel-device-plugins-for-kubernetes/releases) |

kube-prometheus-stack decides the versions of Prometheus, Grafana, Alertmanager and the
exporters, so they are not listed one by one.

## Apps

Image tags are in the Deployments under `kubernetes/apps/`.

| App | Running | Newest found | Last changed | Where to check |
|---|---|---|---|---|
| Jellyfin | 10.11.6 (`10.11.6ubu2404-ls22`) | 12.4 | 2026-10-30 (moved, same version) | [jellyfin](https://github.com/jellyfin/jellyfin/releases) |
| qBittorrent | 5.3.0 (`5.3.0_v2.1.2-ls485`) | 5.3.0 | 2026-10-30 | [qBittorrent](https://github.com/qbittorrent/qBittorrent/releases) |
| gluetun | Digest `2733bb22`, built 2026-09-26 | v3.41.3 | 2026-10-30 | [gluetun](https://github.com/qdm12/gluetun/releases) |
| Radarr | 6.4.4.10685 (`-ls324`) | 6.4.4.10685 | 2026-10-30 | [Radarr](https://github.com/Radarr/Radarr/releases) |
| Sonarr | 4.0.20.3014 (`-ls1`) | 4.0.20.3014 | 2026-10-30 | [Sonarr](https://github.com/Sonarr/Sonarr/releases) |
| Prowlarr | 2.7.0.5723 (`-ls166`) | 2.7.0.5723 | 2026-10-30 | [Prowlarr](https://github.com/Prowlarr/Prowlarr/releases) |
| restic rest-server | 0.14.0 | 0.14.0 | 2026-11-04 | [rest-server](https://github.com/restic/rest-server/releases) |
| Audiobookshelf | 2.37.2 | 2.37.2 | 2026-11-02 | [audiobookshelf](https://github.com/advplyr/audiobookshelf/releases) |
| Homarr | v2.10.1 | v2.10.1 | 2026-10-31 | [homarr](https://github.com/homarr-labs/homarr/releases) |
| Home Assistant | 2026.10.4 | 2026.10.4 | 2026-10-28 | [home-assistant](https://github.com/home-assistant/core/releases) |
| Uptime Kuma | 2.5.8 | 2.5.9 | 2026-10-28 | [uptime-kuma](https://github.com/louislam/uptime-kuma/releases) |
| Immich (server, ML) | v3.3.5 | v3.3.5 | 2026-10-29 | [immich](https://github.com/immich-app/immich/releases) |
| Immich Postgres (VectorChord image) | 18.6-1.1.1 | VectorChord 1.1.1 | 2026-10-29 | [VectorChord](https://github.com/tensorchord/VectorChord/releases) |
| Valkey (Immich) | 9.1.3 | 9.1.3 | 2026-10-29 | [valkey](https://github.com/valkey-io/valkey/releases) |
| podinfo | 6.4.0 | 6.17.0 | 2026-01-18 | [podinfo](https://github.com/stefanprodan/podinfo/releases) |

## Update log

Real updates only, newest first. Adding a component or moving it without changing its
version does not count. Git history has the details, and starts on 2026-01-18. Updates made
by hand outside Git are only here when they were written down somewhere.

| Date | Component | From | To | Source |
|---|---|---|---|---|
| 2026-10-28 | Home Assistant | 2025.12.5 | 2026.10.4 | Git |
| 2026-10-28 | Uptime Kuma | 2.1.3 | 2.5.8 | Git |
| 2026-10-23 | TrueNAS SCALE | Older release, via 25.04 | 25.10.7 | Notes |
| Unknown | Kubernetes | v1.33 | v1.36 (by hand) | README |
