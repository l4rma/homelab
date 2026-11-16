---
status: accepted
date: 2026-11-15
---

# Renovate for dependency updates

## Context

Versions are pinned everywhere: Helm charts, images, Flux itself, GitHub Actions (by SHA) and
pre-commit hooks. They were checked by hand once a month against `docs/versions.md`, which
was slow and easy to forget. A tool should notice new versions and open pull requests.

## Options

- **Dependabot**: built into GitHub, but has no Flux support (HelmReleases and the Flux
  components are not updated), and Kubernetes images need one entry per directory.
- **Flux image automation**: runs in the cluster and commits new image tags. Only images, and
  it needs write access to the repository.
- **Updatecli**: flexible, but every dependency needs a hand-written rule.
- **Renovate** (chosen): understands Flux, Kubernetes manifests, SHA-pinned actions and
  pre-commit, with grouping, schedules and a minimum release age built in.

## Decision

Chosen: Renovate, as the hosted Mend Renovate app, because it covers almost everything pinned
in the repository and needs nothing running in the homelab.

## Consequences

- Good: new versions show up as pull requests on Monday mornings, with release notes.
- Good: a version must be 14 days old first, which avoids most broken or hijacked releases.
- Bad: a third-party app with write access to the repository. It is installed on this
  repository only, and every pull request still needs a human to merge it.
- Bad: what is not in Git (Proxmox, TrueNAS, kubeadm, the node OS) is still checked by hand in
  `docs/versions.md`.

## More information

[docs/dependencies.md](../dependencies.md), with the full comparison.
