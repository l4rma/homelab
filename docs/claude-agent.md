# Claude as an agent in the homelab

Claude Code has **read-only** access to the homelab. All changes go through Git and
are rolled out by Flux (or by a human), never by Claude directly.

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

Claude may later get permission to create branches and pull requests, but never to
merge them. A token cannot tell "create a PR" apart from "merge it", so that needs a
ruleset on `main` (require a PR and an approval, no bypass) first. Rulesets need
GitHub Pro on private repos and are free on public ones.

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

The server connects to `proxmox.magelssen.io:443` through ingress-nginx
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

### Updating a server

Bump the pinned version (`VERSION` or `IMAGE`) in the wrapper script in its own PR.
Read the changelog first, and check that the read-only switch still exists and
still works.

### AWS

Planned: a read-only IAM role, set up the same way.
