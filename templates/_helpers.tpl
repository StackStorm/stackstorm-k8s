{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.image.repository (printf "%s:%s" .Values.secrets.st2.license .Values.secrets.st2.license | b64enc) | b64enc }}
{{- end }}
