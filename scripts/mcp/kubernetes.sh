#!/usr/bin/env bash
# Starts the Kubernetes MCP server (Flux159/mcp-server-kubernetes) for Claude Code.
# Started by .mcp.json. Read-only twice over: the server only offers get/describe/logs
# tools, and the claude-readonly ServiceAccount cannot write or read secrets.
set -euo pipefail

VERSION="4.1.9"

export KUBECONFIG="${HOME}/.kube/claude-readonly.yaml"
export ALLOW_ONLY_READONLY_TOOLS=true
export MASK_SECRETS=true

if [[ ! -r "$KUBECONFIG" ]]; then
  echo "ERROR: $KUBECONFIG not found. Run scripts/create-claude-kubeconfig.sh first." >&2
  exit 1
fi

exec npx -y "mcp-server-kubernetes@${VERSION}"
