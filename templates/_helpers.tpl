# Image pull secret used to access private docker.stackstorm.com Docker registry with Enterprise images
{{- define "imagePullSecret" }}
{{- if required "Missing context '.Values.enterprise.enabled'!" .Values.enterprise.enabled -}}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" "docker.stackstorm.com" (printf "%s:%s" .Values.enterprise.license .Values.enterprise.license | b64enc) | b64enc }}
{{- end -}}
{{- end }}

# Generate support method used in labels. This is based on community/enterprise
{{- define "supportMethod" -}}
{{- if required "Missing context '.Values.enterprise.enabled'!" .Values.enterprise.enabled -}}
enterprise
{{- else -}}
community
{{- end -}}
{{- end }}

# Generate Docker image repository: Private 'docker.stackstorm.com' for Enterprise vs Public Docker Hub 'stackstorm' for FOSS version
{{- define "imageRepository" -}}
{{- if required "Missing context '.Values.enterprise.enabled'!" .Values.enterprise.enabled -}}
docker.stackstorm.com
{{- else -}}
stackstorm
{{- end -}}
{{- end -}}

# Generate '-enterprise' suffix only when it's needed for resource names, docker images, etc
{{- define "enterpriseSuffix" -}}
{{ if required "Missing context '.Values.enterprise.enabled'!" .Values.enterprise.enabled }}-enterprise{{ end }}
{{- end -}}
