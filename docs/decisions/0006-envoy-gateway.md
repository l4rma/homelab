---
status: accepted
date: 2026-10-29 (written down 2026-11-16)
---

# Envoy Gateway (Gateway API) instead of ingress-nginx

## Context

All traffic came in through ingress-nginx ([0004](0004-ingress-nginx.md)), chosen knowing it
would be retired, so that the move to the Gateway API could be done on a running cluster. The
Kubernetes project stopped fixing ingress-nginx in March 2026 and points to the Gateway API as
the successor to Ingress. Some routes go to services outside the cluster with
self-signed certificates (Proxmox, TrueNAS, Omada), and the Gateway API's own
`BackendTLSPolicy` cannot skip certificate checks.

## Options

- **Keep ingress-nginx**: works today, but gets no security fixes.
- **Traefik**: popular and implements the Gateway API, but much of its value is in its own
  resources (`IngressRoute`), and the goal was to learn the standard API.
- **Cilium**: Gateway API built in, but it replaces the CNI (Flannel), which is a much larger
  change.
- **Istio**: a service mesh, far more than is needed here.
- **Envoy Gateway** (chosen): the Envoy project's Gateway API implementation.

## Decision

Chosen: Envoy Gateway, because it follows the Gateway API closely and adds what is missing
through its own extensions: `Backend` for services outside the cluster, with TLS that skips
verification for the self-signed ones.

## Consequences

- Good: routing uses the standard `Gateway` and `HTTPRoute`, with one wildcard certificate.
- Good: services on Proxmox get the same entry point and TLS as the apps in the cluster.
- Bad: `Backend` and the policies are Envoy Gateway's own resources, so changing the
  controller means rewriting those.
- Good: the migration itself was the learning goal of [0004](0004-ingress-nginx.md): every
  `Ingress` rewritten as an `HTTPRoute`, cert-manager moved to the Gateway, and the backends
  outside the cluster moved to `Backend`.
- Bad: Envoy's default route timeout is 15 seconds, which cuts websockets and long requests,
  so it is turned off for Home Assistant, Uptime Kuma, Proxmox and TrueNAS.
- Bad: the switch was done with downtime, in two pull requests (#40, #41): the Gateway API
  CRDs had to exist before Flux could apply the routes, and ingress-nginx had to free its
  MetalLB IP first.

## More information

[README: Architecture](../../README.md#architecture),
[Ingress NGINX retirement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/),
[Envoy Gateway docs](https://gateway.envoyproxy.io/docs/).
