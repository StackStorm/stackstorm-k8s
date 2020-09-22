# Expand the name of the chart.
{{- define "stackstorm-ha.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

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
{{- else if .Values.image.repository -}}
{{ .Values.image.repository }}
{{- else -}}
stackstorm
{{- end -}}
{{- end -}}

{{/*
Create the name of the stackstorm-ha service account to use
*/}}
{{- define "stackstorm-ha.serviceAccountName" -}}
{{- default .Chart.Name .Values.serviceAccount.serviceAccountName -}}
{{- end -}}

# Generate '-enterprise' suffix only when it's needed for resource names, docker images, etc
{{- define "enterpriseSuffix" -}}
{{ if required "Missing context '.Values.enterprise.enabled'!" .Values.enterprise.enabled }}-enterprise{{ end }}
{{- end -}}

# Generate '-' prefix only when the variable is defined
{{- define "hyphenPrefix" -}}
{{ if . }}-{{ . }}{{end}}
{{- end -}}

# Allow calling helpers from nested sub-chart
# https://stackoverflow.com/a/52024583/4533625
# https://github.com/helm/helm/issues/4535#issuecomment-477778391
# Usage: "{{ include "nested" (list . "mongodb-ha" "mongodb-replicaset.fullname") }}"
{{- define "nested" }}
{{- $dot := index . 0 }}
{{- $subchart := index . 1 | splitList "." }}
{{- $template := index . 2 }}
{{- $values := $dot.Values }}
{{- range $subchart }}
{{- $values = index $values . }}
{{- end }}
{{- include $template (dict "Chart" (dict "Name" (last $subchart)) "Values" $values "Release" $dot.Release "Capabilities" $dot.Capabilities) }}
{{- end }}

# Generate comma-separated list of nodes for MongoDB-HA connection string, based on number of replicas and service name
{{- define "mongodb-ha-nodes" -}}
{{- $replicas := (int (index .Values "mongodb-ha" "replicas")) }}
{{- $mongo_fullname := include "nested" (list $ "mongodb-ha" "mongodb-replicaset.fullname") }}
  {{- range $index0 := until $replicas -}}
    {{- $index1 := $index0 | add1 -}}
{{ $mongo_fullname }}-{{ $index0 }}.{{ $mongo_fullname }}{{ if ne $index1 $replicas }},{{ end }}
  {{- end -}}
{{- end -}}

{{- define "packs-volumes" -}}
{{- if .Values.st2.packs.image.repository }}
- name: st2-packs-vol
  emptyDir: {}
- name: st2-virtualenvs-vol
  emptyDir: {}
{{- else if .Values.st2.packs.nfs.server }}
- name: st2-packs-vol
  nfs:
    server: {{ .Values.st2.packs.nfs.server }}
    path: {{ .Values.st2.packs.nfs.packsPath }}
- name: st2-virtualenvs-vol
  nfs:
    server: {{ .Values.st2.packs.nfs.server }}
    path: {{ .Values.st2.packs.nfs.virtualenvsPath }}
{{- end }}
{{- end -}}
