# homelab

Monorepo for the whole homelab: Kubernetes (GitOps with Flux), and later Terraform,
Ansible, Crossplane and AWS. The repository is **public**. See `README.md` for the
architecture.

## The homelab in short

- **Kubernetes**: bare-metal kubeadm cluster with three nodes (two Lenovo ThinkCentre
  M720q and a Raspberry Pi 5), managed by Flux from `kubernetes/`.
- **Proxmox VE**: runs TrueNAS SCALE in a VM (NFS/SMB, storage, backups, Omada
  controller app) and VMs/LXCs for services not yet in Kubernetes (Pi-hole,
  Nextcloud, and Portainer with Homarr, Jellyfin, Radarr and Sonarr).
- **AWS**: Route53 hosts `magelssen.io`, used by cert-manager for DNS-01.
- **Goal**: move the services on Proxmox into Kubernetes, and manage Proxmox and AWS
  as code.

## Repository layout

| Path | Contents | Read before working there |
|---|---|---|
| `kubernetes/` | Flux entrypoint, infrastructure and apps | `kubernetes/CLAUDE.md` |
| `terraform/` | Proxmox and AWS as code (no code yet) | `terraform/CLAUDE.md` |
| `ansible/` | Node and NAS configuration (no code yet) | `ansible/README.md` |
| `scripts/` | Helper scripts run locally | |
| `docs/` | Documentation | |
| `tmp/` | Local scratch notes, gitignored | |

## Rules for Claude

- You have **read-only** access to all systems. For Kubernetes this is the
  `claude/claude-readonly` ServiceAccount (details in `kubernetes/CLAUDE.md`). You
  cannot read secrets.
- Read-only MCP servers for Kubernetes, GitHub and Proxmox are set up in `.mcp.json`
  (see `docs/claude-agent.md`). Use them to read the real state instead of relying
  on hand-written docs.
- For how-to and reference questions, use the official docs as the main source,
  and prefer the page for the version that runs here:
  - TrueNAS: https://www.truenas.com/docs/
  - Proxmox VE: https://pve.proxmox.com/pve-docs/
  - Kubernetes: https://kubernetes.io/docs/home/
- All changes go through Git, never directly against a system. Flux (and later
  Terraform runs started by a human) roll out what is merged to `main`.
- Create a new branch for every change. Explain what you change and why.
- Do not commit, push or merge unless asked.
- No secrets in plain text, anywhere. The repo is public. kubeconfigs, tokens, age
  keys, Terraform state and `.tfvars` files must never be committed.
- Follow the existing conventions in each directory.
- If something is unclear or looks risky, ask instead of guessing.
