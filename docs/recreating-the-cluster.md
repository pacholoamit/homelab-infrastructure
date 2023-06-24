# Documentation on recreating the cluster after initial setup (WIP)

Ensure to follow the steps in [start-from-scratch.md](./start-from-scratch.md) before proceeding. You'll need to make sure all the sealed-secrets are generated and the cluster is bootstrapped with flux. Before recreating the cluster ensure you have a backup of the `sealed-secret-backup.key` file. This is needed to reapply the secrets.

```sh
kubectl get secret -n flux-system sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secret-backup.key
```

Reapplying secrets, if `sealed-secret-backup.key` (yaml) file is present in the root directory. To get the `sealed-secret-backup.key`

```sh
kubectl apply -f sealed-secret-backup.key
kubectl -n flux-system rollout restart deployment sealed-secrets-controller
```
