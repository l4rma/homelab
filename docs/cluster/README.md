# Kubernetes cluster

A bare-metal cluster built with kubeadm, with three nodes: two Lenovo ThinkCentre M720q
and a Raspberry Pi 5 ([hardware](../architecture/hardware.md)). Everything in it is managed
by Flux from [`kubernetes/`](../../kubernetes/) in the repository. What is installed, and
how that directory is laid out: [kubernetes/README.md](../../kubernetes/README.md).

## GitOps flow

1. A change is made on a branch and opened as a pull request.
2. After review, the pull request is merged to `main`.
3. Flux's `GitRepository` polls `main` every minute and fetches the new revision.
4. The `flux-system` Kustomization applies `kubernetes/clusters/homelab`, which
   defines the other Kustomizations.
5. `infrastructure` applies `kubernetes/infrastructure` (gateway, certificates,
   load balancing, secrets operator). `apps` applies `kubernetes/apps` once
   `infrastructure` is applied and healthy. Both wait until what they applied is running
   (`wait: true`), and report a failure after 10 minutes.
6. Flux uses server-side apply and prunes resources that were removed from Git.
   Rolling back is a `git revert`.

The goal is that nothing is applied to the cluster by hand. Every workload is in Git.
What is still done by hand: the two bootstrap AWS keys (cert-manager's Route53 key and
the key external-secrets uses to read SSM, see [secrets](secrets.md)) and the kubelet
settings on the nodes ([nodes](nodes.md)), until Terraform and Ansible take over.

## In this section

- [Nodes](nodes.md): packages, kubelet reservations and taints on each node.
- [Secrets](secrets.md): how secrets get from AWS SSM into the cluster.
