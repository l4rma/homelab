# Storage

All data lives on TrueNAS SCALE (a VM on Proxmox) in one pool, `Firelink`: three disks
in RAIDZ1, about 7.2 TiB usable. The layout was cleaned up in October 2026, before
backups were set up.

## Rule: one top-level dataset per kind of data

Snapshots, retention, quotas and replication are set per dataset in ZFS. So each
top-level dataset holds one kind of data with one backup policy, and anything below it
inherits that policy. Dark Souls names at the top level, plain names below.

| Dataset | Contents | Backup policy |
|---|---|---|
| `AnorLondo` | Personal files: photos (Immich), documents (Nextcloud), SMB share | Highest, offsite. Irreplaceable. |
| `DukesArchives` | Media library: `movies/`, `series/`, `downloads/` | Low. Can be downloaded again. |
| `BlightTown` | Kubernetes app data over NFS, one child dataset per app | Medium |
| `SensFortress` | The only Proxmox storage (ISOs, LXC templates, VM disks) | Low |
| `UndeadParish` | Data for TrueNAS apps (Omada) | Medium |
| `Catacombs` | Backup target only | (is the backup) |
| `ix-apps` | TrueNAS system dataset | Do not touch |

```
Firelink
├── AnorLondo
│   ├── immich            photo library (planned)
│   └── nextcloud         Nextcloud user files (planned)
├── DukesArchives         movies/ series/ downloads/  (folders, not datasets)
├── BlightTown
│   ├── home-assistant
│   └── uptime-kuma
├── SensFortress          template/iso, template/cache, images/
├── UndeadParish
│   └── omada
└── Catacombs
    └── backups
```

## Who uses what

| Consumer | How | Path |
|---|---|---|
| Kubernetes (static PVs) | NFS, one share per app dataset, only `192.168.30.0/24` | `/mnt/Firelink/BlightTown/<app>` |
| Proxmox storage `SensFortress` | SMB (CIFS), mounted by Proxmox at `/mnt/pve/SensFortress` | `SensFortress` |
| Plex (LXC 101) and the docker LXC (102) | SMB, `/etc/fstab` on pve at `/mnt/dukesarchives`, bind-mounted into the LXCs | `DukesArchives` |
| Personal devices | SMB | `AnorLondo` |
| Omada (TrueNAS app) | host path | `Catacombs/data` (moving to `UndeadParish/omada`) |

## Things to know

- **An NFS share does not reach into child datasets.** A share on `BlightTown` shows each
  child dataset as an empty, root-owned folder. Every app dataset needs its own share.
- **Kubernetes PVs are static, and `spec.nfs.path` cannot be changed.** Keep the
  dataset at the path the PV points to.
- **Do not put SQLite on NFS** (Uptime Kuma, the *arr apps, Jellyfin). Use local disk
  in the cluster instead.
- **Media stays one dataset.** Radarr and Sonarr hardlink from `downloads/` to
  `movies/` and `series/`, and hardlinks do not work across datasets or across
  separate mounts. Mount the whole dataset once (as `/data`) in the apps that move files.
- **Proxmox's folder layout is fixed:** ISOs go in `template/iso/`, LXC templates in
  `template/cache/`, disks in `images/<vmid>/`. Removing a Proxmox storage does not
  unmount it, so also run `umount /mnt/pve/<name>`.
- **Boot order:** TrueNAS is a VM on the same host as the CIFS mounts, so at boot the
  mounts and the guests that use them can start before TrueNAS is up. This is not fixed yet.
- **Fixed for good:** the pool layout (RAIDZ1), ashift, encryption and case
  sensitivity. Dataset names and properties like `recordsize` can be changed later.
