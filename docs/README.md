# homelab

My homelab, as code. A bare-metal Kubernetes cluster managed with GitOps, a Proxmox
host for everything that is not in Kubernetes yet, and a NAS for storage and backups.
Later also Terraform, Ansible, Crossplane and AWS.

The lab is where I learn platform engineering by doing it: I act as both the platform
team and the development team, follow the same practices I would at work, and write
about it on my blog at [magelssen.io/blog](https://magelssen.io/blog/k8s-part0/).

These docs are the Markdown files in [`docs/`](https://github.com/l4rma/homelab/tree/main/docs)
of the [repository](https://github.com/l4rma/homelab).

## The docs

| Section | What is in it |
|---|---|
| [Architecture](architecture/README.md) | How the homelab fits together: [hardware](architecture/hardware.md), [network](architecture/network.md), [storage](architecture/storage.md), and the [technology choices](architecture/technology.md) |
| [Kubernetes cluster](cluster/README.md) | The GitOps flow, the [nodes](cluster/nodes.md) and [secrets](cluster/secrets.md) |
| [Services](services/README.md) | Every service and where it runs, and the ones outside Kubernetes ([Uptime Kuma](services/uptime-kuma.md)) |
| [Operations](operations/README.md) | Running it: [backups](operations/backups.md), [dependency updates](operations/dependencies.md) and [versions](operations/versions.md) |
| [Development](development/README.md) | How changes are made: the [GitHub repository](development/github.md) and [Claude as an agent](development/claude-agent.md) |
| [Decisions](decisions/README.md) | Architecture decision records: why each larger choice was made, and what was rejected |

## Repository

| Path | Contents |
|---|---|
| [`kubernetes/`](../kubernetes/) | Flux entrypoint, cluster infrastructure and apps. See [kubernetes/README.md](../kubernetes/README.md). |
| [`terraform/`](../terraform/) | Proxmox and AWS as code. Not started. |
| [`ansible/`](../ansible/) | Node and NAS configuration. Not started. |
| [`docs/`](./) | These docs. |
| [`hugo/`](../hugo/) | The docs website: Hugo config and templates. See [hugo/README.md](../hugo/README.md). |
| [`scripts/`](../scripts/) | Helper scripts run locally, such as generating the read-only kubeconfig for Claude. |
| [`.github/`](../.github/) | Workflows, issue forms, the pull request template, labels, code owners, the Renovate configuration and the ruleset for `main`. See [GitHub repository](development/github.md). |
| `CLAUDE.md` files | Instructions for Claude Code, at the root and per directory. |
