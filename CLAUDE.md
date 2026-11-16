# homelab

Monorepo for the whole homelab: Kubernetes (GitOps with Flux), and later Terraform,
Ansible, Crossplane and AWS. The repository is **public**. See `README.md` for the
architecture.

## The homelab in short

- **Kubernetes**: bare-metal kubeadm cluster with three nodes (two Lenovo ThinkCentre
  M720q and a Raspberry Pi 5), managed by Flux from `kubernetes/`.
- **Proxmox VE**: runs TrueNAS SCALE in a VM (NFS/SMB, storage, backups, Omada
  controller app) and LXCs for services not in Kubernetes (Pi-hole, Plex, Tailscale).
  The old docker LXC (102) is no longer in use and is being retired.
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
  - TrueNAS: <https://www.truenas.com/docs/>
  - Proxmox VE: <https://pve.proxmox.com/pve-docs/>
  - Kubernetes: <https://kubernetes.io/docs/home/>
- All changes go through Git, never directly against a system. Flux (and later
  Terraform runs started by a human) roll out what is merged to `main`.
- Create a new branch for every change. Explain what you change and why.
- Work is tracked in GitHub issues (epics with sub-issues) and on the project board, see
  `docs/github.md`. Pull requests follow `.github/pull_request_template.md`, link their
  issue, and have a short title: it becomes the commit message on `main`.
- Run `uvx pre-commit run --all-files` before handing over a change. It is what the
  required `pre-commit` check runs (see `docs/github.md`).
- Do not commit, push or merge unless asked.
- No secrets in plain text, anywhere. The repo is public. kubeconfigs, tokens, age
  keys, Terraform state and `.tfvars` files must never be committed.
- Follow the existing conventions in each directory.
- Versions pinned in Git are updated by Renovate (`docs/dependencies.md`). When a PR changes
  a version Renovate cannot see (hosts, Kubernetes itself, services outside Kubernetes),
  update `docs/versions.md` in the same PR.
- When a PR adds a technology, replaces one, or makes a choice between real alternatives,
  write a decision record in `docs/decisions/` in the same PR (see its README).
- If something is unclear or looks risky, ask instead of guessing.
