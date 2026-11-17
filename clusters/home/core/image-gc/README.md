# Image cleanup

Two things remove unused container images from the nodes: the kubelet on every node, by age, and the DaemonSet in
this folder, once a week.

## The kubelet, by age (every node, since 2026-11-17)

Each of the six nodes has a kubelet drop-in, `/var/lib/rancher/k3s/agent/etc/kubelet.conf.d/10-image-gc.conf` (root,
mode 600):

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
imageMaximumGCAge: 72h
```

- The kubelet removes an image that no container on the node has used for 72 hours. It never removes an image in use
  or a pinned one (the pause image).
- It waits 72 hours after its own start before it removes anything by age. A node that restarts more often than that
  is cleaned by the DaemonSet below, and by the kubelet's disk thresholds (85% and 80%, the defaults).
- `imageMaximumGCAge` is a field of the kubelet's configuration, not a kubelet flag, so it cannot go in `--kubelet-arg`.
  k3s starts the kubelet with `--config-dir` on that directory and rewrites only `00-k3s-defaults.conf` there at each
  start; the drop-in is read after it.
- Neither Flux nor k3s-ansible manages the file. A rebuilt node needs it again: write the file, then restart k3s on
  that node only. The service is `k3s` on a master, `k3s-node` on k3s-node-1 and k3s-node-2, and `k3s-agent` on
  k3s-node-3. Restarting k3s leaves the node's containers running. One node at a time.

Check a node from a workstation (it prints `72h0m0s`):

```sh
kubectl get --raw /api/v1/nodes/<node>/proxy/configz \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["kubeletconfig"]["imageMaximumGCAge"])'
```

## The DaemonSet `image-gc`, weekly

`daemonset.yaml`: on Sundays at 13:00 Asia/Manila each node removes every image that no container on it uses
(`crictl rmi --prune`, with the node's own crictl). It never prunes when it starts; the header of `daemonset.yaml` says
why.

An image removed either way is pulled again when a pod needs it, so a node's copy is the only source of an image
whose registry has stopped serving it. hoarder's chrome pod was stuck for four days from 2026-11-13: it moved to a node
with no copy of an image that `gcr.io/zenika-hub` no longer serves.

Once the kubelet's cleanup has been seen to work on its own, this DaemonSet can go: take `image-gc` out of
`../kustomization.yaml` and delete this folder's manifests, keeping this page.
