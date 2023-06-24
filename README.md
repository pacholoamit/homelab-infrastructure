## Pre-requisites

On the nodes ensure to install open-iscsi:

```
# on all nodes with longhorn
apt install open-iscsi
apt install nfs-common
```

MUST DO FOR ALL DEPLOYMENTS
Reapplying secrets, if `sealed-secret-backup.key` (yaml) file is present

```sh
kubectl apply -f sealed-secret-backup.key # After this restart the sealed-secrets-controller pod
```



