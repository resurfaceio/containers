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
          resources:
            requests:
              cpu: {{ .Values.custom.resources.cpu | default 6 }}
              memory: {{ .Values.custom.resources.memory | default 12 | printf "%vGi" }}
          env:
            - name: DB_SIZE
              value: {{ .Values.custom.config.dbsize | default 9 | printf "%dg" }}
            - name: DB_HEAP
              value: {{ .Values.custom.config.dbheap | default 3 | printf "%dg" }}
            - name: DB_SLABS
              value: {{ .Values.custom.config.dbslabs | default 3 | quote }}
            {{- if .Values.custom.config.tz }}
            - name: TZ
              value: {{ .Values.custom.config.tz | quote }}
            {{- end}}
  volumeClaimTemplates:
    - metadata:
        name: {{ include "resurface.fullname" . }}-pvc
      spec:
        {{- $scndict := dict "azure" "managed-csi" "aws" "gp2" "gcp" "standard" }}
        {{- $scn := (.Values.custom.storage.classname | default (get $scndict (toString .Values.provider))) }}
        {{- if not (empty $scn) }}
        storageClassName: {{ $scn }}
        {{- end }}
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: {{ .Values.custom.storage.size | default 9 | printf "%vGi" }}
{{- end }}

{{/*
Common config.properties for both coordinator and workers
*/}}
{{- define "resurface.config.common" }}
http-server.http.port=7700
{{ if .Values.ingress.tls.enabled -}}
internal-communication.shared-secret={{ randAscii 32  | b64enc }}
{{ end -}}
query.max-history=20
query.max-length=1000000
query.max-memory=1000MB
query.max-memory-per-node=1000MB
query.max-total-memory=1000MB
query.min-expire-age=1s
{{- end }}

{{/*
Auth file
*/}}
{{- define "resurface.auth.creds" }}
{{- $builder := list -}}
{{- if .Values.auth.enabled -}}
{{- range $_, $v := .Values.auth.credentials }}
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
{{- $ignoredev := .Values.sniffer.ignore | default (list "eth0" "cbr0") }}
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
