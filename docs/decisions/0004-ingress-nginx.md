---
status: superseded by [0006](0006-envoy-gateway.md)
date: 2026-01-19 (written down 2026-11-16)
---

# ingress-nginx for traffic into the cluster

## Context

The apps in the cluster needed to be reached over HTTPS by name, through one IP from MetalLB.
The standard way was an `Ingress` resource and an ingress controller. In November 2025 the
Kubernetes project had announced that ingress-nginx would be retired in March 2026, and
pointed to the Gateway API as the successor.

## Options

- **Gateway API from the start** (Envoy Gateway or another controller): the future, but
  skips the API that most clusters, charts and guides still use.
- **Traefik with Ingress**: also common, but adds its own resources on top.
- **ingress-nginx** (chosen): the most used ingress controller, with `Ingress` resources.

## Decision

Chosen: ingress-nginx, on purpose, although it was going to be retired: to get experience
with the `Ingress` API that most clusters still run, and then with moving a running cluster
from Ingress to the Gateway API, which many teams have to do now.

## Consequences

- Good: experience with both APIs and with the migration itself (see
  [0006](0006-envoy-gateway.md)).
- Good: the Helm chart and the Ingresses were simple to set up, and most charts support
  `Ingress` out of the box.
- Bad: no security fixes after March 2026, so it had to be replaced before then or soon
  after.
- Bad: services outside the cluster (Proxmox, TrueNAS, Omada) needed a `Service` with
  hand-written `Endpoints` and nginx annotations for self-signed HTTPS backends.

## More information

[Ingress NGINX retirement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/).
Replaced in October 2026 (#40, #41).
