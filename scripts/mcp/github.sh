#!/usr/bin/env bash
# Starts the GitHub MCP server (github/github-mcp-server) for Claude Code.
# Started by .mcp.json. The token is a fine-grained PAT with read-only permissions,
# kept outside the repo in ~/.config/homelab-mcp/github.env:
#   GITHUB_PERSONAL_ACCESS_TOKEN=github_pat_...
set -euo pipefail

IMAGE="ghcr.io/github/github-mcp-server:v2.0.3"
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/homelab-mcp/github.env"

if [[ ! -r "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. See docs/claude-agent.md." >&2
  exit 1
fi
set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

# Lockdown mode hides content from users without push access (prompt injection
# through issues and PR comments once the repo is public).
exec docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN \
  -e GITHUB_READ_ONLY=1 \
  -e GITHUB_LOCKDOWN_MODE=1 \
  -e GITHUB_TOOLSETS="context,repos,issues,pull_requests,actions" \
  "$IMAGE"
