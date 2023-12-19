# Documentation on recreating the cluster after initial setup (WIP)

Ensure to follow the steps in [start-from-scratch.md](./start-from-scratch.md) before proceeding. You'll need to make sure all the sops secrets are generated and the cluster is bootstrapped with flux. Before recreating the cluster ensure you have a backup of the `age.agekey` file. This is needed to reapply the secrets.

```sh
cat age.agekey |
   kubectl create secret generic sops-age \
   --namespace=flux-system \
   --from-file=age.agekey=/dev/stdin
```