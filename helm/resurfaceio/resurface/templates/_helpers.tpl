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
Default options: container resources and persistent volumes
*/}}
{{- define "resurface.resources" }}
{{- $provider := toString .Values.provider -}}
{{- $cpureq := .Values.custom.resources.cpu | default 6 -}}
{{- $dbsize := .Values.custom.config.dbsize | default 9 | int -}}
{{- if eq $provider "azure" -}}
{{- $cpureq = sub $cpureq 1 -}}
{{- $dbsize = sub $dbsize 2 -}}
{{- end -}}
{{- $dbheap := .Values.custom.config.dbheap | default 3 | int -}}
{{- $dbslabs := .Values.custom.config.dbslabs | default 3 | int -}}
{{- $memreq := .Values.custom.resources.memory | default (add $dbsize $dbheap) }}
          resources:
            requests:
              cpu: {{ $cpureq }}
              memory: {{ printf "%vGi" $memreq }}
          env:
            - name: DB_SIZE
              value: {{ printf "%dg" $dbsize }}
            - name: DB_HEAP
              value: {{ printf "%dg" $dbheap }}
            - name: DB_SLABS
              value: {{ quote $dbslabs }}
            {{- if .Values.custom.config.tz }}
            - name: TZ
              value: {{ .Values.custom.config.tz | quote }}
            {{- end}}
  volumeClaimTemplates:
    - metadata:
        name: {{ include "resurface.fullname" . }}-pvc
      spec:
        {{- $scndict := dict "azure" "managed-csi" "aws" "gp2" "gcp" "standard" }}
        {{- $scn := (.Values.custom.storage.classname | default (get $scndict $provider)) }}
        {{- if not (empty $scn) }}
        storageClassName: {{ $scn }}
        {{- end }}
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: {{ .Values.custom.storage.size | default $dbsize | printf "%vGi" }}
{{- end }}

{{/*
Common config.properties for both coordinator and workers
*/}}
{{- define "resurface.config.common" -}}
internal-communication.shared-secret={{ randAscii 32 | b64enc }}
http-server.http.port=7700

query.max-history=20
query.max-length=1000000
query.max-memory=1000MB
query.max-memory-per-node=1000MB
query.max-total-memory=1000MB
query.min-expire-age=1s
{{- end }}

{{/*
Auth-related config.properties for the coordinator
*/}}
{{- define "resurface.config.auth" }}
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
{{- end }}

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
