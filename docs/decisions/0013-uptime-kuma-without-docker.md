---
status: accepted
date: 2026-11-19
---

# Uptime Kuma installed with Node.js in its LXC, not in Docker

## Context

[ADR 0011](0011-alerting-with-alertmanager-and-telegram.md) moved Uptime Kuma out of the
cluster into an LXC on Proxmox. That left how to run it inside the LXC. Uptime Kuma ships a
Docker image (which the cluster used) and supports a plain Node.js install from source.
The old docker LXC (102), which ran Docker with Portainer, was just retired.

## Options

- **Docker in the LXC**: the same image as in the cluster. But Proxmox recommends running
  application containers in a VM, not in an LXC; Docker in an unprivileged LXC needs
  `nesting` and `keyctl` and breaks now and then on Proxmox or kernel updates. It adds a
  daemon and a layer for one app.
- **A small VM with Docker**: what Proxmox recommends for Docker, but a full VM (kernel,
  more RAM and disk) for one small Node.js app.
- **Node.js in the LXC** (chosen): Uptime Kuma's documented install without Docker, git tag
  pinned, run by systemd.

## Decision

Chosen: Node.js in the LXC, because it is the simplest setup that Proxmox supports well,
and it fits being managed by Ansible later. Debian 13 ships a new enough Node.js (20.19,
Uptime Kuma 2.x needs 20.4 or newer), so no extra apt repository is needed.

## Consequences

- Good: no Docker daemon, nothing beyond `nodejs`, `npm` and `git` from Debian.
- Good: the code is owned by root and the service runs as its own user with only its data
  folder writable.
- Bad: upgrades are a few commands (`git checkout`, `npm ci`, `download-dist`) instead of a
  new image tag, and Renovate cannot see the version. Written down in
  [docs/uptime-kuma.md](../uptime-kuma.md), version tracked in [versions.md](../versions.md).
- Bad: Node.js comes from Debian, so a future Uptime Kuma that needs a newer Node.js needs
  a newer Debian or another source.
- Bad: Ping monitors do not work as the unprivileged service user; TCP Port monitors are
  used instead.

## More information

- Issue #129, PR #156 (the move)
- Uptime Kuma: <https://github.com/louislam/uptime-kuma>
- Proxmox VE, Linux Container: <https://pve.proxmox.com/pve-docs/chapter-pct.html>
