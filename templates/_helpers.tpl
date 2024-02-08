{{/*
Expand the name of the chart.
*/}}
{{- define "stackstorm-ha.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
Usage: "{{ include "stackstorm-ha.labels" (list $ "st2servicename") }}"
*/}}
{{- define "stackstorm-ha.labels" -}}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $valuesKey := regexReplaceAll "-.*" $name "" }}
{{- $appVersion := dig $valuesKey "image" "tag" ($root.Values.image.tag) ($root.Values|merge (dict)) }}
{{ include "stackstorm-ha.selectorLabels" . }}
{{- if list "st2web" "ingress" | has $name }}
app.kubernetes.io/component: frontend
{{- else if list "st2canary" "st2tests" | has $name }}
app.kubernetes.io/component: tests
{{- else }}
app.kubernetes.io/component: backend
{{- end }}
app.kubernetes.io/part-of: stackstorm
app.kubernetes.io/version: {{ tpl $appVersion $root | quote }}
helm.sh/chart: {{ $root.Chart.Name }}-{{ $root.Chart.Version }}
app.kubernetes.io/managed-by: {{ $root.Release.Service }}
{{- end -}}

{{/*
Selector labels
Usage: "{{ include "stackstorm-ha.selectorLabels" (list $ "st2servicename") }}"
*/}}
{{- define "stackstorm-ha.selectorLabels" -}}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
app.kubernetes.io/name: {{ $name }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
{{- end -}}

{{/*
Generate Docker utility image line
*/}}
{{- define "stackstorm-ha.utilityImage" -}}
{{- if .Values.image.utilityImage -}}
{{ .Values.image.utilityImage }}
{{- else -}}
docker.io/library/busybox:1.28
{{- end -}}
{{- end -}}


{{/*
Generate Docker image repository: Public Docker Hub 'stackstorm' for FOSS version
*/}}
{{- define "stackstorm-ha.imageRepository" -}}
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


{{/*
Create the name of the stackstorm-ha st2 auth secret to use
*/}}
{{- define "stackstorm-ha.secrets.st2Auth" -}}
{{- $name := print .Release.Name "-st2-auth" -}}
{{- default $name .Values.st2.existingAuthSecret -}}
{{- end -}}

{{/*
Create the name of the stackstorm-ha st2 datastore secret to use
*/}}
{{- define "stackstorm-ha.secrets.st2Datastore" -}}
{{- $name := print .Release.Name "-st2-datastore-crypto-key" -}}
{{- default $name .Values.st2.existingDatastoreSecret -}}
{{- end -}}


{{/*
Generate '-' prefix only when the variable is defined
*/}}
{{- define "stackstorm-ha.hyphenPrefix" -}}
{{ if . }}-{{ . }}{{end}}
{{- end -}}

{{/*
Allow calling helpers from nested sub-chart
https://stackoverflow.com/a/52024583/4533625
https://github.com/helm/helm/issues/4535#issuecomment-477778391
Usage: "{{ include "stackstorm-ha.nested" (list . "mongodb" "mongodb.fullname") }}"
*/}}
{{- define "stackstorm-ha.nested" }}
{{- $dot := index . 0 }}
{{- $subchart := index . 1 | splitList "." }}
{{- $template := index . 2 }}
{{- $values := $dot.Values }}
{{- range $subchart }}
{{- $values = index $values . }}
{{- end }}
{{- include $template (dict "Chart" (dict "Name" (last $subchart)) "Values" $values "Release" $dot.Release "Capabilities" $dot.Capabilities) }}
{{- end }}

{{/*
Generate comma-separated list of nodes for MongoDB-HA connection string, based on number of replicas and service name
*/}}
{{- define "stackstorm-ha.mongodb-nodes" -}}
{{- $replicas := (int (index .Values "mongodb" "replicaCount")) }}
{{- $architecture := (index .Values "mongodb" "architecture" ) }}
{{- $mongo_fullname := include "stackstorm-ha.nested" (list $ "mongodb" "mongodb.fullname") }}
{{- range $index0 := until $replicas -}}
  {{- $index1 := $index0 | add1 -}}
  {{- if eq $architecture "replicaset" }}
    {{- $mongo_fullname }}-{{ $index0 }}.{{ $mongo_fullname }}-headless.{{ $.Release.Namespace }}.svc.{{ $.Values.clusterDomain }}{{ if ne $index1 $replicas }},{{ end }}
  {{- else }}
    {{- $mongo_fullname }}-{{ $index0 }}.{{ $mongo_fullname }}{{ if ne $index1 $replicas }},{{ end }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate list of nodes for Redis with Sentinel connection string, based on number of replicas and service name
*/}}
{{- define "stackstorm-ha.redis-nodes" -}}
{{- if not .Values.redis.sentinel.enabled }}
{{- fail "value for redis.sentinel.enabled MUST be true" }}
{{- end }}
{{- $replicas := (int (index .Values "redis" "cluster" "slaveCount")) }}
{{- $master_name := (index .Values "redis" "sentinel" "masterSet") }}
{{- $sentinel_port := (index .Values "redis" "sentinel" "port") }}
{{- range $index0 := until $replicas -}}
  {{- if eq $index0 0 -}}
    {{ $.Release.Name }}-redis-node-{{ $index0 }}.{{ $.Release.Name }}-redis-headless.{{ $.Release.Namespace }}.svc.{{ $.Values.clusterDomain }}:{{ $sentinel_port }}?sentinel={{ $master_name }}
  {{- else -}}
    &sentinel_fallback={{ $.Release.Name }}-redis-node-{{ $index0 }}.{{ $.Release.Name }}-redis-headless.{{ $.Release.Namespace }}.svc.{{ $.Values.clusterDomain }}:{{ $sentinel_port }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "stackstorm-ha.redis-password" -}}
{{- if not .Values.redis.sentinel.enabled }}
{{- fail "value for redis.sentinel.enabled MUST be true" }}
{{- end }}
{{- if not (empty .Values.redis.password)}}:{{ .Values.redis.password }}@{{- end }}
{{- end -}}

