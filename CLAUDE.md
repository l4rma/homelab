# homelab-k8s

GitOps-repo for homelab-Kubernetes-klusteret. Flux synker fra `main` i
`github.com/l4rma/homelab-k8s`. **Repoet er public.**

## Homelabben

- **Proxmox**: <!-- TODO: hvilke hoster/VM-er, hva kjører der -->
- **NAS**: <!-- TODO: modell/OS. Trolig 192.168.20.4 (jellyfin/radarr/sonarr/nextcloud/homarr peker dit) -->
- **Kubernetes**: kubeadm-cluster (static pods for etcd/apiserver), Kubernetes v1.36.1, containerd 2.2.1, Flannel CNI
- **GitOps**: Flux v2.7.5 (source, kustomize, helm, notification controllers; ikke image automation)
- **Senere**: Crossplane og AWS <!-- TODO: planer -->

Nettverk (VLAN-er, slik det ser ut fra repoet):
- `192.168.30.0/24`: k8s-noder. MetalLB-pool `192.168.30.200-240`, ingress-nginx på `192.168.30.200`
- `192.168.20.0/24`: NAS og tjenester utenfor klusteret
- `192.168.10.0/24`: <!-- TODO: pihole (192.168.10.4) og omada (192.168.10.24) ligger her -->

## Klusteret

| Node    | Rolle         | IP            | Arkitektur | OS               |
|---------|---------------|---------------|------------|------------------|
| lenovo1 | control-plane | 192.168.30.10 | amd64      | Ubuntu 24.04     |
| lenovo2 | worker        | 192.168.30.11 | amd64      | Ubuntu 24.04     |
| pi5     | worker        | 192.168.30.12 | arm64      | Ubuntu 24.04     |

Bruk multi-arch-images, siden pi5 er arm64. De fleste workloads havner på pi5 i dag.

Ingen StorageClass og ingen metrics-server (`kubectl top` virker ikke) per oktober 2026.

### Infrastruktur (Flux, `infrastructure/`)
- **cert-manager** v1.19.2: `ClusterIssuer letsencrypt-prod`, Route53 DNS-01 for `magelssen.io`
- **ingress-nginx** 4.15.1: LoadBalancer via MetalLB
- **metallb** 0.15.3: L2, pool `main-pool`
- **external-secrets** 1.3.1
- **claude-readonly**: ServiceAccount med lesetilgang for Claude Code

### Apper (Flux, `apps/`)
Alle har Ingress på `<navn>.magelssen.io` (homarr bruker `dashboard.magelssen.io`).
- **podinfo**: kjører i klusteret
- **homarr, jellyfin, nextcloud, omada, pihole, radarr, sonarr**: kjører *utenfor*
  klusteret. Repoet har bare `Service` + manuelle `Endpoints` + `Ingress` som
  ruter til eksterne IP-er.

### Kjører i klusteret, men styres ikke av Flux
Installert manuelt, så ikke endre disse ved å forvente at Flux tar dem:
- `monitoring`: kube-prometheus-stack (Prometheus, Alertmanager, Grafana)
- `uptime-kuma`, `kuma`
- `default`: home-assistant (hostNetwork på pi5), nginx

Planen er å flytte alle disse inn i Flux etter hvert.

## Struktur i repoet

```
clusters/homelab/          Flux-entrypoint (bootstrap-path)
  flux-system/             Generert av flux bootstrap. Ikke rediger.
  infrastructure.yaml      Flux Kustomization "infrastructure" -> ./infrastructure (60m)
  apps.yaml                Flux Kustomization "apps" -> ./apps (5m)
infrastructure/<komponent>/  namespace.yaml, helmrepository.yaml, helmrelease.yaml, kustomization.yaml
apps/<app>/                  namespace.yaml, service.yaml, ingress.yaml, kustomization.yaml
scripts/                     Hjelpescripts som kjøres lokalt
docs/                        Planer og notater
```

`infrastructure/` og `apps/` har **ingen** rot-`kustomization.yaml`. Flux genererer
en selv og tar med alle undermapper. En ny mappe med egen `kustomization.yaml`
synkes derfor automatisk, og ingen rotliste må oppdateres.

## Arbeidsregler for Claude

- Du har **kun lesetilgang** til klusteret (ServiceAccount `claude/claude-readonly`
  via `KUBECONFIG` i `.claude/settings.local.json`). Du kan ikke lese secrets.
- Alle endringer gjøres i repoet, **aldri direkte mot klusteret**. Ingen
  `kubectl apply/delete/patch/edit`, ingen `flux reconcile/suspend`.
- Lag en ny branch for endringer. Forklar hva du endrer og hvorfor.
- Ikke commit eller push uten at det er bedt om.
- Kjør `kustomize build <mappe>` (eller `kubectl kustomize <mappe>`) på det du
  endrer før du sier deg ferdig.
- Ingen hemmeligheter i klartekst. Repoet er public. Bruk external-secrets
  <!-- TODO: hvilken SecretStore/backend? --> eller SOPS for hemmeligheter.
  kubeconfig, tokens og age-nøkler skal aldri inn i Git.
- Følg eksisterende konvensjoner: én mappe per komponent, én fil per ressurstype.

## Feilsøking

Start med:
```sh
flux get all -A
kubectl get events -A --sort-by=.lastTimestamp
```
Uten `flux`-CLI: `kubectl get kustomizations,gitrepositories,helmreleases,helmrepositories -A`.

Deretter: `kubectl describe` på ressursen som feiler, og `flux logs` /
`kubectl logs -n flux-system deploy/kustomize-controller` (eller `helm-controller`).
