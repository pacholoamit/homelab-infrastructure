# Homelab Infrastructure

<img src="https://raw.githubusercontent.com/kubernetes/kubernetes/master/logo/logo.png" width="150px" alt="">
<img src="https://avatars.githubusercontent.com/u/52158677?s=200&v=4" width="150px" alt="">
<img src="https://cncf-branding.netlify.app/img/projects/k3s/stacked/color/k3s-stacked-color.png"  height="150" alt="">

> Warning: Documentation is a work in progress

This repository contains the infrastructure used for my homelab. It mainly contains the manifests to run my Kubernetes cluster. The kubernetes distribution used is [k3s](https://k3s.io/), whilst the manifests are managed by [flux](https://fluxcd.io/). I am mainly focused on following a GitOps approach to managing my homelab.

# :open_book: Check out the Documentation

- [Documentation](./docs)

# Main tools used

1. **FluxCD 2** - GitOps for my HomeLab.
2. **Cloudfare** - Cloudflare tunnel for accessing my services.
3. **ingress-nginx** - Kubernetes ingress. Cloudflare forwards all requests to the ingress-nginx controller which then routes the requests to the correct service.
4. **Longhorn** - K8S distributed & replicated block storage.
5. **SealedSecerts** - Kubernetes secret manager.
6. **Kube-Prometheus-Stack** - Kubernetes monitoring stack.
7. **Velero** - K8S and PVC backup. Free and open source by VMware
