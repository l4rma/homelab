#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "truenas_api_client @ git+https://github.com/truenas/api_client@TS-25.10.7",
# ]
# ///
"""Calls one TrueNAS API method and prints the result as JSON.

Stopgap until the TrueNAS MCP server exists. Authenticates with the API key of
the `claude` TrueNAS user, so what a call may do is decided by that user's
privilege on TrueNAS. The key lives outside the repo in
~/.config/homelab-mcp/truenas.env and is never printed:
  TRUENAS_API_KEY=<key>
  TRUENAS_URL=wss://truenas.magelssen.io/api/current   (optional)

Usage:
  scripts/truenas-api.py <method> [param ...]
Each param is parsed as JSON, or passed as a string if it is not valid JSON:
  scripts/truenas-api.py system.info
  scripts/truenas-api.py pool.query '[["name", "=", "tank"]]'
"""
import json
import os
import sys
from pathlib import Path

from truenas_api_client import Client, ClientException

DEFAULT_URL = "wss://truenas.magelssen.io/api/current"
ENV_FILE = (
    Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    / "homelab-mcp"
    / "truenas.env"
)


def read_env_file(path: Path) -> dict[str, str]:
    values = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip().strip("'\"")
    return values


def parse_param(raw: str):
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip(), file=sys.stderr)
        return 2
    if not ENV_FILE.is_file():
        print(f"ERROR: {ENV_FILE} not found. See docs/claude-agent.md.", file=sys.stderr)
        return 1

    env = read_env_file(ENV_FILE)
    api_key = env.get("TRUENAS_API_KEY")
    if not api_key:
        print(f"ERROR: TRUENAS_API_KEY is missing in {ENV_FILE}.", file=sys.stderr)
        return 1
    url = env.get("TRUENAS_URL", DEFAULT_URL)
    if not url.startswith("wss://"):
        # TrueNAS revokes API keys that are sent over an unencrypted connection.
        print("ERROR: TRUENAS_URL must use wss://.", file=sys.stderr)
        return 1

    method, params = sys.argv[1], [parse_param(p) for p in sys.argv[2:]]
    try:
        with Client(url) as c:
            if not c.call("auth.login_with_api_key", api_key):
                print("ERROR: TrueNAS rejected the API key.", file=sys.stderr)
                return 1
            result = c.call(method, *params)
    except ClientException as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    json.dump(result, sys.stdout, indent=2, default=str)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
