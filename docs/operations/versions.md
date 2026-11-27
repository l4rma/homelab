# Versions

What Renovate cannot see: the hosts, Kubernetes itself, and the services outside
Kubernetes. Everything pinned in Git (Helm charts, images, Flux, actions, pre-commit hooks)
is watched by Renovate, and its Dependency Dashboard issue lists what is behind. See
[dependencies.md](dependencies.md).

**Last check: 2026-10-31.** Next check: first weekend of each month.

## Renovate

Renovate updates everything that is pinned in Git. It opens pull requests on Monday mornings
for versions that have been out for 14 days, and never merges by itself. The full behaviour
is in [dependencies.md](dependencies.md).

- **Logs and settings:** [developer.mend.io](https://developer.mend.io/), under
  `l4rma/homelab`.
- **What it covers:** Helm charts and images under `kubernetes/`, Flux itself, GitHub
  Actions, pre-commit hooks, Hugo and the docs theme.
- **What it needs to take over a version:** the exact version written in a file it reads,
  in one of the forms below. A floating tag such as `latest` is never updated. When adding
  an app, check that its versions show up in the Dependency Dashboard.

  ```yaml
  # Kubernetes manifest: the image tag
  image: ghcr.io/immich-app/immich-server:v3.3.5

  # HelmRelease: the chart version, under chart.spec
  chart: cert-manager
  version: v1.19.2

  # CloudNativePG Cluster: the Postgres image
  imageName: ghcr.io/tensorchord/cloudnative-vectorchord:18.6-1.1.1

  # A tag in HelmRelease values: a comment on the line above tells Renovate what it is
  # renovate: datasource=docker depName=docker.io/library/nextcloud
  tag: 35.0.2-apache

  # GitHub Actions: the commit SHA, with the version as a comment after it
  uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

  # pre-commit hooks: the same, with "frozen:" in the comment
  rev: 3e8a8703264a2f4a69428a0aa4dcb512790b2c8c # frozen: v6.0.0
  ```

  For actions and hooks, the SHA is what is actually used: a tag can be moved to other
  code, a commit cannot. The comment is for people and for Renovate, which updates the SHA
  and the comment together. Never change one without the other.
- **What is still manual:**
  - read the release notes in each pull request, and merge it
  - back up before merging `manual-step` pull requests (stateful apps)
  - tick majors in the Dependency Dashboard to get a pull request for them
  - watch Flux roll the update out
  - update everything else on this page by hand: the hosts, Kubernetes itself and the
    services outside Kubernetes

## Monthly check

1. Compare the running versions below with the sources, and update the tables and the
   **Last check** date, also when nothing changed.
2. Read the release notes before updating anything that is behind, and move newly found
   problems to [Needs attention](#needs-attention).
3. Look through the Dependency Dashboard for updates that wait for approval (majors).
4. Update one thing per PR, and add a line to the [update log](#update-log) in the same PR.

Claude can do steps 1 to 3 with its read-only access, except for the versions marked
"check by hand" below.

Rules for updating, also for Renovate's pull requests:

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
| Router ER7206 (v2.0) firmware | 2.2.3 | Check by hand | Unknown | Omada controller, Devices |
| Switch SG2210MP (v4.20) firmware | 4.20.20 | Check by hand | Unknown | Omada controller, Devices |
| Access point EAP653 (v1.0) firmware | 1.3.7 | Check by hand | Unknown | Omada controller, Devices |

## Outside Kubernetes

Claude cannot read versions inside the LXCs, so these need a check by hand.

| Component | Running | Newest found | Last changed | Where it runs |
|---|---|---|---|---|
| Omada controller | `5.15_1.2.12` | Chart 1.4.19 | Unknown | TrueNAS app |
| Pi-hole | Check by hand | 6.5 | Unknown | LXC 104 |
| Tailscale | Check by hand | Check by hand | Unknown | LXC 103 |
| Uptime Kuma | 2.5.8 | 2.5.12 | 2026-11-19 | LXC 101, upgrade steps in [uptime-kuma.md](../services/uptime-kuma.md) |

## Kubernetes core

Not in Git. kubeadm, the node packages and upstream manifests installed by hand decide these.

| Component | Running | Newest found | Last changed |
|---|---|---|---|
| Kubernetes (kubeadm, kubelet) | v1.36.1 | v1.36.6, v1.37.2 | Unknown |
| etcd (follows kubeadm) | 3.6.8-0 | Comes with kubeadm | Unknown |
| CoreDNS (follows kubeadm) | v1.14.2 | Comes with kubeadm | Unknown |
| containerd | 2.2.1 | 2.4.2 | Unknown |
| Flannel | v0.27.4 | v0.28.10 | Unknown |

## Update log

Updates of the things on this page, newest first. Updates made by Renovate are in Git: the
merged pull requests with the `dependencies` label. Updates made by hand outside Git are only
here when they were written down somewhere.

| Date | Component | From | To | Source |
|---|---|---|---|---|
| 2026-10-28 | Home Assistant | 2025.12.5 | 2026.10.4 | Git |
| 2026-10-28 | Uptime Kuma | 2.1.3 | 2.5.8 | Git |
| 2026-10-23 | TrueNAS SCALE | Older release, via 25.04 | 25.10.7 | Notes |
| Unknown | Kubernetes | v1.33 | v1.36 (by hand) | README |
