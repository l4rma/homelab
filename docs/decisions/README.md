# Decisions

Architecture decision records (ADRs): one short file per decision, with the problem, the
options that were considered, what was chosen and what it costs. The README's technology
table says *what* is used; these files say *why*, and what was rejected. The format is
[MADR](https://adr.github.io/madr/), shortened.

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-bare-metal-kubernetes-nodes.md) | Kubernetes on bare-metal nodes, not VMs | Accepted |
| [0002](0002-truenas-as-a-vm-on-proxmox.md) | TrueNAS as a VM on Proxmox | Accepted |
| [0003](0003-flux-for-gitops.md) | Flux for GitOps, not Argo CD | Accepted |
| [0004](0004-ingress-nginx.md) | ingress-nginx for traffic into the cluster | Superseded by 0006 |
| [0005](0005-external-secrets-with-aws-ssm.md) | Secrets in AWS SSM through External Secrets | Accepted |
| [0006](0006-envoy-gateway.md) | Envoy Gateway (Gateway API) instead of ingress-nginx | Accepted |
| [0007](0007-restic-for-laptop-backups.md) | restic for laptop backups, not Kopia | Accepted |
| [0008](0008-renovate-for-dependency-updates.md) | Renovate for dependency updates | Accepted |
| [0009](0009-github-app-for-flux.md) | A GitHub App for Flux's commit statuses | Accepted |
| [0010](0010-no-bot-account-for-claude.md) | No bot account or auto-approval for Claude's pull requests | Accepted |
| [0011](0011-alerting-with-alertmanager-and-telegram.md) | Alerts from Alertmanager to Telegram, and Uptime Kuma moved to Proxmox | Accepted |
| [0012](0012-pihole-stays-in-an-lxc.md) | Pi-hole stays in an LXC on Proxmox, not in Kubernetes | Accepted |
| [0013](0013-uptime-kuma-without-docker.md) | Uptime Kuma installed with Node.js in its LXC, not in Docker | Accepted |
| [0014](0014-infrastructure-services-stay-outside-kubernetes.md) | Services needed to run or fix the cluster stay outside Kubernetes | Accepted |
| [0015](0015-hugo-for-the-docs-website.md) | A Hugo website built from docs/, published to GitHub Pages | Accepted |
| [0016](0016-nextcloud-in-kubernetes.md) | Nextcloud in Kubernetes with the Helm chart, user files on NFS | Accepted |

0001 to 0006 were written down after the fact, in November 2026.

## When to write one

- A new technology is added, or one replaces another.
- A choice between real alternatives that would be expensive to undo.

Not for version bumps, config changes or small fixes. The ADR goes in the same pull request
as the change.

## How

1. Copy [template.md](template.md) to `NNNN-short-title.md` with the next number.
2. Keep it short. The options and their reasons matter most.
3. Add it to the table above, and link it from the [technology choices](../architecture/technology.md) if it is there.

An accepted ADR is not rewritten. When a decision changes, write a new ADR and set the old
one's status to `superseded by [NNNN](NNNN-...md)`.
