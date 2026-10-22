# Ansible

Configuration management for the hosts in the homelab. No code yet. This directory
is reserved for:

- Kubernetes nodes (two Lenovo ThinkCentre M720q and a Raspberry Pi 5): OS setup,
  container runtime, kubeadm and upgrades, so the cluster can be rebuilt from
  freshly installed machines
- The NAS (TrueNAS SCALE) and other hosts on Proxmox, where it makes sense

## Secrets

No secrets in plain text. Use Ansible Vault or SOPS. Vault password files
(`.vault_pass*`) are excluded by `.gitignore` and must never be committed.