{{/*
Reduce duplication of the st2.*.conf volume details
*/}}
{{- define "stackstorm-ha.st2-config-volume-mounts" -}}
- name: st2-config-vol
  mountPath: /etc/st2/st2.docker.conf
  subPath: st2.docker.conf
- name: st2-config-vol
  mountPath: /etc/st2/st2.user.conf
  subPath: st2.user.conf
{{- if $.Values.st2.existingConfigSecret }}
- name: st2-config-secrets-vol
  mountPath: /etc/st2/st2.secrets.conf
  subPath: st2.secrets.conf
{{- end }}
{{- end -}}
{{- define "stackstorm-ha.st2-config-volume" -}}
- name: st2-config-vol
  configMap:
    name: {{ $.Release.Name }}-st2-config
{{- if $.Values.st2.existingConfigSecret }}
- name: st2-config-secrets-vol
  secret:
    secretName: {{ $.Values.st2.existingConfigSecret }}
{{- end }}
{{- end -}}

# Override CMD CLI parameters passed to the startup of all pods to add support for /etc/st2/st2.secrets.conf
{{- define "stackstorm-ha.st2-config-file-parameters" -}}
- --config-file=/etc/st2/st2.conf
- --config-file=/etc/st2/st2.docker.conf
- --config-file=/etc/st2/st2.user.conf
{{- if $.Values.st2.existingConfigSecret }}
- --config-file=/etc/st2/st2.secrets.conf
{{- end }}
{{- end -}}

{{- define "stackstorm-ha.init-containers-wait-for-db" -}}
{{- if index .Values "mongodb" "enabled" }}
{{- $mongodb_port := (int (index .Values "mongodb" "service" "port")) }}
- name: wait-for-db
  image: {{ template "stackstorm-ha.utilityImage" . }}
  command:
    - 'sh'
    - '-c'
    - >
      until nc -z -w 2 {{ $.Release.Name }}-mongodb-headless {{ $mongodb_port }} && echo mongodb ok;
        do
          echo 'Waiting for MongoDB Connection...'
          sleep 2;
      done
  {{- with .Values.securityContext }}
  securityContext: {{- toYaml . | nindent 8 }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "stackstorm-ha.init-containers-wait-for-mq" -}}
  {{- if index .Values "rabbitmq" "enabled" }}
    {{- $rabbitmq_port := (int (index .Values "rabbitmq" "service" "port")) }}
