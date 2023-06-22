## Pre-requisites

On the nodes ensure to install open-iscsi:

```
# on all nodes with longhorn
apt install open-iscsi
apt install nfs-common
```

```

Create namespaces

```

kubectl create namespace ingress-nginx
kubectl create namespace longhorn-system
kubectl create namespace cloudflare
kubectl create namespace kasten-io

```

Fixes volume errors

```

kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

```

Set up K10

```

kubectl annotate volumesnapshotclass \
(kubectl get volumesnapshotclass -o=jsonpath='{.items[?(@.metadata.annotations.snapshot\.storage\.kubernetes\.io\/is-default-class=="true")].metadata.name}') \
 k10.kasten.io/is-snapshot-class=true

```

Create longhorn secret

```

USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
kubectl -n longhorn-system create secret generic basic-auth --from-file=auth

```

Install CLI Deps

```

brew install cloudflared

```

Create a tunnel

```

cloudflared tunnel login

cloudflared tunnel create home-k3s-cluster

# Create kubernetes secret

kubectl create secret generic tunnel-credentials --from-file=credentials.json=/Users/<USER>/.cloudflared/<UUID>.json

```

Create the routes

```

cloudflared tunnel route dns home-k3s-cluster longhorn.pacholoamit.com
cloudflared tunnel route dns home-k3s-cluster vaultwarden.pacholoamit.com

```

## Reprovisioning new cluster

```

flux bootstrap github \
 --components-extra=image-reflector-controller,image-automation-controller \
 --owner=pacholoamit \
 --repository=homelab-infra \
 --branch=master \
 --path=clusters/home \
 --personal \
 --token-auth

```

```
