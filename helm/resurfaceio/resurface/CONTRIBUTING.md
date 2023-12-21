# Contributing to resurfaceio/containers
&copy; 2016-2023 Graylog, Inc.

## Before Installing Local Changes

```bash
# check template rendering
helm template resurface . --debug | less

# do a dry run with a small configuration
helm install resurface . --dry-run --debug --create-namespace -n resurface --set custom.config.dbheap=3 --set custom.config.dbsize=3 --set custom.config.shardsize=1 --set custom.resources.cpu=3 --set custom.resources.memory=7

# do a dry run with cloud provider defaults
helm install resurface . --dry-run --debug --create-namespace -n resurface --set provider=azure
helm install resurface . --dry-run --debug --create-namespace -n resurface --set provider=aws
```

## Test Local Changes

```bash
# install coordinator node
helm install resurface . --create-namespace -n resurface

# enable iceberg with minio standalone
helm upgrade -i resurface . -n resurface --set iceberg.enabled=true --set minio.enabled=true --set minio.mode=standalone --set minio.replicas=1 --set minio.rootUser=minio --set minio.rootPassword=minio123 --set minio.ingress.expose=true --reuse-values

# add worker node if you have enough cowbell
helm upgrade -i resurface . -n resurface --set multinode.enabled=true --set multinode.workers=1 --reuse-values

# enable tls
helm repo add jetstack https://charts.jetstack.io; helm repo update; helm install cert-manager jetstack/cert-manager -n resurface --version v1.13.3 --set installCRDs=true --set prometheus.enabled=false
helm upgrade resurface . -n resurface --set ingress.tls.enabled=true --set ingress.tls.autoissue.enabled=true --set ingress.tls.autoissue.email=rob@resurface.io --set ingress.tls.host=radware4 --reuse-values

# enable basic auth
noglob helm upgrade resurface . -n resurface --set auth.enabled=true --set auth.basic.enabled=true --set auth.basic.credentials[0].username=rob --set auth.basic.credentials[0].password=blah1234 --reuse-values

# completely remove everything
helm uninstall resurface -n resurface; kubectl delete $(kubectl get pvc -n resurface -o name) -n resurface; helm uninstall cert-manager -n resurface; kubectl delete namespace resurface; kubectl delete clusterrole kubernetes-ingress; kubectl delete clusterrolebinding kubernetes-ingress; kubectl delete ingressclass haproxy
```

## Test Local Changes with a Cloud Provider

```bash
helm install resurface . --create-namespace -n resurface --set provider=azure
helm install resurface . --create-namespace -n resurface --set provider=aws
helm install resurface . --create-namespace -n resurface --set provider=gcp
```

## Test Storage Deployments

```bash
# MinIO Distributed
helm upgrade -i resurface . -n resurface --set iceberg.enabled=true --set minio.enabled=true --set minio.mode=distributed --set minio.replicas=4 --set minio.rootUser=minio --set minio.rootPassword=minio123  --set minio.ingress.expose=true --reuse-values

# AWS S3
helm upgrade -i resurface . -n resurface --set iceberg.enabled=true --set iceberg.s3.enabled=true --set iceberg.s3.bucketname=iceberg.resurface --set iceberg.s3.aws.region=us-west-2 --set iceberg.s3.aws.accesskey=<AWS-ACCESS-KEY> --set iceberg.s3.aws.secretkey=<AWS-SECRET-KEY> --reuse-values
```

## Uninstall

```bash
helm uninstall resurface -n resurface; kubectl delete $(kubectl get pvc -n resurface -o name) -n resurface; helm uninstall cert-manager -n resurface; kubectl delete namespace resurface; kubectl delete clusterrole kubernetes-ingress; kubectl delete clusterrolebinding kubernetes-ingress; kubectl delete ingressclass haproxy
```

## Update Docs

`README.md` and `templates/NOTES.txt` contain information about both the usage of this Helm chart and its status as a Helm release once installed. If it applies, please update each accordingly.

## Update Changelog and Chart version

`Chart.yaml` contains an annotation named `artifacthub.io/changes` where the modifications introduced to the chart can be described briefly. The supported kinds of modification are *added*, *changed*, *deprecated*, *removed*, *fixed* and *security*.

The github action in charge of making new helm releases is automatically triggered when the Chart version is updated. Make sure to test the changes that you have made as indicated above before updating this value. This chart follows semantic versioning (major: usually breaking changes, minor: usually new features/new app version, patch: usually bug fixes).

## Push Local Changes

```bash
git pull --rebase
git push
```
