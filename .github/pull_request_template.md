## What and why

<!-- What changes, and why. Link the issue: "Closes #123". -->

## How it was verified

<!-- kubectl kustomize, a check in the cluster after the merge, a restore test ... -->

## Manual steps

<!-- Anything done by hand before or after the merge (TrueNAS, Proxmox, AWS, Pi-hole). "None" if none. -->

## Rollback

<!-- Usually "git revert". Say so if it is not enough, for example after a data migration. -->

## Checklist

- [ ] No secrets in the diff
- [ ] Image and chart versions pinned, and `docs/versions.md` updated if a version changed
- [ ] Docs updated (README, `docs/`, `CLAUDE.md`)
