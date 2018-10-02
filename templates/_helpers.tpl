{{- define "imagePullSecret" }}
{{- if .Values.enterprise.enabled -}}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.image.repository (printf "%s:%s" .Values.enterprise.license .Values.enterprise.license | b64enc) | b64enc }}
{{- end -}}
{{- end }}
