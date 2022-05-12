# resurfaceio-helm-resurface

Resurface is like an API analyst in a box. Resurface continuously scans your API traffic to discover attacks,
leaks, and failures that are impacting your APIs. See [resurface.io](https://resurface.io) for more information.

## Components

- StatefulSets: Resurface database coordinator pod and worker replicas with persistent storage. Your very own Resurface instance.
- Service: Coordinator. Exposes the API Explorer frontend for your Resurface instance.
- Service: Worker. Exposes the fluke microservice used to import API calls into your Resurface instance.
- Ingress: Requires HAProxy ingress controller. Enabled by default.
- TLS Secret: (Optional) TLS certificate and key. Used for Ingress TLS termination. A TLS cert and key combination can be autoissued by the cert-manager utility, or it can be provided by the user. Disabled by default.
- ClusterIssuer: (Optional) Issues TLS certificate from Let's Encrypt. Resquires Cert-manager utility. Disabled by default.
- Daemonset: (Optional) Packet-sniffer-based logger. Captures API calls made to your application pods over the wire, parses them and sends them to your Resurface pod. A service account, cluster role, and cluster role binding are also deployed with this daemon set. Disabled by default.

## Dependencies

- [HAProxy Ingress Controller](https://www.haproxy.com/documentation/kubernetes/latest/installation/community/)
- [Cert-manager utility](https://cert-manager.io/docs/installation/helm/) (when TLS auto-issuing enabled)

## Values

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
    - **ingress.tls.autoissue.staging**: boolean. The TLS certificate automatic issuing and renewal process uses the "Let's Encrypt" ACME as CA. Let's Encrypt provides both a [staging environment](https://letsencrypt.org/docs/staging-environment/) and a [rate-limited production environment](https://letsencrypt.org/docs/rate-limits/) for the certificate issuing process. By setting this value to `true` cert-manager uses the former, and by setting it to `false` it then uses the latter. Defaults to `true`.
    - **ingress.tls.autoissue.email**: string. Let's Encrypt will send notices only if a certificate is about to expire and the renewal process has failed. Required only if **ingress.tls.autoissue.enabled** is set to `true`.
  - **ingress.tls.byoc**: this nested subsection corresponds to the bring-your-own-certificate configuration. This process is mutually exclusive with respect to the autoissuing process. A user must supply the name of a Kubernetes TLS Secret that already exists in the same namespace.
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

Basic authorization can be configured in the **auth** section.

- **auth.enabled**: boolean. If set to `true`, password will be required at the login page of the API Explorer and, for any transaction using the Trino REST API. Otherwise, no password is required. Defaults to `false`. Auth will work only when TLS is enabled. At least one authentication method must be enabled when auth is enabled.
- **auth.basic.enabled**: If set to `true`, basic authentication will be enabled. A secret containing an encrypted list of allowed credentials will be mounted in the file system. Defaults to `false`.
- **auth.basic.credentials**: Sequence of credentials allowed. Both a **username** and **password** are required for each item. At least one credential must be passed when **auth.basic.enabled** is set to `true`.
- **auth.oauth2.enabled**: If set to `true`, OAuth 2.0 will be enabled. All the corresponding endpoints for an external OAuth 2.0 Authorization Code service must be configured, as well as a Client ID and Client Secret provided by this third party. Users will be redirected to the external provider Log In page, and redirected back to the API Explorer once authenticated. Defaults to `false`.
- **auth.oauth2.issuer**: String. The issuer URL for the external OAuth 2.0 service. All tokens issued by the service must have this in the `iss` field. Required only if **auth.aouth2.enabled** is set to `true`.
- **auth.oauth2.authurl**: String. The service authorization URL. The browser will be redirected to this URL when accessing the API Explorer for the first time. Required only if **auth.aouth2.enabled** is set to `true`.
- **auth.oauth2.tokenurl**: String. The URL of the endpoint on the authorization server to exchange the authorization code for an access token. Required only if **auth.aouth2.enabled** is set to `true`.
- **auth.oauth2.jwksurl**: String. The URL of the JSON Web Key Set (JWKS) endpoint on the authorization server. It must point to the set of keys containing the public key to verify any JSON Web Token (JWT) from the authorization server. Required only if **auth.aouth2.enabled** is set to `true`.
- **auth.oauth2.userinfourl**: String.  If supplied then this URL is used to validate the OAuth access token and retrieve any associated claims. Required only if the authorization server issues opaque tokens.
- **auth.oauth2.clientid**: String. Client identifier provided by the external OAuth 2.0 service.
- **auth.oauth2.clientsecret**: String. Client secret provided by the external OAuth2.0 service.

```yaml
auth:
  enabled: true
  basic:
    enabled: true
    credentials:
      - username: admin
        password: irtRUqUp7fkfL
      - username: msmith
        password: qPBceDWjPJFYKfX7QAXfmy1b33tBE
    oauth2:
      enabled: true
      issuer: https://accounts.google.com
      authurl: https://accounts.google.com/o/oauth2/v2/auth
      tokenurl: https://oauth2.googleapis.com/token
      jwksurl: https://www.googleapis.com/oauth2/v3/certs
      userinfourl: https://openidconnect.googleapis.com/v1/userinfo
      clientid: sampleid123.apps.googleusercontent.com
      clientsecret: samplesecret456
```

The **provider** value is a string equal to either `azure`, `aws`, or `gcp`. It is used as an alias to request persistent volumes specific to each provider. See the **custom.storage** section.

```yaml
provider: azure
```

The **multinode** section is where the configuration to set multiple database nodes can be found.

- **multinode.enabled**: boolean. If set to `true` worker nodes are enabled. Otherwise, the single-node configuration is used. Defaults to `false`
- **multinode.workers**: integer. Number of stateful worker nodes to deploy. Resources must be available in the cluster in order to succesfully scale accordingly. The total number of nodes in the database will be **multinode.workers** + 1, since the coordinator node always acts as a worker node.

```yaml
multinode:
  enabled: true
  workers: 3
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
  - **custom.resources.memory**: integer. Minimum required memory in GiB to run a Resurface container. It should be greater than the sum of both **custom.config.dbsize** and **custom.config.dbheap** values.

- The **custom.config** subsection contains configuration specific to Resurface.
  - **custom.config.dbsize**: integer. Available memory in GiB to be used by the Resurface database.
  - **custom.config.dbheap**: integer. Available memory in GiB to be used by the JVM running the application. It isn't recommended to set this value below `3`.
  - **custom.config.dbslabs**: integer. Used by the Resurface database to define a level of parallelism for queries.
  - **custom.config.tz**: string. Used to specify a local timezone instead of the UTC timezone containers run with by default.

- The **custom.storage** subsection refers to the persistent storage configuration. Persistent volume implementation is specific to each cloud provider.
  - **custom.storage.size**: integer. Size in GiB of the persistent volume that should be provisioned for each Resurface node. It should match the **custom.config.dbsize** value.
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

The **sniffer** value is where the configuration for the optional network packet sniffer can be found.

- **sniffer.enabled**: boolean. The sniffer can be deployed by setting this value to `true`. Defaults to `false`.

- **sniffer.services**: Sequence of services to log from. For each service, both a **namespace** and service **name** can be specified. If only namespace is specified for a given service, it will be ignored uless namespace-only discovery is enabled. In addition, an array of integer **ports** can be passed for each service. These ports refer to the target ports for each container, not service ports. See example below.

- **sniffer.pods**: Sequence of specific pods to log from. For each pod, both **namespace** and pod **name** are required. In addition, an array of integer container **ports** can also be passed for each pod. See example below.

- **sniffer.labels**: Sequence of specific label selectors used to select a set of pods. A **keyvalues** sequence of strings corresponding to all key-value pairs that make up the selector label in the form `"key=value"` must be provided for each item. The **namespace** is optional. See example below.

- The **sniffer.discovery** subsection contains the configuration for service discovery. When **sniffer.services** is empty and **sniffer.discovery.enabled** is set to `true`, global service discovery is enabled. When **sniffer.discovery.enabled** is set to `true` and **sniffer.services** contains at least one service specifying only its namespace, namespace-only discovery is enabled for that namespace. Note: It is suggested to explicitly skip services that expose pods acting as Ingress Controllers, as traffic will still be logged from upstream pods.
  - **sniffer.discovery.enabled**: boolean. Defaults to `false`.
  - **sniffer.discovery.skip**: nested subsection that refers to specific namespaces or services to skip when discovery is performed.
    - **sniffer.discovery.skip.ns**: []string. Array containing the names of the namespaces to be skipped.
    - **sniffer.discovery.skip.svc**: []string. Array containing the names of the services to be skipped.
- The **sniffer.logger** nested section contains the configuration specific to the Resurface logger used by the sniffer to send API calls to the corresponding importer endpoint.
  - **sniffer.logger.enabled**: boolean. The internal logger can be temporarily disabled by setting this value to `false`.
  - **sniffer.logger.rules**: string. The internal logger operates under a certain [set of rules](http://resurface.io/logging-rules) that determines which data is logged. These rules can be passed to the logger as a single-line or a multiline string.

- **sniffer.ignore**: []string. Array containing the names of specific network interfaces to ignore for all nodes. Defaults to `[ "eth0", "cbr0" ]`
- **sniffer.port**: (deprecated) integer. Container port exposed by the application to capture packets from. Defaults to `80`. Required only if **sniffer.enabled** is `true`.
- **sniffer.device**: (deprecated) string. Name of the network interface to attach the sniffer to. Defaults to the Kubernetes custom bridge interface `cbr0`.

NOTE: When no services, pods, or labels are specified and discovery is disabled, the sniffer behavior falls back to logging from a specific network device on a specific port. This is not compatible with all Kubernetes environments and should be avoided by specifiying at least one service, pod or label, or enabling service discovery.

```yaml
sniffer:
  deploy: true
  discovery:
    enabled: false
    skip:
      ns: [ "kube-system" ]
      svc: [ "kubernetes" ]
  services:
  - namespace: mynamespace
    name: myservice
    ports: [ 8000, 3000 ]
  - namespace: anotherone
    name: anothersvc
  - namespace: thisoneworksfordiscoveryonly
  pods:
  - namespace: mynamespace
    name: mypod-12345A
    ports: [ 8080 ]
  - namespace: mynamespace
    name: mypod-12345B
  labels:
  - namespace: mynamespace
    keyvalues: [ "key1=value1","key2=value2","key4=value4" ]
  - keyvalues: [ "key3=value3", "key5=value5" ]
  logger:
    enabled: true
    rules: |
      include debug
      skip_compression
```
