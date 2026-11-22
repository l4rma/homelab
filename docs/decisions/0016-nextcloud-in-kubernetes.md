---
status: accepted
date: 2026-11-21
---

# Nextcloud in Kubernetes with the Helm chart, user files on NFS

## Context

I want notes and a replacement for Google Drive and Dropbox: files synced to the laptops and
phones, shared links, and notes I can edit in the browser and on the phone. The old Nextcloud
(LXC `nextcloudpi`) was removed in October 2026 without moving its data, so this starts from
scratch.

Two things to decide: which app, and how it runs and stores its data. Nextcloud is not needed
to run or fix the cluster, so it belongs in Kubernetes
([ADR 0014](0014-infrastructure-services-stay-outside-kubernetes.md)).

## Options

What to run:

- **OpenCloud** (a Go fork of ownCloud Infinite Scale): one binary, no database, files and
  metadata on disk. Much lighter, but no Notes app, calendar or contacts, and a much smaller
  ecosystem.
- **Seafile**: fast sync, but stores files in its own block format, not as plain files, and
  has no good notes app.
- **Nextcloud** (chosen): Files, Notes (Markdown files, with mobile apps), calendar and
  contacts if I want them later. The files stay plain files on disk.

How to run it:

- **Nextcloud All-in-One**: built around the Docker socket and its own master container.
  Does not fit Kubernetes or Flux.
- **Hand-written manifests**, like Immich: full control, but `config.php`, cron, the
  metrics exporter and the probes would all be mine to write and keep up to date.
- **The community Helm chart `nextcloud/helm`** (chosen), with the official `nextcloud` image
  (Apache), and the chart's bundled Postgres and Redis turned off.

Where the data goes:

- **Everything on NFS**, including `/var/www/html`: PHP reads thousands of small files per
  request, which is slow over NFS. The image's entrypoint also copies the code into that
  folder on every upgrade.
- **Everything on `local-path`**: fast, but the user files would be outside ZFS snapshots and
  on a node's root disk.
- **Split** (chosen): user files on NFS from `AnorLondo/nextcloud`; the app folder
  (`/var/www/html`: code, `config.php`, apps) and Postgres (CloudNativePG) on `local-path`.

## Decision

Nextcloud, with the community Helm chart, and the split storage. It is the same pattern as
Immich ([storage](../architecture/storage.md)): files on the NAS, databases on the node.

- **Valkey** is required, not optional. Nextcloud's transactional file locking goes through
  it, so nothing relies on NFS locks. It is also the cache.
- **Nextcloud runs as `www-data` (UID 33)**, so the dataset is owned by 33:33 with mode 770.
  Nextcloud refuses a data directory that other users can read. The chart mounts the
  subfolder `data/` as a subPath, which the kubelet sets up as root, so the NFS share maps
  root to `www-data` (maproot) instead of `nobody`. It weakens nothing: with `sec=sys`, root
  on a node can already act as any UID. The dataset gets no SMB
  share of its own. It shows up as a folder in the `AnorLondo` SMB share, but `larma` has no
  access to it, which is on purpose: Nextcloud keeps its own index of the files, and files
  changed behind its back do not show up until `occ files:scan`. Devices reach the files
  through the Nextcloud clients or WebDAV.
- **Nextcloud and its Postgres run on the same node** (lenovo2). The app's `local-path`
  volume pins it to one node anyway, and Nextcloud makes many small queries per request.

## Consequences

- Good: the files are plain files in a dataset with daily snapshots (`AnorLondo`, 30 days),
  and get the same offsite backup as the photos later.
- Good: the chart is maintained upstream and Renovate can update it.
- Bad: Nextcloud is down when lenovo2 is down. Accepted, as for Immich and Jellyfin.
- Bad: shares, file versions' metadata, notes' metadata and (later) calendars and contacts
  are only in Postgres, on a local disk, outside ZFS snapshots. Until it has its own backup
  (a `pg_dump` to the NAS in phase 14, Barman to S3 in phase 16), do not keep files in
  Nextcloud that exist nowhere else.
- Bad: Nextcloud can only be upgraded one major version at a time, and a chart minor
  release can bring a new Nextcloud major. The image tag is pinned on its own, so Renovate
  shows a Nextcloud major as a major update.
- Bad: PHP, cron, Postgres and Valkey is a lot of moving parts for notes and files.

## More information

- Epic #89, issues #90 (storage and database) and #91 (deploy)
- Chart: <https://github.com/nextcloud/helm>
- System requirements: <https://docs.nextcloud.com/server/latest/admin_manual/installation/system_requirements.html>
