## Upgrading the Kubernetes cluster

We use the Rancher [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) to perform upgrades of the Kubernetes cluster.
The upgrade manifests are located in ./upgrades. To apply the upgrades, run the following command:

```bash
kubectl apply -f ./upgrades/<manifest>.yaml
```