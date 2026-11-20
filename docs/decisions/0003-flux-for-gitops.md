---
status: accepted
date: 2026-01-18
---

# Flux for GitOps, not Argo CD

## Context

Everything in the cluster should come from Git, applied by a controller in the cluster, so
nothing is applied by hand and every change has a commit. The two big GitOps tools are Flux
and Argo CD. Both are CNCF graduated projects and both pull from Git.

## Options

- **Argo CD**: a web UI that shows every app, its resources and the diff to Git, with
  single sign-on and buttons to sync and roll back. More to run (API server, repo server,
  Redis, Dex), and the UI makes it easy to change things outside Git. Helm charts are
  rendered with `helm template`, so they are not real Helm releases.
- **Flux** (chosen): a set of small controllers configured only with Kubernetes resources
  (`GitRepository`, `Kustomization`, `HelmRelease`). No UI. Helm charts are installed as real
  Helm releases by helm-controller.

## Decision

Chosen: Flux, because the lack of a UI means working through `kubectl`, `flux` and the
manifests, which is the point of the lab, and because Flux is what I use at work.

## Consequences

- Good: small and fully declarative. Flux manages itself from the same repository
  (`kubernetes/clusters/homelab/flux-system/`).
- Bad: no overview in a browser. The state is read with `flux get` and `kubectl`, and the
  commit statuses on GitHub.
- Bad: the order between Kustomizations (`dependsOn`) and health checks must be set up by
  hand. Today `apps` waits for `infrastructure`, but without health checks.

## More information

[GitOps flow](../cluster/README.md#gitops-flow), [Flux docs](https://fluxcd.io/flux/).
