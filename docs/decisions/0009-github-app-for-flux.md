---
status: accepted
date: 2026-11-15
---

# A GitHub App for Flux's commit statuses

## Context

Flux posts a commit status to GitHub for each commit it applies, so GitHub shows what actually
runs in the cluster. For that, the cluster needs a login to GitHub that can write commit
statuses. The repository is public, and the login is stored in the cluster.

## Options

- **Classic personal access token**: the `repo` scope gives full access to all my
  repositories. Far too much.
- **Fine-grained personal access token**: can be limited to commit statuses on one
  repository. But it belongs to my account, the statuses show up as me, and it has to be
  renewed when it expires.
- **Deploy key**: SSH access to Git only. It cannot post statuses.
- **GitHub App** (chosen): its own identity, installed on this repository only, with the one
  permission it needs.

## Decision

Chosen: a GitHub App (`larma-homelab-flux`), because it has the least access, is not tied to
my account, and shows up as its own bot. Flux supports App logins directly.

## Consequences

- Good: only "Commit statuses: read and write" on `l4rma/homelab`. A leaked key cannot read or
  change code.
- Good: the private key does not expire, and Flux gets short-lived tokens from it.
- Bad: more setup steps than a token. They are written down in
  [github.md](../development/github.md#deployment-status).
- Bad: the private key is long-lived, so it must stay in SSM only. It can be rotated in the
  App settings.

## More information

[docs/development/github.md: Deployment status](../development/github.md#deployment-status),
[Flux GitHub provider](https://fluxcd.io/flux/components/notification/providers/#github).
