# Claude as an agent in the homelab

Claude Code has **read-only** access to the homelab. All changes go through Git and
are rolled out by Flux (or by a human), never by Claude directly.

## How access is limited

Claude can inspect the cluster and propose changes, but it cannot change anything by
itself:

- Read-only ServiceAccount: `claude-readonly` is bound to the built-in `view`
  ClusterRole plus a small extra ClusterRole for nodes, persistent volumes, CRDs,
  Flux, Prometheus Operator and Gateway API resources, and may run PromQL queries
  through the Prometheus Service. It has no access to secrets. The RBAC is managed by Flux like
  everything else, in [`kubernetes/infrastructure/claude-readonly`](../../kubernetes/infrastructure/claude-readonly/).
- Separate kubeconfig: a [script](../../scripts/create-claude-kubeconfig.sh) builds a
  kubeconfig from the ServiceAccount token. Claude Code uses it through a gitignored
  local settings file. The admin kubeconfig is denied.
- Client-side guardrails: [`.claude/settings.json`](../../.claude/settings.json) allows
  read commands and denies `kubectl apply/delete/edit/patch/exec` and
  `flux reconcile/suspend`.
- Changes through Git: Claude works on a branch. A human reviews, commits and merges,
  and Flux rolls out the change.

Why it is set up this way: the RBAC is enforced by the API server, so even if a
client-side rule is bypassed, the agent still cannot change the cluster or read
secrets. Every change goes through review and is recorded in Git history, the same
as for a human operator. The repo is public, so no credentials are ever part of the
setup in Git.

## MCP servers

`.mcp.json` registers three MCP servers. Each one is started by a wrapper script in
`scripts/mcp/` that pins the version and turns on the server's read-only mode. The
credentials are read-only as well, so a bug in a server cannot be used to write.
Secrets live outside the repo, in `~/.config/homelab-mcp/` (`chmod 600`), and
`.claude/settings.json` denies Claude from reading that directory.

| Server | Project | Runs with | Read-only through |
|---|---|---|---|
| `kubernetes` | [Flux159/mcp-server-kubernetes](https://github.com/Flux159/mcp-server-kubernetes) | `npx` | `ALLOW_ONLY_READONLY_TOOLS=true` + the `claude-readonly` ServiceAccount |
| `github` | [github/github-mcp-server](https://github.com/github/github-mcp-server) | `docker` | `GITHUB_READ_ONLY=1` + a read-only fine-grained PAT |
| `proxmox` | [GethosTheWalrus/proxmox-mcp](https://github.com/GethosTheWalrus/proxmox-mcp) | `uvx` | `PROXMOX_READ_ONLY=true` + an API token with the `PVEAuditor` role |

Claude Code asks once whether to trust the servers in `.mcp.json`. Check the status
with `claude mcp list` or `/mcp` in a session.

### Kubernetes

Uses the kubeconfig from `scripts/create-claude-kubeconfig.sh`
(`~/.kube/claude-readonly.yaml`). No extra setup is needed. Only the get, describe,
logs, explain and api-resources tools are offered; calls to any other tool are
refused by the server.

### GitHub

Create a [fine-grained personal access token](https://github.com/settings/personal-access-tokens/new):

- Repository access: only `l4rma/homelab`
- Repository permissions, all **Read-only**: Actions, Contents, Issues, Metadata,
  Pull requests
- An expiry date (renew it when it runs out)

```sh
mkdir -p ~/.config/homelab-mcp && chmod 700 ~/.config/homelab-mcp
install -m 600 /dev/null ~/.config/homelab-mcp/github.env
$EDITOR ~/.config/homelab-mcp/github.env   # GITHUB_PERSONAL_ACCESS_TOKEN=github_pat_...
```

Lockdown mode is on, so content from users without push access to the repo is
hidden from Claude. This limits prompt injection through issues and comments.

Claude stays read-only on GitHub: it does not push or open pull requests, and gets no
account of its own ([ADR 0010](../decisions/0010-no-bot-account-for-claude.md)). If it ever
works without a human at the keyboard, it gets a GitHub App that can open pull requests
but never merge them.

### Proxmox

Create a user and an API token with read-only access, on the Proxmox host as root.
With privilege separation on, the token only gets what is granted to both the user
and the token:

```sh
pveum user add claude@pve --comment "Claude Code, read-only (MCP)"
pveum acl modify / --users claude@pve --roles PVEAuditor
pveum user token add claude@pve mcp --privsep 1   # prints the secret once
pveum acl modify / --tokens 'claude@pve!mcp' --roles PVEAuditor
```

The server connects to `proxmox.magelssen.io:443` through Envoy Gateway
(`kubernetes/apps/proxmox`), which has a trusted Let's Encrypt certificate, so TLS
is verified without a custom CA. Store the token:

```sh
mkdir -p ~/.config/homelab-mcp && chmod 700 ~/.config/homelab-mcp
install -m 600 /dev/null ~/.config/homelab-mcp/proxmox.env
$EDITOR ~/.config/homelab-mcp/proxmox.env
```

```sh
PROXMOX_USER=claude@pve
PROXMOX_TOKEN_NAME=mcp
PROXMOX_TOKEN_VALUE=<token secret>
```

`uvx` comes from [uv](https://docs.astral.sh/uv/getting-started/installation/).
The raw API tool is turned off (`PROXMOX_DISABLE_RAW_API=true`).

### TrueNAS (helper script, until the MCP server exists)

There is no TrueNAS MCP server yet. Until there is, Claude calls the TrueNAS API
with `scripts/truenas-api.py <method> [param ...]`, which uses the official client
([truenas/api_client](https://github.com/truenas/api_client), pinned to the
TrueNAS version) and prints the result as JSON. The script reads the key itself,
so Claude never sees it.

What Claude may do is decided by the TrueNAS user the key belongs to, not by the
script. Start with read-only, and change the user's privilege on TrueNAS to give
more access later.

On TrueNAS (25.10):

1. Credentials → Users → Add: username `claude`, no password login, shell
   `nologin`, no SMB access, no home directory.
2. Give it the **Read-Only Administrator** role (TrueNAS access in the user form,
   or through a group with that privilege under Credentials → Groups).
3. Create an API key for `claude` (Credentials → Users → API Keys). It is shown
   once. Give it an expiry date if you want to renew it regularly.

Store the key:

```sh
install -m 600 /dev/null ~/.config/homelab-mcp/truenas.env
$EDITOR ~/.config/homelab-mcp/truenas.env   # TRUENAS_API_KEY=<key>
```

The script connects to `wss://truenas.magelssen.io/api/current` through
Envoy Gateway (`kubernetes/apps/truenas`), which has a trusted Let's Encrypt
certificate, the same way as Proxmox. TrueNAS revokes an API key that is used over
an unencrypted connection, so the script only accepts `wss://`.

### Updating a server

Bump the pinned version (`VERSION` or `IMAGE`) in the wrapper script in its own PR.
Read the changelog first, and check that the read-only switch still exists and
still works.

### AWS

Planned: a read-only IAM role, set up the same way.