- name: wait-for-queue
  image: {{ template "stackstorm-ha.utilityImage" . }}
  command:
    - 'sh'
    - '-c'
    - >
      until nc -z -w 2 {{ $.Release.Name }}-rabbitmq {{ $rabbitmq_port }} && echo rabbitmq ok;
        do
          echo 'Waiting for RabbitMQ Connection...'
          sleep 2;
      done
  {{- with .Values.securityContext }}
  securityContext: {{- toYaml . | nindent 8 }}
  {{- end }}
  {{- end }}
{{- end -}}

{{/*
consolidate pack-configs-volumes definitions
*/}}
{{- define "stackstorm-ha.pack-configs-volume" -}}
  {{- if and .Values.st2.packs.volumes.enabled .Values.st2.packs.volumes.configs }}
- name: st2-pack-configs-vol
  {{- toYaml .Values.st2.packs.volumes.configs | nindent 2 }}
  {{-   if .Values.st2.packs.configs }}
- name: st2-pack-configs-from-helm-vol
  configMap:
    name: {{ .Release.Name }}-st2-pack-configs
  {{-   end }}
  {{- else }}
- name: st2-pack-configs-vol
  configMap:
    name: {{ .Release.Name }}-st2-pack-configs
  {{- end }}
{{- end -}}
{{- define "stackstorm-ha.pack-configs-volume-mount" -}}
- name: st2-pack-configs-vol
  mountPath: /opt/stackstorm/configs/
  readOnly: false
  {{- if and .Values.st2.packs.volumes.enabled .Values.st2.packs.volumes.configs .Values.st2.packs.configs }}
- name: st2-pack-configs-from-helm-vol
  mountPath: /opt/stackstorm/configs-helm/
  {{- end }}
{{- end -}}

{{/*
For custom st2packs-Container reduce duplicity by defining it here once
*/}}
{{- define "stackstorm-ha.packs-volumes" -}}
  {{- if .Values.st2.packs.volumes.enabled }}
- name: st2-packs-vol
  {{- toYaml .Values.st2.packs.volumes.packs | nindent 2 }}
- name: st2-virtualenvs-vol
  {{- toYaml .Values.st2.packs.volumes.virtualenvs | nindent 2 }}
  {{- else if .Values.st2.packs.images }}
- name: st2-packs-vol
  emptyDir: {}
- name: st2-virtualenvs-vol
  emptyDir: {}
  {{- end }}
{{- end -}}
{{- define "stackstorm-ha.packs-volume-mounts" -}}
  {{- if .Values.st2.packs.volumes.enabled }}
- name: st2-packs-vol
  mountPath: /opt/stackstorm/packs
  readOnly: false
- name: st2-virtualenvs-vol
  mountPath: /opt/stackstorm/virtualenvs
  readOnly: false
  {{- else if .Values.st2.packs.images }}
- name: st2-packs-vol
  mountPath: /opt/stackstorm/packs
  readOnly: true
- name: st2-virtualenvs-vol
  mountPath: /opt/stackstorm/virtualenvs
  readOnly: true
  {{- end }}
{{- end -}}
{{/*
define this here as well to simplify comparison with packs-volume-mounts
*/}}
{{- define "stackstorm-ha.packs-volume-mounts-for-register-job" -}}
  {{- if or .Values.st2.packs.images .Values.st2.packs.volumes.enabled }}
- name: st2-packs-vol
  mountPath: /opt/stackstorm/packs
  readOnly: false
- name: st2-virtualenvs-vol
  mountPath: /opt/stackstorm/virtualenvs
  readOnly: false
  {{- end }}
{{- end -}}

#Inserted for override ability to happen via helm charts

{{- define "stackstorm-ha.overrides-config-mounts" -}}
  {{- if .Values.st2.overrides }}
- name: st2-overrides-vol
  mountPath: /opt/stackstorm/overrides
  {{- end }}
{{- end -}}

