---
status: accepted
date: 2026-11-17
---

# Alerts from Alertmanager to Telegram, and Uptime Kuma moved to Proxmox

## Context

Prometheus and Alertmanager run in the cluster (kube-prometheus-stack), with the chart's default
alert rules, but Alertmanager has no receiver: alerts fire and nobody is told. On 2026-11-17 all
sites were down for 29 minutes while every pod was healthy and Flux was green. It was found by
chance.

Uptime Kuma also runs in the cluster, and it showed no downtime. From a pod, kube-proxy sends
traffic for a LoadBalancer IP straight to the backend pod (the Service has `ipMode: VIP`). The
check never asks the network who has 192.168.30.200, so it skips MetalLB, which is the part that
broke. Anything in the cluster also goes down with the cluster, so it cannot report that.

Three things need deciding: what evaluates the rules and sends the alerts, how they reach me, and
what checks the services the way a user reaches them and notices when the alerting itself is down.
Monitoring stays at home: no outside service watches the homelab. Only the delivery of the message
leaves it.

## Options

What evaluates and sends:

- **Grafana alerting**: rules made in the UI, kept in Grafana's database unless provisioned from
  files. It would duplicate the rules Prometheus already has.
- **Netdata, Zabbix, Checkmk**: a second monitoring system next to Prometheus.
- **Prometheus rules and Alertmanager** (chosen): already installed. Rules are `PrometheusRule`
  objects in Git, reviewed in pull requests like everything else.

How alerts reach me:

- **SMS** (AWS SNS or Twilio): works without data, but costs per message, needs sender setup, and
  the messages are short and plain.
- **Pushover**: good priorities and acknowledgement, but a paid app for one person's alerts.
- **ntfy, self-hosted**: free, but if it runs in the cluster it goes down with the cluster.
- **Telegram for alerts, Gmail for the rest** (chosen): Alertmanager supports both natively,
  both are free, and Telegram is already on the phone. Alerts can arrive at any time; the phone's
  night mode decides when they make a sound.

What checks from the user's side, and watches the watcher:

- **An outside service** (healthchecks.io, UptimeRobot): rejected, monitoring stays at home. It
  also cannot reach the private addresses.
- **Keep Uptime Kuma in the cluster and change kube-proxy** so pods do not take the shortcut:
  kube-proxy has no setting for it, the change would affect every pod that calls a
  `*.magelssen.io` address, kube-proxy's config is a kubeadm ConfigMap outside Git, and Uptime Kuma
  would still die with the cluster.
- **Uptime Kuma in both places**: two sets of monitors to keep in step, for little gain.
- **Move Uptime Kuma to an LXC on Proxmox** (chosen): Proxmox is separate hardware from the cluster
  ([ADR 0001](0001-bare-metal-kubernetes-nodes.md)). It reaches the services like a browser on the
  LAN does, through MetalLB, and it keeps running when the cluster does not.

## Decision

- **Prometheus rules and Alertmanager** decide what to alert on. Grafana is for dashboards only.
- **Two severities:**
  - `critical` goes to Telegram. It is something that is down or about to break: a site, DNS or a
    node down, a disk, PVC or pool almost full, a degraded pool, no node announcing the gateway IP,
    or the cluster gone silent.
  - `warning` goes to Gmail. It needs a look the same day: a pod crashlooping, a failed Flux
    reconcile, a missed backup, a certificate that did not renew, a container near its memory limit.
- **Not alerted:** CPU and memory usage on their own, and short spikes. They stay on the dashboards.
- **The bot token and the Gmail app password** are stored in SSM and read through External Secrets
  ([ADR 0005](0005-external-secrets-with-aws-ssm.md)).
- **MetalLB's metrics go into Prometheus**, with an alert when no node announces 192.168.30.200
  (`metallb_speaker_announced`). That is the 2026-11-17 failure, seen from inside the cluster.
- **Uptime Kuma moves from the cluster to an LXC on Proxmox**, and the copy in the cluster is
  removed:
  - It checks the sites, DNS, Proxmox, TrueNAS and the nodes from the LAN.
  - It receives Alertmanager's always-firing `Watchdog` alert as a heartbeat. When the heartbeat
    stops, Alertmanager or the cluster is down.
  - It sends to the same Telegram chat.
  - Prometheus checks the LXC back, so each side notices when the other is down.
- **TrueNAS and Proxmox** use their own notifications (TrueNAS alert services, Proxmox notification
  targets) to the same Telegram chat and Gmail. They are not in Prometheus.

## Consequences

- Good: every alert rule is in Git, and a change to an alert is a pull request.
- Good: the 2026-11-17 outage would have been sent to Telegram within a few minutes, both from
  Prometheus (MetalLB) and from Uptime Kuma.
- Good: free, and nothing outside the homelab watches it.
- Good: Uptime Kuma's SQLite database moves off NFS and onto the LXC's local disk
  ([docs/architecture/storage.md](../architecture/storage.md) says SQLite does not belong on NFS).
- Bad: if the internet connection or the Proxmox host is down, nothing can send an alert. I accept
  that, because nothing else works then either.
- Bad: delivery depends on Telegram and Google. A Telegram outage means only the Gmail warnings
  arrive.
- Bad: Uptime Kuma leaves GitOps. The LXC is made by hand until Proxmox is managed with Terraform
  (#104), its version is tracked in `docs/operations/versions.md`, and its setup is written down in `docs/`.
  Its monitors live in its own database, as they do today.
- Bad: the chart's default rules include some that are noisy on a kubeadm cluster. Each one is
  turned off in Git, with the reason next to it.

## More information

[Alertmanager configuration](https://prometheus.io/docs/alerting/latest/configuration/)
(`telegram_configs`, `email_configs`), [Uptime Kuma](https://github.com/louislam/uptime-kuma),
[Proxmox notifications](https://pve.proxmox.com/pve-docs/chapter-notifications.html),
[MetalLB Prometheus metrics](https://metallb.universe.tf/prometheus-metrics/),
[Service `ipMode`](https://kubernetes.io/docs/concepts/services-networking/service/#load-balancer-ip-mode).
The incident that led to this: Envoy moved to lenovo1, fixed in #124.
