# Uptime Kuma

Uptime Kuma runs in LXC 101 on Proxmox, outside the cluster, so it checks the services the
way a browser on the LAN does and keeps running when the cluster is down
([ADR 0011](decisions/0011-alerting-with-alertmanager-and-telegram.md)). It is installed
from source with Node.js, not Docker
([ADR 0013](decisions/0013-uptime-kuma-without-docker.md)).

The LXC is set up by hand until Terraform and Ansible cover Proxmox (#104). These are the
steps that were used, so it can be rebuilt.

| What | Value |
|---|---|
| LXC | 101 `uptime-kuma`, unprivileged, Debian 13, 1 core, 1 GB RAM, 512 MB swap, 8 GB on `local-lvm` |
| Network | `vmbr20` (VLAN 20, no tag on the LXC), `192.168.20.10/24`, gateway `192.168.20.1` |
| DNS | `192.168.20.20` (Pi-hole). Only Pi-hole has the `*.magelssen.io` records |
| Code | `/opt/uptime-kuma`, git tag of the running version, owned by root |
| Data | `/var/lib/uptime-kuma` (`DATA_DIR`), SQLite, owned by the `uptime-kuma` user, mode 700 |
| Service | `uptime-kuma.service` (systemd), port 3001, plain HTTP |
| URL | `https://uptime-kuma.magelssen.io` through Envoy (`kubernetes/apps/uptime-kuma/`), or `http://192.168.20.10:3001` when the cluster is down |
| Version | In [versions.md](versions.md). Renovate cannot see it |

## Create the LXC

In the Proxmox UI, from the `debian-13-standard` template on `local` (download it with
`pveam download local debian-13-standard_<version>_amd64.tar.zst`). Keep the template on
`local`, not on SensFortress: SensFortress is a share from the TrueNAS VM on the same host.

Use the values in the table above, unprivileged, with `nesting=1` (the default, systemd
needs it), and **start at boot** on.

## Install

As root in the LXC (`pct enter 101` on pve). Uptime Kuma 2.x needs Node.js 20.4 or newer,
and Debian 13 ships 20.19.

```bash
apt update && apt full-upgrade -y
apt install -y nodejs npm git ca-certificates

useradd --system --home-dir /var/lib/uptime-kuma --create-home --shell /usr/sbin/nologin uptime-kuma
chmod 700 /var/lib/uptime-kuma

VERSION=2.5.8
git clone --branch "$VERSION" --depth 1 https://github.com/louislam/uptime-kuma.git /opt/uptime-kuma
cd /opt/uptime-kuma
npm ci --omit dev --no-audit   # what `npm run setup` does, without its `git checkout`
npm run download-dist          # the built frontend for this version, from GitHub Releases
```

`npm ci` prints many `deprecated` warnings and `TAR_ENTRY_ERROR EINVAL ... fchown`. Both
are harmless: the first come from Uptime Kuma's dependencies, the second because root in an
unprivileged LXC cannot set high UIDs, so the files stay owned by root.

Check that the dependencies and the SQLite driver are there:

```bash
npm ls --omit dev > /dev/null && echo "deps OK"
node -e "require('@louislam/sqlite3'); console.log('sqlite OK')"
```

## systemd unit

```bash
cat > /etc/systemd/system/uptime-kuma.service <<'EOF'
[Unit]
Description=Uptime Kuma
After=network-online.target
Wants=network-online.target

[Service]
User=uptime-kuma
Group=uptime-kuma
WorkingDirectory=/opt/uptime-kuma
Environment=NODE_ENV=production
Environment=DATA_DIR=/var/lib/uptime-kuma/
Environment=UPTIME_KUMA_PORT=3001
ExecStart=/usr/bin/node server/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now uptime-kuma
```

On a fresh install without data, the first page asks for the database type: choose SQLite.
When restoring data, put it in place **before** the first start (see below), or the service
starts in database setup mode. `systemctl start` does nothing when the service already runs:
use `systemctl restart` after changing the data.

In the UI: **Settings → Reverse Proxy → Trusted Proxies: Yes**, since it sits behind Envoy.

## Restore or move the data

Uptime Kuma keeps everything in `DATA_DIR`: `kuma.db`, `db-config.json` (`{"type":"sqlite"}`),
`upload/`, `screenshots/`, `docker-tls/`. Copy the whole folder while Uptime Kuma is stopped
on both sides, then:

```bash
systemctl stop uptime-kuma
tar -C /var/lib/uptime-kuma -xzf /tmp/kuma.tgz
chown -R uptime-kuma: /var/lib/uptime-kuma
chmod 700 /var/lib/uptime-kuma
chmod 600 /var/lib/uptime-kuma/kuma.db
systemctl start uptime-kuma
journalctl -u uptime-kuma -n 30   # look for "Database Type: sqlite" and "Connected to the database"
```

To get a file into the LXC without SSH: copy it to pve, then `pct push 101 <file> /tmp/<file>`.

The data was moved from the cluster on 2026-11-19 (#129). The old copy is still on the
TrueNAS dataset `BlightTown/uptime-kuma` and is deleted once the LXC has a backup (phase 14).

## Upgrade

Snapshot the LXC first (`pct snapshot 101 pre-<version>`), since a new version can migrate the
database and there is no way back. Then:

```bash
systemctl stop uptime-kuma
cd /opt/uptime-kuma
git fetch --depth 1 origin tag <version>
git checkout <version>
npm ci --omit dev --no-audit
npm run download-dist
systemctl start uptime-kuma
```

Update [versions.md](versions.md) in the same PR as any doc change, or on its own.

## Monitors

- No Ping monitors: the service user cannot open ICMP sockets in the unprivileged LXC.
  The nodes are checked with TCP Port monitors instead (`192.168.30.10:6443`, the API
  server, and `192.168.30.11:10250` / `192.168.30.12:10250`, the kubelet), which also show
  that Kubernetes answers on the node.
- Sites are checked on their `https://<name>.magelssen.io` address, through the Gateway at
  `192.168.30.200`, like a user reaches them. Cluster-internal names do not resolve here.
- `.io` has no RDAP server, so the log warns `Domain expiry unsupported` for each
  `magelssen.io` monitor. Turn off the domain expiry option on those monitors.
