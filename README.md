# Homelab Infrastructure

<p align="center">
<img src="https://raw.githubusercontent.com/kubernetes/kubernetes/master/logo/logo.png" width="150px" alt=""><img src="https://avatars.githubusercontent.com/u/52158677?s=200&v=4" width="150px" alt=""><img src="https://cncf-branding.netlify.app/img/projects/k3s/stacked/color/k3s-stacked-color.png"  height="150" alt="">
</p>

> Warning: Documentation is a work in progress

This repository contains the infrastructure used for my homelab. It mainly contains the manifests to run my Kubernetes cluster. The kubernetes distribution used is [k3s](https://k3s.io/), whilst the manifests are managed by [flux](https://fluxcd.io/). I am mainly focused on following a GitOps approach to managing my homelab.

# :open_book: Check out the Documentation

- [Documentation](./docs)

# Main tools used

1. **FluxCD 2** - GitOps for my HomeLab.
2. **Cloudfared** - Cloudflare tunnel for accessing my services.
3. **ingress-nginx** - Kubernetes ingress. Cloudflare forwards all requests to the ingress-nginx controller which then routes the requests to the correct service.
4. **Longhorn** - K8S distributed & replicated block storage.
5. **SealedSecerts & Mozilla SOPS** - Kubernetes secret manager & Secrets encryption.
6. **Kube-Prometheus-Stack** - Kubernetes monitoring stack.
7. **Velero** - K8S and PVC backup. Free and open source by VMware
8. **Descheduler** - Kubernetes descheduler. Monitors node resource usage and reassigns workloads to other nodes based on rules.
9. **Renovate** - Automated dependency updates for my kubernetes deployments and helm charts.

# GitOps :construction:

GitOps is applied wherever possible using Flux2.
CI/CD is done by bootstrapping flux into my cluster. Flux polls GitHub for changes and applies them automatically on my server.
It is currently pretty stable and works fine

# Accessing services ( ingress-nginx, Cloudflared )

Apps are currently exposed by ingress-nginx and Cloudflared which both run in the cluster. Cloudflared is used to expose services to the internet. Cloudflare forwards all requests to the ingress-nginx controller which then routes the requests to the correct service. The current Cloudflare deployment creates 2 pods on different nodes to ensure high availability.

Cloudflare manages my DNS records for my domain `pacholoamit.com` and adding routes is as simple as creating an ingress resource and applying a command

```
cloudflared tunnel route dns home-k3s-cluster route.pacholoamit.com
```

# Storage ( Longhorn )

Longhorn is a great replicated storage option with a great UI for better visualisation. It's fast and tailor made for
k8s. Developed by the same people responsible for k3s/rancher and other great tools. [Official site](https://longhorn.io/)

# Secrets ( Sealed Secrets )

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) is a great tool for managing secrets in k8s. It allows me to encrypt secrets and store them in git. The sealed secret controller then decrypts the secrets and applies them to the cluster. This allows me to store my secrets in git without worrying about them being exposed.

# Monitoring ( Kube-Prometheus-Stack )

The [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) allows me to monitor my cluster, I am able to view the metrics gathered by prometheus on my grafana dashboard.

# Backup ( Velero )

Velero allows me to back up selected namespaces and ( with the help of restic ) ship the data to different sources.
In my case I'm using the velero AWS plugin.
