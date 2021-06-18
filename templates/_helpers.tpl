# Expand the name of the chart.
{{- define "stackstorm-ha.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

# Generate Docker image repository: Public Docker Hub 'stackstorm' for FOSS version
{{- define "imageRepository" -}}
{{- if .Values.image.repository -}}
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

# Generate '-' prefix only when the variable is defined
{{- define "hyphenPrefix" -}}
{{ if . }}-{{ . }}{{end}}
{{- end -}}

# Allow calling helpers from nested sub-chart
# https://stackoverflow.com/a/52024583/4533625
# https://github.com/helm/helm/issues/4535#issuecomment-477778391
# Usage: "{{ include "nested" (list . "mongodb" "mongodb.fullname") }}"
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
{{- define "mongodb-nodes" -}}
{{- $replicas := (int (index .Values "mongodb" "replicaCount")) }}
{{- $architecture := (index .Values "mongodb" "architecture" ) }}
{{- $mongo_fullname := include "nested" (list $ "mongodb" "mongodb.fullname") }}
{{- range $index0 := until $replicas -}}
  {{- $index1 := $index0 | add1 -}}
  {{- if eq $architecture "replicaset" }}
    {{- $mongo_fullname }}-{{ $index0 }}.{{ $mongo_fullname }}-headless{{ if ne $index1 $replicas }},{{ end }}
  {{- else }}
    {{- $mongo_fullname }}-{{ $index0 }}.{{ $mongo_fullname }}{{ if ne $index1 $replicas }},{{ end }}
  {{- end -}}
{{- end -}}
{{- end -}}

# Generate list of nodes for Redis with Sentinel connection string, based on number of replicas and service name
{{- define "redis-nodes" -}}
{{- if not .Values.redis.sentinel.enabled }}
{{- fail "value for redis.sentinel.enabled MUST be true" }}
{{- end }}
{{- $replicas := (int (index .Values "redis" "cluster" "slaveCount")) }}
{{- $master_name := (index .Values "redis" "sentinel" "masterSet") }}
{{- $sentinel_port := (index .Values "redis" "sentinel" "port") }}
{{- range $index0 := until $replicas -}}
  {{- if eq $index0 0 -}}
    {{ $.Release.Name }}-redis-node-{{ $index0 }}.{{ $.Release.Name }}-redis-headless:{{ $sentinel_port }}?sentinel={{ $master_name }}
  {{- else -}}
    &sentinel_fallback={{ $.Release.Name }}-redis-node-{{ $index0 }}.{{ $.Release.Name }}-redis-headless:{{ $sentinel_port }}
  {{- end -}}
{{- end -}}
{{- end -}}
    
{{- define "init-containers-wait-for-db" -}}
{{- if index .Values "mongodb" "enabled" }}
{{- $mongodb_port := (int (index .Values "mongodb" "service" "port")) }}
- name: wait-for-db
  image: busybox:1.28
  command:
    - 'sh'
    - '-c'
    - >
      until nc -z -w 2 {{ $.Release.Name }}-mongodb-headless {{ $mongodb_port }} && echo mongodb ok;
        do 
          echo 'Waiting for MongoDB Connection...'
          sleep 2;
      done
{{- end }}
{{- end -}}

{{- define "init-containers-wait-for-mq" -}}
  {{- if index .Values "rabbitmq" "enabled" }}
    {{- $rabbitmq_port := (int (index .Values "rabbitmq" "service" "port")) }}
- name: wait-for-queue
  image: busybox:1.28
  command:
    - 'sh'
    - '-c'
    - >
      until nc -z -w 2 {{ $.Release.Name }}-rabbitmq {{ $rabbitmq_port }} && echo rabbitmq ok;
        do
          echo 'Waiting for RabbitMQ Connection...'
          sleep 2;
      done
  {{- end }}
{{- end -}}

# For custom st2packs-Container reduce duplicity by defining it here once
{{- define "packs-volumes" -}}
  {{- if .Values.st2.packs.images }}
- name: st2-packs-vol
  emptyDir: {}
- name: st2-virtualenvs-vol
  emptyDir: {}
  {{- end }}
{{- end -}}

# For custom st2packs-initContainers reduce duplicity by defining them here once
# Merge packs and virtualenvs from st2 with those from st2packs images
{{- define "packs-initContainers" -}}
  {{- if $.Values.st2.packs.images }}
    {{- range $.Values.st2.packs.images }}
- name: 'st2-custom-pack-{{ printf "%s-%s-%s" .repository .name .tag | sha1sum }}'
  image: "{{ .repository }}/{{ .name }}:{{ .tag }}"
  imagePullPolicy: {{ .pullPolicy | quote }}
  volumeMounts:
  - name: st2-packs-vol
    mountPath: /opt/stackstorm/packs-shared
  - name: st2-virtualenvs-vol
    mountPath: /opt/stackstorm/virtualenvs-shared
  command:
    - 'sh'
    - '-ec'
    - |
      /bin/cp -aR /opt/stackstorm/packs/. /opt/stackstorm/packs-shared &&
      /bin/cp -aR /opt/stackstorm/virtualenvs/. /opt/stackstorm/virtualenvs-shared
    {{- end }}
# System packs
- name: st2-system-packs
  image: '{{ template "imageRepository" . }}/st2actionrunner:{{ .Chart.AppVersion }}'
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  volumeMounts:
  - name: st2-packs-vol
    mountPath: /opt/stackstorm/packs-shared
  - name: st2-virtualenvs-vol
    mountPath: /opt/stackstorm/virtualenvs-shared
  command:
    - 'sh'
    - '-ec'
    - |
      /bin/cp -aR /opt/stackstorm/packs/. /opt/stackstorm/packs-shared &&
      /bin/cp -aR /opt/stackstorm/virtualenvs/. /opt/stackstorm/virtualenvs-shared
  {{- end }}
{{- end -}}


# For custom st2packs-pullSecrets reduce duplicity by defining them here once
{{- define "packs-pullSecrets" -}}
  {{- range $.Values.st2.packs.images }}
    {{- if .pullSecret }}
- name: {{ .pullSecret }}
    {{- end }}
  {{- end }}
{{- end -}}
