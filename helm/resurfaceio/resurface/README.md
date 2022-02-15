# resurfaceio-helm-resurface

## Contents

- [resurfaceio-helm-resurface](#resurfaceio-helm-resurface)
  - [Contents](#contents)
  - [Requirements](#requirements)
  - [Description](#description)
  - [Values](#values)

## Requirements

- [Resurface entitlement token](https://resurface.io/installation)
- [HAProxy Ingress Controller](https://www.haproxy.com/documentation/kubernetes/latest/installation/community/) (Only if using Ingress)
- [Cert-manager utility](https://cert-manager.io/docs/installation/helm/) (Only if using Ingress with TLS autoissuing enabled)

## Description

Resurface can help with failure triage and root cause analysis, threat and
risk identification, and simply just knowing how your APIs are being used.
It identifies what's important in your API data, and can send warnings and
alerts in real-time for fast action.

With these charts, several resources are deployed in your cluster:

- Secret: Entitlement Token. It is used to pull images from the Resurface.io private container registry.
- StatefulSets: Resurface database coordinator pod and worker replicas with persistent storage. Your very own Resurface instance.
- Service: Coordinator. It exposes the API Explorer frontend for your Resurface instance.
- Service: Worker. It exposes the fluke microservice used to import API calls into your Resurface instance.
- Ingress: (Optional) Gateway to services. Provides load balancing and SSL/TLS termination. Requires HAProxy ingress controller. Enabled by default.
- TLS Secret: (Optional) TLS certificate and key. Used for Ingress TLS termination. A TLS cert and key combination can be autoissued by the cert-manager utility, or it can be provided by the user. Disabled by default.
- ClusterIssuer: (Optional) Issues TLS certificate from Let's Encrypt. Resquires Cert-manager utility. Disabled by default.
- Daemonset: (Optional) Packet-sniffer-based logger. It captures API calls made to your application pods over the wire, parses them and sends them to your Resurface pod. Disabled by default.

## Values

The **etoken** value is a string equal to the password sent to you after signing up for Resurface. Required.

```yaml
etoken: << paste it here! >>
```

The **size** value is a string equal to either `orca` or `humpback`. It represents a predefined configuration for the resources necessary to run the container. See the **custom.resources**, **custom.config** and **custom.storage** values section. Defaults to `orca`.

```yaml
size: orca
```

The **provider** value is a string equal to either `azure`, `aws`, or `gcp`. It is used to request persistent volumes specific to each provider. See the **custom.storage** section. Required.

```yaml
provider: azure
```

The **ingress** values section is where the configuration for the Ingress resource can be found. The following fields can be found nested in this section:

- **ingress.enabled**: boolean. The Ingress resource can be disabled by setting this value to `false`. In that case, the services can still be exposed, albeit without SSL/TLS termination. See **custom.service** section. Defaults to `true`.

- **ingress.importer**: this subsection corresponds to the endpoint used by each Resurface worker node to import API calls into your Resurface database.
  - **ingress.importer.expose**: boolean. The importer endpoint can be disabled by setting this value to `false`. In that case, the endpoint will only be reachable through the worker importer service and not the ingress resource. Defaults to `true`.
  - **ingress.importer.path**: string. The ingress resource will route all calls made to this path to the worker importer service. Defaults to "/fluke". Required only if **ingress.importer.expose** is set to `true`.

- **ingress.tls**: this subsection corresponds to the TLS termination configuration for the Ingress resource.
  - **ingress.tls.enabled**: boolean. The TLS termination feature can be enabled by setting this value to `true`. Defaults to `false`.
  - **ingress.tls.host**: string. Host included in the TLS certificate. DNS records must be updated accordingly. Required only if **ingress.tls.enabled** is set to `true`.
  - **ingress.tls.autoissue**: this nested subsection corresponds to the configuration needed to autoissue a TLS certificate using the cert-manager utility. The autoissing process is mutually exclusive with respect to the BYOC (bring-your-own-certificate) process.
    - **ingress.tls.autoissue.enabled**: boolean. The TLS certificate automatic issuing and renewal process can be disabled by setting this value to `false`. Defaults to `true`.
    - **ingress.tls.autoissue.staging**: boolean. The TLS certificate automatic issuing and renewal process uses the "Let's Encrypt" ACME as CA. Let's Encrypt provides both a staging and a rate-limited production environments for the certificate issuing process. By setting this value to `true` cert-manager uses the former, and by setting it to `false` it then uses the latter. Learn more about each Let's Encrypt environment at: https://letsencrypt.org/docs/staging-environment/ and https://letsencrypt.org/docs/rate-limits/ Defaults to `true`.
    - **ingress.tls.autoissue.email**: string. Let's Encrypt will send notices only if a certificate is about to expire and the renewal process has failed. Required only if **ingress.tls.autoissue.enabled** is set to `true`.
  - **ingress.tls.byoc**: this nested subsection corresponds to the bring-your-own-certificate configuration. This process is mutually exclusive with respect to the autoissing process. A user must supply the name of a Kubernetes TLS Secret that already exists in the same namespace.
    - **ingress.tls.byoc.secretname**: string. Name of an already existing Kubernetes TLS Secret to be used by the Ingress resource. Required only if **ingress.tls.enabled** is set to `true` and **ingress.tls.autoissue.enabled** is set to `false`.

```yaml
ingress:
  enabled: true
  tls:
    enabled: true
    host: thisisanexample.com
    autoissue:
      staging: false
      email: admin@thisisanexample.com
```

The **custom** section holds the values for fields that can be overriden in any default configuration. None of its fields are required. The following fields can be found nested in this section:

- The **custom.service** subsection is where the configuration for both the internal service resources can be found.
  - **custom.service.apiexplorer**: nested subsection that refers to the Resurface frontend service.
    - **custom.service.apiexplorer.port**: integer. Port exposed by the coordinator service. Defaults to `7700`
    - **custom.service.apiexplorer.type**: string. Service type for the coordinator service. Defaults to `LoadBalancer` when `ingress.enabled` is set to `false`. It defaults to a headless service otherwise.
  - **custom.service.flukeserver**: nested subsection for the Resurface importer service.
    - **custom.service.flukeserver.port**: integer. Port exposed by the worker service. Defaults to `7701`
    - **custom.service.flukeserver.type**: string. Service type for the worker service. Defaults to `ClusterIP`

- The **custom.resources** subsection is where the container configuration requirements can be found.
  - **custom.resources.cpu**: integer. Minimum required vCPU to run a Resurface container. It isn't recommended to set this value lower than `3`.
  - **custom.resources.memory**: integer. Minimum required memory in GiB to run a Resurface container. It should match both **custom.config.dbsize** and **custom.storage.size** values.

- The **custom.config** subsection contains configuration specific to Resurface.
  - **custom.config.dbsize**: integer. Available memory (volatile and persistent) in GiB to be used by the Resurface database.
  - **custom.config.dbheap**: integer. Available memory in GiB to be used by the JVM running the application. It isn't recommended to set this value below `3`.
  - **custom.config.dbslabs**: integer. Used by the Resurface database to define a level of parallelism for queries.

- The **custom.storage** subsection refers to the persistent storage configuration. Persistent volume implementation is specific to each cloud provider.
  - **custom.storage.size**: integer. Size in GiB of the persistent volume that should be provisioned for each Resurface node. It should match both **custom.config.dbsize** and **custom.resource.memory** values.
  - **custom.storage.classname**: string. Name of the storage class to be used when requesting a new persistent volume claim. Each cloud provider can offer more than one `StorageClassName`. By setting `provider`, the storage class name is set to the one offered as default for each provider. This value overrides that default class name. The chosen **custom.storage.classname** should be offered by the cloud provider, otherwise persistence is not guaranteed.

```yaml
custom:
  service:
    apiexplorer:
      port: 80
    flukeserver:
      port: 7701
      type: NodePort
  resources:
    memory: 12
  storage:
    classname: managed-csi-premium
```

The **multinode** section is where the configuration to set multiple nodes can be found.

- **multinode.enabled**: boolean. If set to `true` worker nodes are enabled. Otherwise, the single-node configuration is used. Defaults to `false`
- **multinode.workers**: integer. Number of stateful worker nodes to deploy. Resources must be available in the cluster in order to succesfully scale accordingly.

The **sniffer** value is where the configuration for the optional network packet sniffer can be found.

- **sniffer.enabled**: boolean. The sniffer can be deployed by setting this value to `true`. Defaults to `false`.
- **sniffer.port**: integer. Cotnainer port exposed by the application to capture packets from. Default to `80`. Required only if **sniffer.enabled** is `true`.
- **sniffer.device**: string. Name of the network interface to attach the sniffer to. Defaults to the Kubernetes custom bridge interface `cbr0`.
- The **sniffer.logger** nested section contains the configuration specific to the Resurface logger used by the sniffer to send API calls to the corresponding importer endpoint.
  - **sniffer.logger.enabled**: boolean. The internal logger can be temporarily disabled by setting this value to `false`.
  - **sniffer.logger.rules**: string. The internal logger operates under a certain [set of rules](http://resurface.io/logging-rules) that determines which data is logged. These rules can be passed to the logger as a single-line or a multiline string.

```yaml
sniffer:
  deploy: true
  port: 80
  device: cbr0
  logger:
    enabled: true
    rules: |
      include debug
      skip_compression
```
