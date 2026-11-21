# Nextcloud

Notes and files, to replace Google Drive and Dropbox. Runs in the cluster with the community
Helm chart and the official image (Apache). Why, and how the data is split:
[ADR 0016](../decisions/0016-nextcloud-in-kubernetes.md).

| What | Value |
|---|---|
| URL | `https://nextcloud.magelssen.io` |
| In Git | `kubernetes/apps/nextcloud/` (HelmRelease, Postgres, Valkey, volumes) |
| Runs on | lenovo2 only (its app folder is on `local-path` there) |
| User files | NFS, `AnorLondo/nextcloud`, subfolder `data/`, owned by www-data (33:33), mode 770 |
| App folder | `/var/www/html` (code, `config/`, `custom_apps/`, `themes/`) on `local-path`, PVC `nextcloud-app-pvc` |
| Database | CloudNativePG `nextcloud-db`, Postgres 18, on `local-path` on lenovo2 |
| Cache and file locking | Valkey `nextcloud-valkey`, no persistence, plus APCu in each PHP process |
| Background jobs | Cron sidecar in the pod, every 5 minutes |
| Admin account | `admin`, password from SSM `/homelab/nextcloud/admin-password` (first start only) |
| Metrics | Nextcloud's own `/metrics` (OpenMetrics), scraped by a ServiceMonitor |
| Version | Chart and image tag in `helmrelease.yaml`, updated by Renovate |

## First setup

Before the HelmRelease is merged:

1. Store the admin password in SSM. It is only used when Nextcloud installs itself on the
   first start. In the AWS Console (region `eu-west-1`): **Systems Manager → Parameter Store →
   Create parameter**, name `/homelab/nextcloud/admin-password`, tier Standard, type
   **SecureString** (KMS key `alias/aws/ssm`), and paste the password from the password manager
   into the value field. This keeps it out of the shell history.

2. In Pi-hole, add the local DNS record `nextcloud.magelssen.io` → `192.168.30.200`, like the
   other apps.

After the merge, the first start copies the code to the app folder and runs the installer
before Apache answers. That takes a few minutes, and the startup probe allows five. Follow it
with:

```sh
kubectl -n nextcloud logs deploy/nextcloud -c nextcloud -f
```

Then, in the web UI:

1. Log in as `admin`, and create your own user (with admin rights, if you want). Use your own
   user day to day, and keep `admin` for emergencies.
2. **Administration settings → Overview**: go through the warnings. Missing email settings
   are expected.
3. **Apps**: install **Notes**. Turn off apps you do not need.
4. Install the clients: the desktop client (sync), the Nextcloud app on the phones (files,
   automatic photo upload is off, since Immich does that) and the Notes app
   (Android/iOS).

## occ

`occ` must run as `www-data`, the owner of `config.php`:

```sh
kubectl -n nextcloud exec -it deploy/nextcloud -c nextcloud -- \
  su -s /bin/sh www-data -c "php occ status"
```

Useful commands: `status`, `user:list`, `user:resetpassword <user>`,
`files:scan --all` (after files were changed outside Nextcloud), `maintenance:mode --on|--off`,
`db:add-missing-indices`, `maintenance:repair --include-expensive`.

## Upgrades

Renovate opens a pull request for the chart and, separately, for the image tag. Both get the
`manual-step` label.

- **Nextcloud can only go up one major version at a time** (35 → 36 → 37). The image refuses
  to start when a major is skipped. A major update is only opened after ticking it in the
  Dependency Dashboard.
- Read the release notes, and check in **Apps** that the apps you use support the new major.
- Back up first (see below), then merge. The image runs `occ upgrade` by itself when it
  starts with a newer version.
- Afterwards, check the admin overview, and run `db:add-missing-indices` if it asks for it.
- There is no way back: downgrading is not supported. To roll back, restore the database and
  the app folder from before the upgrade.

## Backups and restore

- **User files**: daily ZFS snapshots of `AnorLondo` (recursive, kept 30 days). Offsite later
  (phase 16).
- **Database**: **not backed up yet**. It holds the file index, shares, versions' metadata and
  app data (calendars, contacts). A `pg_dump` to the NAS comes in phase 14. Until then, keep no
  files in Nextcloud that exist nowhere else.
- **App folder**: nothing in it that cannot be recreated, apart from `config/config.php`
  (instance ID, password salt, secret). It should be backed up with the database.

To get one file back, find it under `.zfs/snapshot/<name>/data/<user>/files/` on TrueNAS,
copy it into the user's folder, and run `occ files:scan <user>`.

## Things to know

- **Do not change the files outside Nextcloud.** It keeps its own index of the files, and does
  not see changes made behind its back until `occ files:scan`. The folder shows up in the
  `AnorLondo` SMB share, but `larma` cannot open it, on purpose.
- **The chart always mounts the data folder as a subPath `data`** of the NFS volume. The
  kubelet creates subPaths as root, and NFS maps root to `nobody`, which cannot write in the
  dataset. An init container (`create-data-dir`, running as 33) creates `data/` first.
- **Trusted domains** are `nextcloud.magelssen.io` and `10.244.*` (pod IPs), so Prometheus can
  scrape `/metrics` with the pod IP as the host. Envoy's pods (`10.244.0.0/16`) are trusted
  proxies.
- **Nextcloud is down when lenovo2 is down.** The app folder and the database are on its disk.
