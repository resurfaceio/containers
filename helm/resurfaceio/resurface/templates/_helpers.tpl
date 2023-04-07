{{/*
Expand the name of the chart.
*/}}
{{- define "resurface.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "resurface.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains .Release.Name $name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "resurface.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "resurface.labels" -}}
helm.sh/chart: {{ include "resurface.chart" . }}
{{ include "resurface.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "resurface.selectorLabels" -}}
app.kubernetes.io/name: {{ include "resurface.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Container resources and persistent volumes
*/}}
{{- define "resurface.resources" }}
{{- $provider := toString .Values.provider -}}
{{- $icebergIsEnabled := .Values.iceberg.enabled | default false -}}

{{/* Used for value validation */}}
{{- $validPollingCycles := list "default" "off" "fast" "nonstop" -}}
{{- $validIcebergCompressionCodecs := list "ZSTD" "LZ4" "SNAPPY" "GZIP" -}}
{{- $validIcebergFileFormats := list "ORC" "PARQUET" -}}

{{/* Defaults for DB environment variables */}}
{{- $defaultDBSize := or (eq $provider "ibm-openshift") (eq $provider "azure") | ternary 7 9 -}}
{{- $defaultDBHeap := 3 -}}
{{- $defaultDBSlabs := 3 -}}
{{- $defaultShardSize := "500m" -}}
{{- $defaultPollingCycle := "default" -}}
{{- $defaultTimezone := "UTC" -}}
{{- if $icebergIsEnabled -}}
  {{- $defaultDBHeap = $defaultDBSize -}}
  {{- $defaultDBSize = 3 -}}
  {{- $defaultDBSlabs = 1 -}}
  {{/*- $defaultShardSize = "3g" -*/}}
{{- end -}}
{{/* Min shard number is hard coded in Resurface data ingestion service (fluke server) */}}
{{- $minShards := 3 -}}
{{/*
  All values without data unit prefix are assumed to be GiB/GB.
  Modifying the default order of magnitude only alters the units conversion factor.
  Modifying the units conversion factor affects all numeric values set env vars
*/}}
{{- $defaultOrderOfMagnitude := "G" -}}

{{/* Conversion factor to go from power-of-ten units (metric, GB) to power-of-two units (binary, GiB) */}}
{{- $unitsCF := 1 -}}
{{- if not (empty .Values.units) -}}
  {{- if eq .Values.units "metric" -}}
    {{- $prefixes := dict "k" 1 "M" 2 "G" 3 "T" 4 "P" 5 "E" 6 "Z" 7 "Y" 8 "R" 9 "Q" 10 -}}
    {{- $num := 1000 -}}
    {{- $den := 1024 -}}
    {{- range $i := until (get $prefixes $defaultOrderOfMagnitude) -}}
      {{- $num := mul $num $num -}}
      {{- $den := mul $den $den -}}
    {{- end -}}
    {{- $unitsCF = div $num $den -}}
  {{- else if ne .Values.units "binary" -}}
    {{- fail "Unknown data unit prefix. Supported values are: 'binary', 'metric'" -}}
  {{- end -}}
{{- end -}}

{{- $dbSize := .Values.custom.config.dbsize | default $defaultDBSize | int -}}
{{- $dbHeap := .Values.custom.config.dbheap | default $defaultDBHeap | int -}}
{{- $dbSlabs := .Values.custom.config.dbslabs | default $defaultDBSlabs | int -}}
{{- $shardSize := .Values.custom.config.shardsize | default $defaultShardSize -}}
{{- $pollingCycle := .Values.custom.config.pollingcycle | default $defaultPollingCycle -}}
{{- $timezone := .Values.custom.config.tz | default $defaultTimezone -}}

{{/*
  Shard size can be passed with a data unit prefix (k, m, or g)
  g is assumed when an integer is passed.
  Prefix is normalized as k for any valid value.
*/}}
{{- if kindIs "int64" $shardSize -}}
  {{- $shardSize = printf "%dg" $shardSize -}}
{{- end -}}
{{- $shardSizeLen := len $shardSize -}}
{{- if (trimSuffix "k" $shardSize | len | ne $shardSizeLen) -}}
  {{- $shardSize = trimSuffix "k" $shardSize | int -}}
{{- else if (trimSuffix "m" $shardSize | len | ne $shardSizeLen) -}}
  {{- $shardSize = trimSuffix "m" $shardSize | int | mul 1024 -}}
{{- else if (trimSuffix "g" $shardSize | len | ne $shardSizeLen) -}}
  {{- $shardSize = trimSuffix "g" $shardSize | int | mul (mul 1024 1024) -}}
{{- else -}}
  {{- fail "Invalid shard size value. Supported data unit prefixes are: k, m, g" -}}
{{- end -}}

{{/* Shard size and polling cycle validation */}}
{{- $maxShards := div (mul $dbSize (mul 1024 1024)) $shardSize | int -}}
{{- if lt $maxShards $minShards -}}
  {{- printf "\nNumber of max shards (DB_SIZE/SHARD_SIZE) must be greater than or equal to %d.\n\tDB_SIZE = %dg\n\tSHARD_SIZE = %dk\n\tMax shards configured: %d" $minShards $dbSize $shardSize $maxShards | fail -}}
{{- end -}}

{{- if not (has $pollingCycle $validPollingCycles) -}}
  {{- join "," $validPollingCycles | cat "Unknown DB polling cycle. Polling cycle must be one of the following: " | fail -}}
{{- end -}}

{{/* Defaults for Persistent Volume size and Storage Class names */}}
{{- $defaultPVSize := default $dbSize | max 9 -}}
{{- $defaultSCNames := dict "azure" "managed-csi" "aws" "gp2" "gcp" "standard" -}}

{{- $pvSize := .Values.custom.storage.size | default $defaultPVSize | int -}}
{{- $storageClassName := .Values.custom.storage.classname | default (get $defaultSCNames $provider) -}}

{{/* Defaults for Iceberg environment variables */}}
{{- $defaultIcebergMaxSize := 100 -}}
{{- $defaultIcebergMinSize := 20 -}}
{{- $defaultIcebergPollingMillis := 20000 -}}
{{- $defaultIcebergCompressionCodec := "ZSTD" -}}
{{- $defaultIcebergFileFormat := "ORC" -}}

{{- $icebergMaxSize := .Values.iceberg.config.size.max | default $defaultIcebergMaxSize | int -}}
{{- $icebergMinSize := .Values.iceberg.config.size.reserved | default $defaultIcebergMinSize | int -}}
{{- $icebergPollingMillis := .Values.iceberg.config.millis | default $defaultIcebergPollingMillis -}}
{{- $icebergCompressionCodec := .Values.iceberg.config.codec | default $defaultIcebergCompressionCodec -}}
{{- $icebergFileFormat := .Values.iceberg.config.format | default $defaultIcebergFileFormat -}}

{{- $icebergS3Secret := "" -}}
{{- $icebergS3URL := "" -}}
{{- $icebergS3BucketName := "" -}}

{{- if $icebergIsEnabled -}}
  {{- if and .Values.minio.enabled .Values.iceberg.s3.enabled -}}
    {{ fail "MinIO and AWS S3 iceberg deployments are mutually exclusive. Please enable only one." }}
  {{- else if .Values.minio.enabled -}}
    {{- $minioSize := .Values.minio.persistence.size | trimSuffix "Gi" | int -}}
    {{- $icebergMaxSize = mul $minioSize .Values.minio.replicas -}}
    {{- $icebergS3Secret = include "minio.secretName" .Subcharts.minio | required "Required value: MinIO credentials" -}}
    {{- $icebergS3BucketName = required "Required value: MinIO bucket name" (index .Values.minio.buckets 0).name -}}
    {{- $icebergS3URL = .Values.minio.service.port | default 9000 | printf "http://%s.%s:%v/" (include "minio.fullname" .Subcharts.minio ) .Release.Namespace -}}
  {{- else if .Values.iceberg.s3.enabled -}}
    {{- if or (empty .Values.iceberg.s3.aws.accesskey) (empty .Values.iceberg.s3.aws.secretkey) -}}
      {{- fail "Required value: AWS S3 credentials" -}}
    {{- end -}}
    {{- $icebergS3Secret = "resurface-s3-creds" -}}
    {{- $icebergS3BucketName = required "Required value: AWS S3 bucket unique name" .Values.iceberg.s3.bucketname -}}
    {{- $icebergS3URL = required "Required value: AWS region where the S3 bucket is deployed" .Values.iceberg.s3.aws.region | printf "https://s3.%s.amazonaws.com" -}}
  {{- else -}}
    {{- fail "An object storage provider must be enabled for Iceberg. Supported values are: minio, s3" -}}
  {{- end -}}

  {{- /* Define a minimum DB_HEAP size for Iceberg deployments. Less memory could result in unfulfilled queries due to lack of resources */ -}}
  {{- $dbHeap = max $dbHeap 8 -}}

  {{/* Iceberg validation */}}
  {{- if lt $icebergMaxSize $icebergMinSize -}}
    {{- printf "Iceberg storage size must be greater than the reserved storage size (Current size: %s, Reserved storage size: %s)" $icebergMaxSize $icebergMinSize | fail -}}
  {{- end -}}
  {{- if not (has $icebergCompressionCodec $validIcebergCompressionCodecs) -}}
    {{- join "," $validIcebergCompressionCodecs | cat "Unknown iceberg compression codec. Iceberg compression codec must be one of the following: " | fail -}}
  {{- end -}}
  {{- if not (has $icebergFileFormat $validIcebergFileFormats) -}}
    {{- join "," $validIcebergFileFormats | cat "Unknown iceberg file format. Iceberg file format must be one of the following: " | fail -}}
  {{- end -}}

{{- end -}}

{{- /* Defaults for container resources */ -}}
{{- $cpuRequest := .Values.custom.resources.cpu | default 6 -}}
{{- $memoryRequest := .Values.custom.resources.memory | default (add $dbSize $dbHeap) }}
          resources:
            requests:
              cpu: {{ $cpuRequest }}
              memory: {{ mul $unitsCF $memoryRequest | printf "%vGi" }}
          env:
            - name: DB_SIZE
              value: {{ mul $unitsCF $dbSize | printf "%dg" }}
            - name: DB_HEAP
              value: {{ mul $unitsCF $dbHeap | printf "%dg" }}
            - name: DB_SLABS
              value: {{ $dbSlabs | quote }}
            - name: SHARD_SIZE
              value: {{ mul $unitsCF $shardSize | printf "%dk" }}
            - name: POLLING_CYCLE
              value: {{ $pollingCycle | quote }}
            - name: TZ
              value: {{ $timezone | quote }}
            {{- if $icebergIsEnabled }}
            - name: ICEBERG_SIZE_MAX
              value: {{ mul $unitsCF $icebergMaxSize | printf "%dg" }}
            - name: ICEBERG_SIZE_RESERVED
              value: {{ mul $unitsCF $icebergMinSize | printf "%dg" }}
            - name: ICEBERG_S3_URL
              value: {{ $icebergS3URL | quote }}
            - name: ICEBERG_S3_USER
              valueFrom:
                secretKeyRef:
                  name: {{ $icebergS3Secret }}
                  key: rootUser
            - name: ICEBERG_S3_SECRET
              valueFrom:
                secretKeyRef:
                  name: {{ $icebergS3Secret }}
                  key: rootPassword
            - name: ICEBERG_S3_LOCATION
              value: {{ printf "s3a://%s/" $icebergS3BucketName }}
            - name: ICEBERG_POLLING_MILLIS
              value: {{ $icebergPollingMillis | quote }}
            - name: ICEBERG_FILE_FORMAT
              value: {{ $icebergFileFormat | quote }}
            - name: ICEBERG_COMPRESSION_CODEC
              value: {{ $icebergCompressionCodec | quote }}
            {{- end }}
  volumeClaimTemplates:
    - metadata:
        name: {{ include "resurface.fullname" . }}-pvc
      spec:
        {{- if not (empty $storageClassName) }}
        storageClassName: {{ $storageClassName }}
        {{- end }}
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: {{ mul $unitsCF $pvSize | printf "%vGi" }}
{{- end }}

{{/*
Coordinator config.properties
*/}}
{{- define "resurface.config.coordinator" -}}
coordinator=true
discovery.uri=http://localhost:7700
node-scheduler.include-coordinator=true
{{ if or .Values.ingress.tls.enabled (eq (default "" .Values.provider) "ibm-openshift") -}}
http-server.process-forwarded=true
http-server.authentication.allow-insecure-over-http=true
{{ include "resurface.config.auth" . -}}
{{- end }}
{{ include "resurface.config.common" . -}}
{{- end -}}

{{/*
Worker config.properties
*/}}
{{- define "resurface.config.worker" -}}
coordinator=false
discovery.uri=http://coordinator:7700
{{ include "resurface.config.common" . -}}
{{- end -}}

{{/*
Common config.properties for both coordinator and workers
*/}}
{{- define "resurface.config.common" -}}
http-server.http.port=7700

query.max-history=20
query.max-length=1000000
query.max-memory=1000MB
query.max-memory-per-node=1000MB
query.max-total-memory=1000MB
query.min-expire-age=1s
{{- end -}}

{{/*
Auth-related config.properties for the coordinator
*/}}
{{- define "resurface.config.auth" -}}
{{- if .Values.auth.enabled -}}
{{- $builder := list -}}
{{- if .Values.auth.oauth2.enabled -}}
  {{- $builder = append $builder "oauth2" -}}
{{- end -}}
{{- if .Values.auth.basic.enabled -}}
  {{- $builder = append $builder "PASSWORD" -}}
{{- end -}}
{{- if .Values.auth.jwt.enabled -}}
  {{- $builder = append $builder "JWT" -}}
{{- end -}}
http-server.authentication.type={{ join "," $builder | required "At least one authentication method must be enabled when auth is enabled." }}
{{- if .Values.auth.oauth2.enabled }}
web-ui.authentication.type=oauth2
http-server.authentication.oauth2.issuer={{ required "The service issuer URL is required for the OAuth2.0 configuration" .Values.auth.oauth2.issuer }}
http-server.authentication.oauth2.auth-url={{ required "The auth URL is required for the OAuth2.0 configuration" .Values.auth.oauth2.authurl }}
http-server.authentication.oauth2.token-url={{ required "The token URL is required for the OAuth2.0 configuration" .Values.auth.oauth2.tokenurl }}
http-server.authentication.oauth2.jwks-url={{ required "The jwks URL is required for the OAuth2.0 configuration" .Values.auth.oauth2.jwksurl }}
http-server.authentication.oauth2.userinfo-url={{ .Values.auth.oauth2.userinfourl }}
http-server.authentication.oauth2.client-id={{ required "The client ID is required for the OAuth2.0 configuration" .Values.auth.oauth2.clientid }}
http-server.authentication.oauth2.client-secret={{ required "The client secret is required for the OAuth2.0 configuration" .Values.auth.oauth2.clientsecret }}
{{- end -}}
{{- if .Values.auth.jwt.enabled }}
http-server.authentication.jwt.key-file={{ required "URL to a JWKS service or the path to a PEM or HMAC file is required for JWT configuration" .Values.auth.jwt.jwksurl }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Auth file
*/}}
{{- define "resurface.auth.creds" }}
{{- $builder := list -}}
{{- if and .Values.auth.enabled .Values.auth.basic.enabled -}}
{{- range $_, $v := .Values.auth.basic.credentials }}
  {{- $builder = append $builder (htpasswd $v.username $v.password | replace "$2a$" "$2y$" | println) -}}
{{ end -}}
{{ end -}}
{{ print (join "" $builder | b64enc) }}
{{- end }}

{{/*
Sniffer options
*/}}
{{- define "resurface.sniffer.options" -}}
{{- if .Values.sniffer.enabled -}}

{{- $inflag := "--input-raw" }}
{{- $nocapflag := "--input-raw-k8s-nomatch-nocap" }}
{{- $ignoredevflag := "--input-raw-ignore-interface"}}
{{- $skipnsflag := "--input-raw-k8s-skip-ns" }}
{{- $skipsvcflag := "--input-raw-k8s-skip-svc" }}
{{- $services := .Values.sniffer.services }}
{{- $pods := .Values.sniffer.pods }}
{{- $labels := .Values.sniffer.labels }}
{{- $skipns := .Values.sniffer.discovery.skip.ns -}}
{{- $skipsvc := .Values.sniffer.discovery.skip.svc -}}
{{- $ignoredev := .Values.sniffer.ignore | default (list "lo" "cbr0") }}
{{- $builder := list -}}

{{- if and .Values.sniffer.discovery.enabled (empty $services) -}}
  {{- $builder = append $builder (printf "%s %s" $inflag "k8s://service:") -}}
{{- else -}}
  {{- $svcnonamens := dict -}}
  {{- range $_, $svc := $services }}
    {{- if not $svc.name -}}
      {{- $svcnonamens = set $svcnonamens $svc.namespace (join "," $svc.ports) -}}
    {{- else if not (hasKey $svcnonamens $svc.namespace) -}}
      {{- $builder = append $builder (printf "%s k8s://%s/service/%s:%s" $inflag $svc.namespace $svc.name (join "," $svc.ports)) -}}
    {{- end -}}
  {{- end -}}
  {{- if .Values.sniffer.discovery.enabled -}}
    {{- range $ns, $ports := $svcnonamens -}}
      {{- $builder = append $builder (printf "%s k8s://%s/service:%s" $inflag $ns $ports) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if .Values.sniffer.discovery.enabled -}}
  {{- range $_, $ns := $skipns -}}
    {{- $builder = append $builder (printf "%s %s" $skipnsflag $ns) -}}
  {{- end -}}
  {{- range $_, $svc := $skipsvc -}}
    {{- $builder = append $builder (printf "%s %s" $skipsvcflag $svc) -}}
  {{- end -}}
  {{- $builder = append $builder (printf "%s %s" $skipnsflag .Release.Namespace) -}}
{{- end -}}

{{/*- $podnonamens := dict -*/}}
{{- range $_, $pod := $pods }}
  {{- $builder = append $builder (printf "%s k8s://%s/pod/%s:%s" $inflag $pod.namespace $pod.name (join "," $pod.ports)) -}}
  {{/*- if not $pod.name -}}
    {{- $podnonamens = set $podnonamens $pod.namespace (join "," $pod.ports) -}}
  {{- else if not (hasKey $podnonamens $pod.namespace) -}}
    # {{- $builder = append $builder (printf "%s k8s://%s/pod/%s:%s" $inflag $pod.namespace $pod.name (join "," $pod.ports)) -}}
  {{- end -*/}}
{{- end -}}
{{/*- if .Values.sniffer.discovery.pod.enabled -}}
  {{- range $ns, $ports := $podnonamens -}}
    {{- $builder = append $builder (printf "%s k8s://%s/pod:%s" $inflag $ns $ports) -}}
  {{- end -}}
{{- end -*/}}

{{- range $_, $lbl := $labels -}}
  {{- if empty $lbl.namespace -}}
    {{- $builder = append $builder (printf "%s k8s://labelSelector/%s:%s" $inflag (join "," $lbl.keyvalues) (join "," $lbl.ports)) -}}
  {{- else -}}
    {{- $builder = append $builder (printf "%s k8s://%s/labelSelector/%s:%s" $inflag $lbl.namespace (join "," $lbl.keyvalues) (join "," $lbl.ports)) -}}
  {{- end -}}
{{- end -}}

{{- if empty $builder -}}
{{ print "" }}
{{- else -}}
{{- $devs := list -}}
{{- range $_, $dev := $ignoredev -}}
  {{- $devs = append $devs (printf "%s %s" $ignoredevflag $dev) -}}
{{- end -}}
{{ printf "'%s %s %s'" (join " " $builder) $nocapflag (join " " $devs) }}
{{- end -}}

{{- end -}}
{{- end }}


{{/*
Sniffer.mirror options
*/}}
{{- define "resurface.sniffer.mirror.options" -}}
{{- if and .Values.sniffer.vpcmirror.enabled (default "" .Values.provider | eq "aws") | and .Values.sniffer.enabled -}}
{{- $inflag := "--input-raw" }}
{{- $engineflag := "--input-raw-engine"}}
{{- $vniflag := "--input-raw-vxlan-vni" }}
{{- $vxlanportflag := "--input-raw-vxlan-port" }}
{{- $mirrorports := join "," .Values.sniffer.vpcmirror.ports }}
{{- $vxlanport := default 4789 .Values.sniffer.vpcmirror.vxlanport }}
{{- $builder := list -}}
{{- range $_, $vni := .Values.sniffer.vpcmirror.vnis -}}
  {{- $builder = append $builder (printf " %s %v" $vniflag $vni) -}}
{{- end -}}
{{ printf "'%s :%s %s vxlan %s %v%s'" $inflag (required "At least one port must be specified for AWS VPC mirrored traffic capture" $mirrorports) $engineflag $vxlanportflag $vxlanport (join "" $builder) }}
{{- end -}}
{{- end }}
