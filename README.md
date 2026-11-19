# homelab

[![lint](https://github.com/l4rma/homelab/actions/workflows/lint.yml/badge.svg)](https://github.com/l4rma/homelab/actions/workflows/lint.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/l4rma/homelab/badge)](https://scorecard.dev/viewer/?uri=github.com/l4rma/homelab)

My homelab, as code. A bare-metal Kubernetes cluster managed with GitOps, a Proxmox
host for everything that is not in Kubernetes yet, and a NAS for storage and backups.
Later also Terraform, Ansible, Crossplane and AWS.

The lab is where I learn platform engineering by doing it: I act as both the platform
team and the development team, follow the same practices I would at work, and write
about it on my blog at [magelssen.io/blog](https://magelssen.io/blog/k8s-part0/).

## Architecture

All services are reached at `<name>.magelssen.io` through Envoy Gateway (Gateway API)
in the cluster, with a Let's Encrypt wildcard certificate. Services that still run on
Proxmox are exposed through the cluster with an Envoy Gateway `Backend`, so they get the
same entry point and TLS as everything else until they are moved into Kubernetes.

## Hardware

| Device | Role | Specs |
|---|---|---|
| Lenovo ThinkCentre M720q | Kubernetes control plane, also runs workloads (`lenovo1`) | 6 cores, 8 GB RAM, ~100 GB disk. Node settings: [docs/kubernetes-nodes.md](docs/kubernetes-nodes.md) |
| Lenovo ThinkCentre M720q | Kubernetes worker (`lenovo2`) | 6 cores, 8 GB RAM, ~200 GB disk |
| Raspberry Pi 5 | Kubernetes worker (`pi5`, arm64) | 4 cores, 8 GB RAM, ~480 GB disk |
| Proxmox VE host (`pve`) | Hypervisor for TrueNAS and other services | MSI B250M BAZOOKA (MS-7A70), Intel Core i5-7400 (4 cores), 40 GB DDR4-2133 (2× 16 GB + 2× 4 GB), 1 GbE (Realtek RTL8111), GeForce GTX 1060 3GB. Disks: 240 GB SATA SSD (Proxmox), 1 TB NVMe (unused), 3× 4 TB Seagate IronWolf (passed to TrueNAS) |
| TrueNAS SCALE (VM) | NAS: NFS/SMB, storage, backups | Pool `Firelink`, 3 disks in RAIDZ1, ~7.2 TiB usable. Layout: [docs/storage.md](docs/storage.md) |
| Network | TP-Link Omada | TBD <!-- TODO: router, switches, access points --> |

### Network

The network is split into VLANs by purpose:

| VLAN | Name | Purpose |
|---|---|---|
| 10 | Core | Network management and core services |
| 20 | Servers | Proxmox, NAS and services outside Kubernetes |
| 30 | Kubernetes | Cluster nodes and MetalLB load balancer IPs |
| 42 | Trusted clients | Personal devices on Wi-Fi |
| 90 | Guests | Guest Wi-Fi, isolated |
| 107 | IoT | Smart home devices |

## Technology choices

The larger choices, with the options that were rejected, are written down as decision
records in [docs/decisions/](docs/decisions/).

| Technology | Why |
|---|---|
| Proxmox VE | Runs the NAS and the services that are not in Kubernetes yet, separate from the cluster. A full hypervisor with LXCs, backups and an API, with TrueNAS in a VM ([ADR 0002](docs/decisions/0002-truenas-as-a-vm-on-proxmox.md)). |
| Bare-metal nodes | Keeps the NAS, the hypervisor and the cluster on separate machines, so one can be rebuilt without touching the others ([ADR 0001](docs/decisions/0001-bare-metal-kubernetes-nodes.md)). |
| kubeadm | Upstream Kubernetes with no abstractions on top, which is good practice for the Kubernetes certifications. The cluster started on v1.33 and has been upgraded to v1.36 by hand. |
| Flannel | Simple CNI that just works. The trade-off is no NetworkPolicy support, which I may revisit. |
| Flux | Pull-based GitOps: the cluster pulls from Git, so nothing outside needs access to the cluster. No GUI, which forces me to understand Kubernetes properly. It is also what I use at work ([ADR 0003](docs/decisions/0003-flux-for-gitops.md)). |
| MetalLB + Envoy Gateway | LoadBalancer IPs on bare metal, and the Gateway API (the successor to Ingress) for routing. Replaced ingress-nginx, which was retired upstream ([ADR 0004](docs/decisions/0004-ingress-nginx.md), [ADR 0006](docs/decisions/0006-envoy-gateway.md)). |
| cert-manager + Route53 | Real Let's Encrypt certificates through DNS-01, which works without exposing the cluster to the internet. |
| External Secrets + AWS SSM | The repo is public, so no secret is stored in Git, not even encrypted. Secrets live in SSM Parameter Store (free tier) and are copied into the cluster. See [docs/secrets.md](docs/secrets.md) and [ADR 0005](docs/decisions/0005-external-secrets-with-aws-ssm.md). |
| kube-prometheus-stack | Prometheus, Grafana and Alertmanager in one chart, with dashboards for the cluster out of the box. Also the data for sizing resource requests. |
| local-path + NFS | Databases on the node's own disk, files on the NAS over NFS. Databases on NFS are slow and corrupt easily. The reasoning: [docs/storage.md](docs/storage.md). |
| CloudNativePG | Postgres as a Kubernetes operator: one small cluster per app, with failover and backups to S3 later. |
| gluetun | VPN as a sidecar for qBittorrent only. Its firewall is the kill switch, and the rest of the media stack stays outside the VPN. |
| Terraform (planned) | Proxmox VMs and LXCs, and later AWS, as code. |
| Ansible (planned) | Configure nodes and rebuild the cluster from freshly installed machines. |
| Crossplane + AWS (planned) | Provision cloud resources from Kubernetes. |

## Repository structure

| Path | Contents |
|---|---|
| [`kubernetes/`](kubernetes/) | Flux entrypoint, cluster infrastructure and apps. See [kubernetes/README.md](kubernetes/README.md). |
| [`terraform/`](terraform/) | Proxmox and AWS as code. Not started. |
| [`ansible/`](ansible/) | Node and NAS configuration. Not started. |
| [`scripts/`](scripts/) | Helper scripts run locally, such as generating the read-only kubeconfig for Claude. |
| [`docs/`](docs/) | Documentation, including [decision records](docs/decisions/), [dependency updates with Renovate](docs/dependencies.md) and [versions outside Git](docs/versions.md). |
| [`.github/`](.github/) | Workflows, issue forms, the pull request template, labels, code owners, the Renovate configuration and the ruleset for `main`. See [docs/github.md](docs/github.md). |
| `CLAUDE.md` files | Instructions for Claude Code, at the root and per directory. |

## GitOps flow

1. A change is made on a branch and opened as a pull request.
2. After review, the pull request is merged to `main`.
3. Flux's `GitRepository` polls `main` every minute and fetches the new revision.
4. The `flux-system` Kustomization applies `kubernetes/clusters/homelab`, which
   defines the other Kustomizations.
5. `infrastructure` applies `kubernetes/infrastructure` (gateway, certificates,
   load balancing, secrets operator). `apps` applies `kubernetes/apps` once
   `infrastructure` is applied and healthy. Both wait until what they applied is running
   (`wait: true`), and report a failure after 10 minutes.
6. Flux uses server-side apply and prunes resources that were removed from Git.
   Rolling back is a `git revert`.

The goal is that nothing is applied to the cluster by hand. Every workload is in Git.
What is still done by hand: the two bootstrap AWS keys (cert-manager's Route53 key and
the key external-secrets uses to read SSM) and the kubelet settings on the nodes
([docs/kubernetes-nodes.md](docs/kubernetes-nodes.md)), until Terraform and Ansible
take over.

## Claude as an agent

Claude Code works in this repository as an agent. It can inspect the cluster and
propose changes, but it cannot change anything by itself:

- Read-only ServiceAccount: `claude-readonly` is bound to the built-in `view`
  ClusterRole plus a small extra ClusterRole for nodes, persistent volumes, CRDs,
  Flux, Prometheus Operator and Gateway API resources, and may run PromQL queries
  through the Prometheus Service. It has no access to secrets. The RBAC is managed by Flux like
  everything else, in [`kubernetes/infrastructure/claude-readonly`](kubernetes/infrastructure/claude-readonly/).
- Separate kubeconfig: a [script](scripts/create-claude-kubeconfig.sh) builds a
  kubeconfig from the ServiceAccount token. Claude Code uses it through a gitignored
  local settings file. The admin kubeconfig is denied.
- Client-side guardrails: [`.claude/settings.json`](.claude/settings.json) allows
  read commands and denies `kubectl apply/delete/edit/patch/exec` and
  `flux reconcile/suspend`.
- Changes through Git: Claude works on a branch. A human reviews, commits and merges,
  and Flux rolls out the change.

Why it is set up this way: the RBAC is enforced by the API server, so even if a
client-side rule is bypassed, the agent still cannot change the cluster or read
secrets. Every change goes through review and is recorded in Git history, the same
as for a human operator. The repo is public, so no credentials are ever part of the
setup in Git.

Details: [docs/claude-agent.md](docs/claude-agent.md).

## License and contributions

[MIT](LICENSE): copy whatever is useful. This is a personal lab, so pull requests from others
are not accepted, but issues and questions are welcome. To report a security problem, see
[SECURITY.md](SECURITY.md).
