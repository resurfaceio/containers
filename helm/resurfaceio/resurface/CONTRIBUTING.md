# Contributing to Resurface helm chart
&copy; 2016-2022 Resurface Labs Inc.

## Testing Local Changes

```
# install local chart
helm install resurface . --create-namespace --namespace resurface

# enable tls
helm repo add jetstack https://charts.jetstack.io; helm repo update; helm install cert-manager jetstack/cert-manager --namespace resurface --version v1.7.1 --set installCRDs=true --set prometheus.enabled=false
helm upgrade resurface . -n resurface --set ingress.tls.enabled=true --set ingress.tls.autoissue.enabled=true --set ingress.tls.autoissue.email=rob@resurface.io --set ingress.tls.host=radware4 --reuse-values

# enable basic auth
noglob helm upgrade resurface . -n resurface --set auth.enabled=true --set auth.basic.enabled=true --set auth.basic.credentials[0].username=rob --set auth.basic.credentials[0].password=blah1234 --reuse-values

# completely remove everything
helm uninstall resurface -n resurface; kubectl delete namespace resurface
kubectl delete clusterrole kubernetes-ingress
kubectl delete clusterrolebinding kubernetes-ingress
kubectl delete ingressclass haproxy
```

## Release Process

tbd