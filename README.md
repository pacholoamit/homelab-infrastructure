## Pre-requisites

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
cloudflared tunnel create homelab

# Create kubernetes secret
kubectl create secret generic tunnel-credentials --from-file=credentials.json=/Users/<USER>/.cloudflared/<UUID>.json
```

## Creating a new route

```
cloudflared tunnel route dns home-k3s-cluster longhorn.pacholoamit.com
```
