{{- define "imagePullSecret" }}
{{- if .Values.enterprise.enabled -}}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" "docker.stackstorm.com" (printf "%s:%s" .Values.enterprise.license .Values.enterprise.license | b64enc) | b64enc }}
{{- end -}}
{{- end }}

{{- define "supportMethod" }}
{{- if .Values.enterprise.enabled -}}
enterprise
{{- else -}}
community
{{- end -}}
{{- end }}

{{- define "imageRepository" }}
{{- if .Values.enterprise.enabled -}}
docker.stackstorm.com
{{- else -}}
stackstorm
{{- end -}}
{{- end -}}
