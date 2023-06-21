## Pre-requisites

```
kubectl create namespace ingress-nginx
kubectl create namespace longhorn-system
kubectl create namespace cloudflare
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
