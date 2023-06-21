## Pre-requisites

```
kubectl create namespace ingress-nginx
kubectl create namespace longhorn-system
kubectl create namespace cloudflare
```

Install CLI Deps

```
brew install kubeseal
brew install cloudflared
```

Create a tunnel

```
cloudflared tunnel create homelab
# Copy the secrets at /Users/<USER>/.cloudflared/<UUID>.json
```
