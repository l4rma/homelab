# Migrating from ingress-nginx to NGINX Gateway Fabric (Gateway API)

Plan for migrating this cluster from ingress-nginx (`Ingress` resources) to
NGINX Gateway Fabric (Gateway API: `Gateway` + `HTTPRoute`). Old and new
stacks run side by side the whole time — nothing is cut over until Phase 5,
and ingress-nginx isn't removed until Phase 6.

TLS approach chosen: a single wildcard listener/cert for `*.magelssen.io`
instead of one listener+cert per host. Since the existing `ClusterIssuer
letsencrypt-prod` already does Route53 DNS-01 for the whole zone, this works
today and means new apps need zero new TLS config going forward — just an
`HTTPRoute`.

## Phase 0 — Current state

- ingress-nginx (HelmRelease, LoadBalancer via MetalLB pool
  `192.168.30.200-240`)
- cert-manager v1.19.2, `ClusterIssuer letsencrypt-prod` doing Route53 DNS-01
  for the whole `magelssen.io` zone
- 8 apps (podinfo, nextcloud, homarr, pihole, omada, jellyfin, sonarr,
  radarr), each with its own `Ingress` + per-host `Certificate`

## Phase 1 — Install Gateway API CRDs

NGINX Gateway Fabric (NGF) ships its own version-matched fork of the CRDs,
so pin to that instead of fetching upstream separately. Flux's
kustomize-controller supports remote bases natively (same trick already
works for this repo's `apps/` and `infrastructure/` dirs without a root
`kustomization.yaml`).

`infrastructure/gateway-api-crds/kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.6.7
```

Verify: `kubectl get crd | grep gateway.networking.k8s.io`

## Phase 2 — Install NGINX Gateway Fabric

Mirror the existing `infrastructure/ingress-nginx/` layout.

`infrastructure/nginx-gateway-fabric/namespace.yaml` — namespace
`nginx-gateway`

`infrastructure/nginx-gateway-fabric/helmrepository.yaml`
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: nginx-gateway-fabric
  namespace: flux-system
spec:
  type: oci
  interval: 1h
  url: oci://ghcr.io/nginx/charts
```

`infrastructure/nginx-gateway-fabric/helmrelease.yaml`
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: nginx-gateway-fabric
  namespace: nginx-gateway
spec:
  interval: 30m
  chart:
    spec:
      chart: nginx-gateway-fabric
      sourceRef:
        kind: HelmRepository
        name: nginx-gateway-fabric
        namespace: flux-system
```

Plus a `kustomization.yaml` listing all three, same style as the other
`infrastructure/*` dirs.

This installs the control plane + a `GatewayClass` (default name `nginx`)
but **not** a data-plane LoadBalancer yet — that only appears once a
`Gateway` resource is created.

## Phase 3 — Enable cert-manager for Gateway API

Edit `infrastructure/cert-manager/helmrelease.yaml`, add under `values`:
```yaml
    config:
      gatewayAPI:
        enabled: true
```

Works from cert-manager v1.15+ (no feature flag needed), so v1.19.2 is
fine. Flux will roll the cert-manager pod on the next reconcile.

## Phase 4 — Create the Gateway (wildcard listener)

New file, e.g. `infrastructure/nginx-gateway-fabric/gateway.yaml`:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main
  namespace: nginx-gateway
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  gatewayClassName: nginx
  listeners:
    - name: https
      hostname: "*.magelssen.io"
      port: 443
      protocol: HTTPS
      tls:
        mode: Terminate
        certificateRefs:
          - name: magelssen-io-tls
      allowedRoutes:
        namespaces:
          from: All
```

Creating this triggers three things automatically:

- cert-manager issues a wildcard `Certificate`/`magelssen-io-tls` secret via
  DNS-01 (same existing `ClusterIssuer`, no new issuer needed)
- NGF spins up a data-plane `Service` of `type: LoadBalancer`
- MetalLB hands it a **new, different** IP from the pool — this is what
  gives us "run both controllers in parallel on different external IPs"
  for free, matching the official migration guide's recommendation

Verify: `kubectl get certificate -n nginx-gateway` and
`kubectl get svc -n nginx-gateway` (note the new LB IP).

## Phase 5 — Convert Ingress → HTTPRoute, one app at a time

For each app, add `httproute.yaml` next to the existing `ingress.yaml`
(don't delete the Ingress yet) and add it to that app's
`kustomization.yaml`. Example for podinfo (start with the lowest-stakes
app):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: podinfo
spec:
  parentRefs:
    - name: main
      namespace: nginx-gateway
      sectionName: https
  hostnames:
    - podinfo.magelssen.io
  rules:
    - backendRefs:
        - name: podinfo
          port: 80
```

This is a mechanical 1:1 translation for 7 of the 8 apps (host + backend
Service/port, nothing else). Optionally use
[`ingress2gateway`](https://github.com/kubernetes-sigs/ingress2gateway)
(`ingress2gateway print --providers=ingress-nginx`) to auto-draft these,
but at this scale hand-writing is probably faster than installing/learning
the tool.

Test each one **before touching DNS**, against the new Gateway's IP
directly:
```
curl --resolve podinfo.magelssen.io:443:<NGF-LB-IP> https://podinfo.magelssen.io -v
```

Once that returns a valid cert + correct response: flip that host's
Pi-hole Local DNS Record to the NGF IP, confirm in a browser, then delete
that app's old `ingress.yaml`.

### Exception: nextcloud

Its Ingress has `nginx.ingress.kubernetes.io/backend-protocol: HTTPS` and
`proxy-ssl-verify: off` — talking HTTPS with no verification to the
backend. Gateway API core has no equivalent; options are NGF's own
backend-TLS policy CRD (check NGF docs for `BackendTLSPolicy`/`NginxProxy`
support) or testing whether nextcloud still needs this once proxied
through NGF. Treat this as its own research spike — do it last, and leave
nextcloud on ingress-nginx until it's sorted.

## Phase 6 — Decommission ingress-nginx

Once all 8 HTTPRoutes are verified and DNS is cut over:

- Delete all `apps/*/ingress.yaml`
- Delete `infrastructure/ingress-nginx/`
- MetalLB reclaims its old IP automatically

## Reference docs

- [Gateway API: Migrating from Ingress-NGINX](https://gateway-api.sigs.k8s.io/guides/getting-started/migrating-from-ingress-nginx/)
- [NGINX Gateway Fabric install (Helm)](https://docs.nginx.com/nginx-gateway-fabric/install/helm/)
- [cert-manager + Gateway API](https://cert-manager.io/docs/usage/gateway/)
- [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway)
