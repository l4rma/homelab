# Backups

What is backed up, where, and how to restore it. Everything here is local: the copies are
in the same pool as the data, so losing the pool loses both. Offsite copies come later.

## ZFS snapshots (TrueNAS)

Periodic snapshot tasks under Data Protection. A snapshot protects against deleting or
overwriting files, not against losing the pool.

| Dataset | Schedule | Kept |
|---|---|---|
| `AnorLondo` (recursive) | Daily | 30 days |
| `BlightTown` (recursive), `UndeadParish` (recursive), `Catacombs` (recursive) | Daily | 14 days |
| `DukesArchives` | Weekly (Sunday) | 2 weeks |

"Allow taking empty snapshots" is on for every task. Each snapshot expires when its time is
up, whether or not a newer one exists: without it, a dataset that does not change for longer
than the retention ends up with no snapshot at all. An unchanged snapshot only costs a few KB
of metadata.

To get a file back, browse `.zfs/snapshot/<name>/` in the dataset, or roll back the dataset
in the TrueNAS UI (rollback throws away everything newer than the snapshot).

## Laptops (restic)

restic's `rest-server` runs in Kubernetes at `https://restic.magelssen.io` (manifests in
`kubernetes/apps/restic/`). The repositories are in `Catacombs/backups/restic`, one per laptop
user. restic encrypts everything on the laptop before it is sent.

- **Append-only:** a laptop can add backups, but not delete or change old ones. Ransomware or a
  mistake on the laptop cannot destroy its history. The flip side: `restic forget` and
  `restic prune` fail from the laptop, so old snapshots are cleaned up on the server (planned:
  a CronJob, which needs each repository's password in SSM).
- **Private repositories:** each user logs in with its own name and can only reach the
  repository under `/<user>/`.
- Reachable on the home network only, so laptops back up when they are home.

Each laptop has two passwords. Keep both in the password manager:

| Password | Used for |
|---|---|
| Login | rest-server's login for that user. Only its hash is in SSM (`/homelab/restic/htpasswd`) |
| Repository password | Encrypts the laptop's repository. **Without it the backups cannot be read**, and nobody can recover it |

### Add a laptop

1. Pick a user name, for example `<user>-<hostname>`, and create the login hash (needs
   `apache2-utils`). It asks for the login password:

   ```sh
   htpasswd -nB <user>-<hostname>
   ```

2. Add the printed line to the SSM parameter `/homelab/restic/htpasswd`, one line per laptop.
   The Secret refreshes within an hour (to hurry it, annotate the ExternalSecret:
   `kubectl annotate externalsecret -n restic rest-server-htpasswd force-sync=$(date +%s) --overwrite`),
   and rest-server reloads the file by itself.
3. On the laptop, install restic (`sudo apt install restic`, or see the
   [install guide](https://restic.readthedocs.io/en/stable/020_installation.html)), and put the
   settings in a file only you can read, for example `~/.config/restic/env`:

   ```sh
   export RESTIC_REPOSITORY="rest:https://<user>-<hostname>:<login-password>@restic.magelssen.io/<user>-<hostname>/"
   export RESTIC_PASSWORD_FILE="$HOME/.config/restic/password"   # the repository password
   ```

4. Create the repository and take the first backup:

   ```sh
   . ~/.config/restic/env
   restic init
   restic backup ~ --exclude-caches --exclude ~/Downloads --exclude ~/.cache
   ```

5. Schedule it with a systemd user timer (or cron) that runs the same `restic backup` command,
   for example every hour. For a desktop app instead of the command line,
   [Backrest](https://github.com/garethgeorge/backrest) is a web UI for restic that can use the
   same repository and schedule the backups.

### Restore

```sh
. ~/.config/restic/env
restic snapshots
restic restore latest --target /tmp/restore          # or a snapshot ID instead of latest
restic restore latest --target /tmp/restore --include /home/<user>/Documents/file.txt
restic mount /mnt/restic                             # browse all snapshots as folders
```

A new or reinstalled laptop needs only the two passwords and the repository URL.

## Not backed up on purpose

- Proxmox VMs and LXCs (decided 2026-11-04). They are small and can be rebuilt.
- `DukesArchives` beyond the weekly snapshot, for now: 4 TiB does not fit twice on the pool.
  The media is wanted, so revisit it with offsite backups (phase 16).

## Not backed up yet

- **Actual Budget** (`/data` on `local-path` on pi5): the server password and the budgets.
  Every device that has a budget open keeps a full copy and syncs it back, and a budget can
  be exported in the UI (Settings, Export data). A copy to the NAS comes with the other
  `local-path` data in phase 14.
- **Nextcloud's database** (`nextcloud-db`, on `local-path` on lenovo2): the file index,
  shares and app data. The user files are in `AnorLondo/nextcloud` and are snapshotted, but
  the database is outside ZFS. A `pg_dump` to the NAS comes in phase 14
  ([nextcloud.md](../services/nextcloud.md#backups-and-restore)).
