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
│   ├── immich            Immich originals, profile/ and backups/ (DB dumps)
│   └── nextcloud         Nextcloud user files (planned)
├── DukesArchives         movies/ series/ downloads/  (folders, not datasets)
├── BlightTown
│   ├── home-assistant
│   ├── immich            Immich thumbs/ and encoded-video/ (can be regenerated)
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
| Kubernetes (static PVs) | NFS, one share per app dataset, only `192.168.30.0/24` | `/mnt/Firelink/BlightTown/<app>`, `/mnt/Firelink/AnorLondo/immich` |
| Proxmox storage `SensFortress` | SMB (CIFS), mounted by Proxmox at `/mnt/pve/SensFortress` | `SensFortress` |
| Plex (LXC 101) and the docker LXC (102) | SMB, `/etc/fstab` on pve at `/mnt/dukesarchives`, bind-mounted into the LXCs | `DukesArchives` |
| Personal devices | SMB | `AnorLondo` |
| Omada (TrueNAS app) | host path | `Catacombs/data` (moving to `UndeadParish/omada`) |

## Kubernetes: NFS or node-local disk

Two kinds of storage, chosen by the kind of data:

| Data | Where | StorageClass |
|---|---|---|
| Files: photos, documents, media, app config folders | NFS from TrueNAS | none (static PVs) |
| Databases: Postgres (CloudNativePG), SQLite, Prometheus | The node's own disk | `local-path` |

Why databases are not on NFS:

- SQLite needs file locking that NFS does not provide reliably. Uptime Kuma's README
  says NFS is not supported, and the *arr apps are known to corrupt their databases
  on NFS. Postgres is slow and fragile on NFS (every `fsync` goes over the network),
  and Immich's docs require local storage for its database.
- Local disk does not stop when TrueNAS or Proxmox restarts.

What it costs, and how that is handled:

- A local-path volume pins its pod to one node. If that node is down, the app is down.
  Postgres gets its redundancy from CloudNativePG instead (more instances on other
  nodes), not from the storage.
- Local volumes are outside ZFS snapshots, so each database needs its own backup to
  the NAS or S3 (see the backup plan).
- The PVC size is not enforced. Volumes share the node's root disk:

| Node | Root disk | Free (October 2026) |
|---|---|---|
| lenovo1 | 98 GB (LVM) | 80 GB |
| lenovo2 | 196 GB (LVM) | 155 GB |
| pi5 | 459 GB (NVMe) | 417 GB |

Immich is split across two datasets, as Immich's "custom locations" guide allows:
`AnorLondo/immich` is mounted at `/data` (originals, profile pictures, database dumps)
and `BlightTown/immich` at `/data/thumbs` and `/data/encoded-video`. The generated
files can be 10–20% of the library and do not need the offsite backup. Immich runs as
UID/GID 3000 (`larma` on TrueNAS), which owns both datasets, so the originals can also
be read over SMB with the same account. NFS maps root to `nobody`, so running as root
would not work.

Rejected: iSCSI from TrueNAS (democratic-csi) and replicated storage (Longhorn,
Rook-Ceph). Both would let a stateful pod move between nodes, but add a lot of moving
parts, and Ceph is too heavy for 8 GB nodes.

## Snapshots

| Dataset | Schedule | Kept | Notes |
|---|---|---|---|
| `AnorLondo` (recursive) | Daily at 00:00 | 30 days | Empty snapshots allowed |

Snapshots protect against deleting or overwriting by mistake, not against losing the
pool. Real backups come with the backup plan. "Allow taking empty snapshots" is on
because each snapshot expires after 30 days whether or not a newer one exists: without
it, a dataset that does not change for 30 days ends up with no snapshot at all. An
unchanged snapshot only costs a few KB of metadata.

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
