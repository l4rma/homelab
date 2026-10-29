# Kubernetes nodes

Node settings that live outside Git: kubelet configuration and taints. They were set by
hand in October 2026 and must be repeated on a new or reinstalled node. Later this moves
to Ansible.

| Node | Role | CPU | RAM | Disk | Allocatable for pods |
|---|---|---|---|---|---|
| `lenovo1` | control plane, also runs workloads | 6 cores | 8 GB | ~100 GB | 5500m CPU, ~6.3 GiB |
| `lenovo2` | worker | 6 cores | 8 GB | ~200 GB | 5500m CPU, ~6.3 GiB |
| `pi5` | worker (arm64) | 4 cores | 8 GB | ~480 GB | 3500m CPU, ~6.5 GiB |

## Kubelet reservations

Set in the kubeadm ConfigMap `kube-system/kubelet-config`, so all nodes get the same
values:

```yaml
systemReserved:        # OS, sshd, containerd
  cpu: 250m
  memory: 512Mi
kubeReserved:          # kubelet
  cpu: 250m
  memory: 512Mi
evictionHard:
  memory.available: 300Mi   # default is 100Mi
  nodefs.available: 10%     # the rest are the kubelet defaults, written out
  nodefs.inodesFree: 5%
  imagefs.available: 15%
  imagefs.inodesFree: 5%
```

Why:

- The scheduler places pods by their requests against each node's *allocatable*. Without
  reservations, allocatable is almost all RAM, so the scheduler can fill a node past what
  the OS and Kubernetes components need themselves.
- A higher eviction threshold gives the kubelet room to evict a pod cleanly before the
  kernel OOM killer kills a random process. On `lenovo1` that process can be etcd or the
  apiserver.
- Reservations only help scheduling when pods have resource requests.

### Changing the values

With kubeadm the ConfigMap is the source of truth. `kubeadm upgrade` rewrites each node's
`/var/lib/kubelet/config.yaml` from it, so a hand edit on a node is lost. See
"Reconfiguring a kubeadm cluster" in the Kubernetes docs.

1. `kubectl -n kube-system edit cm kubelet-config` (back it up first with `get -o yaml`).
2. On each node, one at a time, workers first and `lenovo1` last:

   ```
   sudo cp /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.bak-<date>
   sudo kubeadm upgrade node phase kubelet-config
   sudo diff /var/lib/kubelet/config.yaml.bak-<date> /var/lib/kubelet/config.yaml
   sudo systemctl restart kubelet
   ```

   The diff must show only the intended change. A kubelet restart does not stop running
   containers, including the control plane static pods.
3. Check `kubectl get node <node> -o jsonpath='{.status.allocatable}'`.

Rollback on a node: copy the backup back and restart the kubelet.

A new node that joins with `kubeadm join` gets the ConfigMap values automatically.

## Taints

`lenovo1` is the only control plane, and its `node-role.kubernetes.io/control-plane:NoSchedule`
taint was removed so it can run workloads. Without it, only `lenovo2` would be left for
amd64 and iGPU workloads (Immich, Jellyfin). The kubelet reservations above are what make
sharing the node with etcd safe.

```
kubectl taint nodes lenovo1 node-role.kubernetes.io/control-plane:NoSchedule-
```

A reinstall with `kubeadm init` adds the taint again. Check `kubectl get node lenovo1 -o
jsonpath='{.spec.taints}'` after each `kubeadm upgrade` too.
