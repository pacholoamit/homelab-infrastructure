## Pre-requisites

On the nodes ensure to install open-iscsi:

```
# on all nodes with longhorn
apt install open-iscsi
apt install nfs-common
```

Create namespaces

```sh

kubectl create namespace ingress-nginx
kubectl create namespace longhorn-system
kubectl create namespace cloudflare
kubectl create namespace monitoring


```

MUST DO FOR ALL DEPLOYMENTS

```sh

# Fix longhorn volume errors
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Create credentials for Longhorn and Grafana

USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>;
echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth &&
echo -n ${USER} > ./admin-user &&
echo -n ${PASSWORD} > ./admin-password &&
kubectl -n longhorn-system create secret generic basic-auth --from-file=auth &&
kubectl create secret generic grafana-admin-credentials --from-file=./admin-user --from-file=admin-password -n monitoring &&
rm -rf ./admin-user ./admin-password auth

# Create Cloudflare secret
kubectl create secret generic tunnel-credentials --from-file=credentials.json=/Users/<USER>/.cloudflared/<UUID>.json

```

Install CLI Deps

```sh

brew install cloudflared

```

Create a tunnel

```sh

cloudflared tunnel login

cloudflared tunnel create home-k3s-cluster

```

Create the routes

```sh

cloudflared tunnel route dns home-k3s-cluster longhorn.pacholoamit.com
cloudflared tunnel route dns home-k3s-cluster vaultwarden.pacholoamit.com
cloudflared tunnel route dns home-k3s-cluster grafana.pacholoamit.com
```

## Reprovisioning new cluster

```sh

flux bootstrap github \
 --components-extra=image-reflector-controller,image-automation-controller \
 --owner=pacholoamit \
 --repository=homelab-infra \
 --branch=master \
 --path=clusters/home \
 --personal \
 --token-auth

```
