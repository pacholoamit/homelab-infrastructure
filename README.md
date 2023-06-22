## Pre-requisites

On the nodes ensure to install open-iscsi:

```
apt install open-iscsi
```

Create namespaces

```
kubectl create namespace ingress-nginx
kubectl create namespace longhorn-system
kubectl create namespace cloudflare

# Fixes volume errors
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

Install CLI Deps

```
brew install cloudflared
```

Create a tunnel

```
cloudflared tunnel login

cloudflared tunnel create homelab

# Create kubernetes secret
kubectl create secret generic tunnel-credentials --from-file=credentials.json=/Users/<USER>/.cloudflared/<UUID>.json
```

## Creating a new route

```
cloudflared tunnel route dns home-k3s-cluster longhorn.pacholoamit.com
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
