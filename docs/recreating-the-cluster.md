# Documentation on recreating the cluster after initial setup (WIP)

Ensure to follow the steps in [start-from-scratch.md](./start-from-scratch.md) before proceeding. You'll need to make sure all the sops secrets are generated and the cluster is bootstrapped with flux. Before recreating the cluster ensure you have a backup of the `age.agekey` file. This is needed to reapply the secrets.

```sh
cat age.agekey |
   kubectl create secret generic sops-age \
   --namespace=flux-system \
   --from-file=age.agekey=/dev/stdin
```


Point FluxCD to the repo
```sh

flux bootstrap github \
 --components-extra=image-reflector-controller,image-automation-controller \
 --owner=<YOUR_GITHUB_USERNAME> \
 --repository=homelab-infra \
 --branch=master \
 --path=clusters/home/base \
 --personal \
 --token-auth
```

Set up botkube at app.botkube.io for notifications