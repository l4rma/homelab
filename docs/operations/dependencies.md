# Dependency updates (Renovate)

[Renovate](https://docs.renovatebot.com/) watches every version pinned in this repository and
opens a pull request when a newer one is out. The configuration is
[`.github/renovate.json5`](../../.github/renovate.json5). It runs as the
[Mend Renovate GitHub App](https://github.com/apps/renovate) (free, hosted by Mend), and
nothing runs in the homelab.

## What it watches

| Where | What | Renovate manager |
|---|---|---|
| `kubernetes/**/helmrelease.yaml` | Helm chart versions, looked up in the matching HelmRepository | `flux` |
| `kubernetes/clusters/homelab/flux-system/gotk-components.yaml` | Flux itself. The pull request regenerates the whole file, like `flux install --export` | `flux` |
| `kubernetes/**` | Container images (`image:`) in Deployments, DaemonSets and upstream manifests | `kubernetes` |
| `kubernetes/apps/immich/postgres-cluster.yaml` | The CloudNativePG image (`imageName:`) | regex |
| `.github/workflows/` | Actions (the SHA and the version comment together), the flux-schema image, the pre-commit version, Hugo (`HUGO_VERSION`) | `github-actions`, regex |
| `.pre-commit-config.yaml` | Hook revisions (`rev: <sha> # frozen: vX.Y.Z`) | `pre-commit` |
| `hugo/go.mod` | The docs website's theme (hugo-book), a Hugo module | `gomod` |

Not in Git, so not seen by Renovate: Proxmox, TrueNAS, the node OS, Kubernetes itself
(kubeadm), containerd, Flannel and everything in the LXCs. Those stay in
[versions.md](versions.md).

## How it behaves

- **Dependency Dashboard:** an issue named "Dependency Dashboard" (in the Issues tab, made and
  kept up to date by Renovate) lists every dependency, what is waiting, and what needs
  approval. The waiting updates have checkboxes: click one, and Renovate opens that pull
  request on its next run, without waiting for the schedule or the approval.
- **Monday mornings:** pull requests are opened between 00:00 and 10:00 on Monday (Oslo
  time). Fixes for vulnerabilities that GitHub reports (Dependabot alerts, here mostly for
  actions) skip the schedule and are opened at once.
- **14 days old:** a version is only proposed when it has been out for 14 days, because most
  broken or hijacked releases are found within days (the same rule as for actions and hooks).
  Some registries do not publish a release date, and those versions are proposed at once.
- **Majors wait for approval:** a major update shows up in the dashboard, and the pull
  request is only opened after ticking it.
- **Grouped:** Immich server and machine learning (they must match), all CI tools (actions
  and pre-commit hooks, minor and patch), and flux-schema in the workflow and the docs.
- **Labels:** `dependencies` on every pull request, `area/*` from the path labeler, and
  `manual-step` on stateful apps (Immich, its Postgres, CloudNativePG, Jellyfin, Home
  Assistant): back up or snapshot before merging.
- **No automerge.** Merging to `main` deploys to the cluster, so a human merges every update.

## Reviewing a Renovate pull request

1. Read the release notes in the pull request description. Look for breaking changes and
   for steps to take before or after.
2. Check that the checks are green. `kubernetes` validates a chart bump against the schemas,
   but not the chart's values: helm-controller checks those when it installs.
3. For a `manual-step` pull request, take the backup first (see [backups.md](backups.md)).
4. Images must stay multi-arch (amd64 and arm64), because `pi5` is arm64.
5. Merge, and watch Flux roll it out: `flux get helmreleases -A`, or the pods.
6. To roll back, revert the squash commit (`git revert`) in a new pull request. Jellyfin and
   database majors have no way back, so restore from backup instead.

A pull request that is not wanted yet: close it, and Renovate will not open it again for that
version. Put a note on why in the pull request.

Why Renovate, and what else was considered: [ADR 0008](../decisions/0008-renovate-for-dependency-updates.md).
