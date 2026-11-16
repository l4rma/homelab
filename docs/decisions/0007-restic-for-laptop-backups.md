---
status: accepted
date: 2026-11-04
---

# restic for laptop backups, not Kopia

## Context

Laptops need backups to the NAS, also when they are not at home. The backup server runs in
the cluster behind Envoy Gateway, with its data on NFS (`Catacombs/backups`). A laptop that
is stolen or hit by ransomware must not be able to delete its own backups.

## Options

- **Kopia**: fast, with a web UI and a repository server with users. But the
  server speaks gRPC, which needs HTTP/2 and TLS all the way to the pod, so it needs its own
  certificate and extra Envoy settings. The server cannot stop a client from deleting
  snapshots.
- **BorgBackup**: mature, but runs over SSH, which does not fit behind the HTTP gateway.
- **restic with rest-server** (chosen): restic encrypts on the laptop, and rest-server is a
  small HTTP server for the repositories.

## Decision

Chosen: restic with rest-server, because rest-server has an append-only mode (a laptop can add
backups, but not delete or change them), it works as plain HTTP behind Envoy Gateway, and the
same tool can be used later for the offsite copies.

## Consequences

- Good: a lost or compromised laptop cannot destroy its backup history.
- Good: one user per laptop (`--private-repos`), and only the password hashes are in SSM.
- Bad: append-only also means `restic forget` and `prune` fail from the laptop. Old
  snapshots have to be removed on the server (planned: a CronJob).
- Bad: no web UI on the server. [Backrest](https://github.com/garethgeorge/backrest) can be
  used on the laptop.

## More information

[docs/backups.md](../backups.md), [rest-server](https://github.com/restic/rest-server).
