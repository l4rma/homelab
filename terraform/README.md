# Terraform

Infrastructure as code for the parts of the homelab that live outside Kubernetes.
No code yet. This directory is reserved for:

- `proxmox/`: VMs and LXC containers on Proxmox VE (first target)
- AWS resources later, for example Route53, S3 for backups and RDS

## State

State is never committed to Git. It can contain secrets and IP addresses, and this
repository is public. `.gitignore` excludes `*.tfstate`, `*.tfstate.*`, `.terraform/`
and variable files (`*.tfvars`, `*.auto.tfvars`).

<!-- TODO: choose a remote backend, for example S3 with state locking -->

`.terraform.lock.hcl` is committed so that provider versions are pinned.

## Secrets

Credentials such as Proxmox API tokens and AWS keys are passed as environment
variables or through a secrets manager, never in `.tf` or `.tfvars` files in Git.
