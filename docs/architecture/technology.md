# Technology choices

What is used, and why in a sentence or two. The larger choices, with the options that were
rejected, are written down as [decision records](../decisions/README.md).

| Technology | Why |
|---|---|
| Proxmox VE | Runs the NAS and the services that are not in Kubernetes yet, separate from the cluster. A full hypervisor with LXCs, backups and an API, with TrueNAS in a VM ([ADR 0002](../decisions/0002-truenas-as-a-vm-on-proxmox.md)). |
| Bare-metal nodes | Keeps the NAS, the hypervisor and the cluster on separate machines, so one can be rebuilt without touching the others ([ADR 0001](../decisions/0001-bare-metal-kubernetes-nodes.md)). |
| kubeadm | Upstream Kubernetes with no abstractions on top, which is good practice for the Kubernetes certifications. The cluster started on v1.33 and has been upgraded to v1.36 by hand. |
| Flannel | Simple CNI that just works. The trade-off is no NetworkPolicy support, which I may revisit. |
| Flux | Pull-based GitOps: the cluster pulls from Git, so nothing outside needs access to the cluster. No GUI, which forces me to understand Kubernetes properly. It is also what I use at work ([ADR 0003](../decisions/0003-flux-for-gitops.md)). |
| MetalLB + Envoy Gateway | LoadBalancer IPs on bare metal, and the Gateway API (the successor to Ingress) for routing. Replaced ingress-nginx, which was retired upstream ([ADR 0004](../decisions/0004-ingress-nginx.md), [ADR 0006](../decisions/0006-envoy-gateway.md)). |
| cert-manager + Route53 | Real Let's Encrypt certificates through DNS-01, which works without exposing the cluster to the internet. |
| External Secrets + AWS SSM | The repo is public, so no secret is stored in Git, not even encrypted. Secrets live in SSM Parameter Store (free tier) and are copied into the cluster. See [secrets](../cluster/secrets.md) and [ADR 0005](../decisions/0005-external-secrets-with-aws-ssm.md). |
| kube-prometheus-stack | Prometheus, Grafana and Alertmanager in one chart, with dashboards for the cluster out of the box. Also the data for sizing resource requests. Alertmanager sends alerts to Telegram and Gmail. Uptime Kuma runs in an LXC on Proxmox, outside the cluster, so it sees the services as a user does ([ADR 0011](../decisions/0011-alerting-with-alertmanager-and-telegram.md), [Uptime Kuma](../services/uptime-kuma.md)). |
| local-path + NFS | Databases on the node's own disk, files on the NAS over NFS. Databases on NFS are slow and corrupt easily. The reasoning: [storage](storage.md). |
| CloudNativePG | Postgres as a Kubernetes operator: one small cluster per app, with failover and backups to S3 later. |
| gluetun | VPN as a sidecar for qBittorrent only. Its firewall is the kill switch, and the rest of the media stack stays outside the VPN. |
| Hugo + GitHub Pages | The docs as a website, built from the same Markdown files that GitHub and Claude read, so there is only one copy. Published from `main`, and stays up when the homelab is down ([ADR 0015](../decisions/0015-hugo-for-the-docs-website.md)). |
| Terraform (planned) | Proxmox VMs and LXCs, and later AWS, as code. |
| Ansible (planned) | Configure nodes and rebuild the cluster from freshly installed machines. |
| Crossplane + AWS (planned) | Provision cloud resources from Kubernetes. |
