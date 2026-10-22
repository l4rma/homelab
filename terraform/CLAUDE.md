# terraform/

General rules are in the root `CLAUDE.md`. See `README.md` in this directory for scope.

- Never run `terraform apply`, `terraform destroy`, `terraform import`,
  `terraform state` subcommands that modify state, or anything else that changes
  infrastructure or state. A human runs those.
- Allowed: `terraform fmt`, `terraform validate` and `terraform plan`. Show the plan
  output and explain it.
- State never goes in Git, and neither do `.tfvars` files or credentials.
  `.terraform.lock.hcl` is committed.
- Pin provider and module versions.
