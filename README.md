# homelab

[![lint](https://github.com/l4rma/homelab/actions/workflows/lint.yml/badge.svg)](https://github.com/l4rma/homelab/actions/workflows/lint.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/l4rma/homelab/badge)](https://scorecard.dev/viewer/?uri=github.com/l4rma/homelab)

My homelab, as code. A bare-metal Kubernetes cluster managed with GitOps through Flux, a
Proxmox host for the services that stay outside it, and a TrueNAS for storage and backups.
Later also Terraform, Ansible, Crossplane and AWS.

The lab is where I learn platform engineering by doing it: I act as both the platform
team and the development team, follow the same practices I would at work, and write
about it on my blog at [magelssen.io/blog](https://magelssen.io/blog/k8s-part0/).

## Documentation

**<https://docs.magelssen.io/>**: the architecture, hardware, every service, how it is
run, and why each choice was made. The source is [`docs/`](docs/README.md) in this
repository.

## License and contributions

[MIT](LICENSE): copy whatever is useful. This is a personal lab, so pull requests from others
are not accepted, but issues and questions are welcome. To report a security problem, see
[SECURITY.md](SECURITY.md).
