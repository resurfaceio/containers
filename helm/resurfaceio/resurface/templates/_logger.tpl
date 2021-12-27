# Note: Invoking a subchart's named template is supported for Helm version >=3.7
# How to use this helper template:
# ...
# imagePullSecrets:
# - name: resurface-entitlement
# containers:
# {{- dict "rules" "include debug" "port" "8080" | set .Subcharts.resurface "loggerconfig" | include "resurface.logger"  | nindent 8 }}
# ...
# Replace "include debug", "8080", and 8, for your logging rules, application port and indentation respectively.

{{- define "resurface.logger" -}}
- name: resurface-logger
  image: docker.resurface.io/release/network-sniffer:1.0.0
  imagePullPolicy: IfNotPresent
  env:
  - name: USAGE_LOGGERS_URL
    value: {{ printf "http://%s:%v/message" (include "resurface.name" .) .Values.service.port.flukeServer }}
  - name: USAGE_LOGGERS_RULES
    value: {{ .loggerconfig.rules }}
  - name: APP_PORT
    value: {{ quote .loggerconfig.port }}
{{- end -}}
