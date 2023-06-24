# Documentation on starting from scratch (WIP)

Below are the required commands to start from scratch.

## Bootstrapping with flux

Install the flux CLI tool and run the following command.

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

## Preparing cloudflare tunnels

We are using Cloudflare tunnels to route traffic to our cluster. Install the cloudflared CLI tool and run the following commands.

```sh
cloudflared tunnel login

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

create an `aws-credentials` file in the root of the project with the following contents

```aw
[default]
aws_access_key_id=<AWS_ACCESS_KEY_ID>
aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>
```

Then run the following commands

```sh
# create a secret from the file
kubectl -n velero create secret generic aws --from-file=aws-credentials --dry-run=client -o yaml > aws-credentials.yaml

# Seal secret
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
< aws-credentials.yaml > aws-credentials-sealed.yaml

mv aws-credentials-sealed.yaml infrastructure/velero/secret.yaml

rm -rf aws-credentials.yaml
```
