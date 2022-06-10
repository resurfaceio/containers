# Contributing to resurfaceio-containers
&copy; 2016-2022 Resurface Labs Inc.

## Testing local helm charts

Here's how to test local changes before committing officially.

```
cd ./helm/resurfaceio/resurface

# test without tls
helm repo add haproxytech https://haproxytech.github.io/helm-charts; helm repo update; helm install kubernetes-ingress haproxytech/kubernetes-ingress --namespace resurface --create-namespace --set controller.service.type=LoadBalancer; helm install resurface . --namespace resurface

(log into UI, add license, etc)

# test with tls
helm upgrade resurface . -n resurface --set ingress.tls.enabled=true --set ingress.tls.autoissue.enabled=true --set ingress.tls.autoissue.email=rob@resurface.io --set ingress.tls.host=radware4

# test with tls & password auth
helm repo add jetstack https://charts.jetstack.io; helm repo update; helm install cert-manager jetstack/cert-manager --namespace resurface --version v1.7.1 --set installCRDs=true --set prometheus.enabled=false
noglob helm upgrade resurface . -n resurface --set ingress.tls.enabled=true --set ingress.tls.autoissue.enabled=true --set ingress.tls.autoissue.email=rob@resurface.io --set ingress.tls.host=radware4 --set auth.enabled=true --set auth.credentials[0].username=rob --set auth.credentials[0].password=blah1234
```
