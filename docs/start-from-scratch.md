# Documentation on starting from scratch (WIP)

Below are the required commands to start from scratch. Make sure you fork the repo and change the paths accordingly.

## Bootstrapping with flux

Install the flux CLI tool and run the following command. You will need to generate a GitHub token with repo access.

```sh

flux bootstrap github \
 --components-extra=image-reflector-controller,image-automation-controller \
 --owner=<YOUR_GITHUB_USERNAME> \
 --repository=homelab-infra \
 --branch=master \
 --path=clusters/home \
 --personal \
 --token-auth
```

## Preparing Longhorn RWX compatibility,

ensure to install open-iscsi on all nodes worker nodes with longhorn installed.

```sh
apt install open-iscsi
apt install nfs-common
```

## Preparing cloudflare tunnels

We are using [Cloudflared](https://github.com/cloudflare/cloudflared) to route traffic to our cluster. Install the cloudflared CLI tool and run the following commands.

```sh
cloudflared tunnel login

# Keep in mind the filepath after this command, we will be generating a sealed secret with it and mounting it to the cloudflared pod
cloudflared tunnel create home-k3s-cluster

```

Then create the routes:

```sh
cloudflared tunnel route dns home-k3s-cluster longhorn.pacholoamit.com
cloudflared tunnel route dns home-k3s-cluster vaultwarden.pacholoamit.com
cloudflared tunnel route dns home-k3s-cluster grafana.pacholoamit.com
```

## Preparing secrets

We're using sealed-secrets to encrypt our secrets. Install the kubeseal CLI tool and run the following commands.

```sh
# Create secret for longhorn
USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>;
echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth &&
kubectl -n longhorn-system create secret generic basic-auth --from-file=auth --dry-run=client -o yaml > auth.yaml &&

# Seal secret
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
< auth.yaml > secret.yaml

mv secret.yaml infrastructure/longhorn/secret.yaml

rm -rf auth.yaml auth

# Create secret for cloudflared
kubectl create secret generic tunnel-credentials --from-file=credentials.json=/Users/<USER>/.cloudflared/<UUID>.json --dry-run -o yaml > cloudflare-credentials.yaml

# Seal secret
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
< cloudflare-credentials.yaml > tunnel-credentials.yaml

mv tunnel-credentials.yaml infrastructure/cloudflared/secret.yaml

rm -rf cloudflare-credentials.yaml

# Create secret for grafana

kubectl -n default create secret generic grafana-admin-credentials \
--from-literal=admin-user=${USER} \
--from-literal=admin-password=${PASSWORD} \
--dry-run=client \
-o yaml > grafana-credentials.yaml

# Seal secret

kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
< grafana-credentials.yaml > grafana-credentials-sealed.yaml

mv grafana-credentials-sealed.yaml infrastructure/prometheus-stack/secret.yaml

rm -rf grafana-credentials.yaml

```

## Preparing Velero credentials

create a `cloud` file in the root of the project with the following contents

```aw
[default]
aws_access_key_id=<AWS_ACCESS_KEY_ID>
aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>
```

Then run the following commands

```sh
# create a secret from the file
kubectl -n velero create secret generic aws --from-file=cloud --dry-run=client -o yaml > cloud.yaml

# Seal secret
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
< cloud.yaml > aws-credentials-sealed.yaml

mv aws-credentials-sealed.yaml infrastructure/velero/secret.yaml

rm -rf cloud.yaml
```
