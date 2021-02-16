# Generate support method used in labels. This is based on community
{{- define "supportMethod" -}}
community
{{- end }}

# Generate Docker image repository: Public Docker Hub 'stackstorm' for FOSS version
{{- define "imageRepository" -}}
stackstorm
{{- end -}}

# Generate '-' prefix only when the variable is defined
{{- define "hyphenPrefix" -}}
{{ if . }}-{{ . }}{{end}}
{{- end -}}
