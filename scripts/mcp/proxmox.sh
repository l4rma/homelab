#!/usr/bin/env bash
# Starts the Proxmox MCP server (GethosTheWalrus/proxmox-mcp) for Claude Code.
# Started by .mcp.json. Read-only twice over: the API token only has the PVEAuditor
# role, and PROXMOX_READ_ONLY makes the server refuse every non-GET request.
# Connects through ingress-nginx (kubernetes/apps/proxmox), which has a trusted
# Let's Encrypt certificate. The token lives outside the repo in
# ~/.config/homelab-mcp/proxmox.env:
#   PROXMOX_USER=claude@pve
#   PROXMOX_TOKEN_NAME=mcp
#   PROXMOX_TOKEN_VALUE=<token secret>
set -euo pipefail

VERSION="1.4.4"
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/homelab-mcp/proxmox.env"

if [[ ! -r "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. See docs/claude-agent.md." >&2
  exit 1
fi
set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

export PROXMOX_HOST=proxmox.magelssen.io
export PROXMOX_PORT=443
export PROXMOX_READ_ONLY=true
export PROXMOX_DISABLE_RAW_API=true
export PROXMOX_VERIFY_SSL=1

exec uvx "proxmox-mcp-server@${VERSION}"
