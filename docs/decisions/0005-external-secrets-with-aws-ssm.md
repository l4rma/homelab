---
status: accepted
date: 2026-10-29 (written down 2026-11-16)
---

# Secrets in AWS SSM through External Secrets

## Context

Apps need passwords and keys, and everything else is in Git. The repository is public, so
whatever is in Git can be read by anyone, forever, also after it is deleted. Until then, the
few Secrets in the cluster were made by hand.

## Options

- **SOPS + age**: secrets encrypted in Git, and Flux decrypts them. Simple and built into
  Flux. But the encrypted files are public for good: if the age key ever leaks, every secret
  in the history leaks with it.
- **Sealed Secrets**: also encrypted in Git, with the same problem. The key is in the cluster,
  so rebuilding the cluster without a backup of it means sealing every secret again.
- **Vault or OpenBao in the cluster**: a real secrets server, but heavy for a homelab, and it
  needs storage, unsealing and its own backups. The cluster would hold the secrets it needs
  to start.
- **External Secrets + AWS SSM Parameter Store** (chosen): the secrets live in AWS, and Git
  only has the names.

## Decision

Chosen: External Secrets with AWS SSM, because no secret is in Git at all, not even
encrypted, and SSM is free at this size. AWS is already used for Route53.

## Consequences

- Good: nothing secret in the public repository, and a value is changed in one place.
- Good: rebuilding the cluster needs one AWS key, and every Secret comes back.
- Bad: that one key (and cert-manager's Route53 key) is made by hand. Until Terraform does it,
  it is documented in [secrets.md](../secrets.md).
- Bad: depends on AWS and the internet. If AWS cannot be reached, existing Secrets stay, but
  new or changed ones are not synced.
- Bad: reading SecureStrings is free up to 20 000 KMS requests a month, enough for about 25
  ExternalSecrets at `refreshInterval: 1h`.

## More information

[docs/secrets.md](../secrets.md).