{{- define "stackstorm-ha.overrides-configs" -}}
  {{- if .Values.st2.overrides }}
- name: st2-overrides-vol
  configMap:
    name: {{ .Release.Name }}-st2-overrides-configs
  {{- end }}
{{- end -}}

{{/*
For custom st2packs-initContainers reduce duplicity by defining them here once
Merge packs and virtualenvs from st2 with those from st2packs images
*/}}
{{- define "stackstorm-ha.packs-initContainers" -}}
  {{- if $.Values.st2.packs.images }}
    {{- range $.Values.st2.packs.images }}
- name: 'st2-custom-pack-{{ printf "%s-%s" .repository .name | sha1sum }}'
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
  {{- with $.Values.securityContext }}
  securityContext: {{- toYaml . | nindent 8 }}
  {{- end }}
    {{- end }}
  {{- end }}
  {{- if or $.Values.st2.packs.images $.Values.st2.packs.volumes.enabled }}
# System packs
- name: st2-system-packs
  image: '{{ template "stackstorm-ha.imageRepository" . }}/st2actionrunner:{{ tpl (.Values.st2actionrunner.image.tag | default .Values.image.tag) . }}'
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
  {{- with .Values.securityContext }}
  securityContext: {{- toYaml . | nindent 8 }}
  {{- end }}
  {{- end }}
  {{- if and $.Values.st2.packs.configs $.Values.st2.packs.volumes.enabled $.Values.st2.packs.volumes.configs }}
# Pack configs defined in helm values
- name: st2-pack-configs-from-helm
  image: '{{ template "stackstorm-ha.imageRepository" . }}/st2actionrunner:{{ tpl (.Values.st2actionrunner.image.tag | default .Values.image.tag) . }}'
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  volumeMounts:
  - name: st2-pack-configs-vol
    mountPath: /opt/stackstorm/configs-shared
  - name: st2-pack-configs-from-helm-vol
    mountPath: /opt/stackstorm/configs
  command:
    - 'sh'
    - '-ec'
    - |
      /bin/cp -aR /opt/stackstorm/configs/. /opt/stackstorm/configs-shared
  {{- with .Values.securityContext }}
  securityContext: {{- toYaml . | nindent 8 }}
  {{- end }}
  {{- end }}
{{- end -}}

{{- define "stackstorm-ha.cleanup-packs" -}}
  {{- if or $.Values.st2.packs.images $.Values.st2.packs.volumes.enabled }}
# Clean Up packs - unregister packs no longer installed
- name: st2-cleanup-packs
  image: '{{ .Values.jobs.image.registry }}/sswann/jq:latest'
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  volumeMounts:
  - name: st2-packs-vol
    mountPath: /opt/stackstorm/packs-shared
  - name: st2-virtualenvs-vol
    mountPath: /opt/stackstorm/virtualenvs-shared
  - name: st2-cleanup-packs
    mountPath: /st2-cleanup-packs.sh
    subPath: st2-cleanup-packs.sh
  command:
    - 'sh'
    - '-ec'
    - /st2-cleanup-packs.sh
  {{- with .Values.securityContext }}
  securityContext: {{- toYaml . | nindent 8 }}
  {{- end }}
  envFrom:
  - secretRef:
      name: {{ include "stackstorm-ha.secrets.st2Auth" . }}
  env:
  - name: ST2_AUTH_URL
    value: "https://{{ .Release.Name }}-st2auth:9100"
  - name: ST2_API_URL
    value: "https://{{ .Release.Name }}-st2api:9111"
  {{- end }}
{{- end -}}

{{/*
For custom st2packs-pullSecrets reduce duplicity by defining them here once
*/}}
{{- define "stackstorm-ha.packs-pullSecrets" -}}
  {{- range $.Values.st2.packs.images }}
    {{- if .pullSecret }}
- name: {{ .pullSecret }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Create the custom env list for each deployment
*/}}
{{- define "stackstorm-ha.customEnv" -}}
  {{- range $env, $value := .env }}
- name: {{ $env | quote }}
  value: {{ $value | quote }}
  {{- end }}
{{- end -}}
