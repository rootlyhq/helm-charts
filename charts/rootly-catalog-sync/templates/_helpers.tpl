{{/*
Expand the name of the chart.
*/}}
{{- define "rootly-catalog-sync.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "rootly-catalog-sync.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rootly-catalog-sync.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "rootly-catalog-sync.labels" -}}
helm.sh/chart: {{ include "rootly-catalog-sync.chart" . }}
{{ include "rootly-catalog-sync.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "rootly-catalog-sync.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rootly-catalog-sync.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "rootly-catalog-sync.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rootly-catalog-sync.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Secret name for the API key.
*/}}
{{- define "rootly-catalog-sync.secretName" -}}
{{- if .Values.rootly.existingSecret }}
{{- .Values.rootly.existingSecret }}
{{- else }}
{{- include "rootly-catalog-sync.fullname" . }}
{{- end }}
{{- end }}

{{/*
Config ConfigMap name.
*/}}
{{- define "rootly-catalog-sync.configMapName" -}}
{{- if .Values.existingConfigMap }}
{{- .Values.existingConfigMap }}
{{- else }}
{{- printf "%s-config" (include "rootly-catalog-sync.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Data ConfigMap name.
*/}}
{{- define "rootly-catalog-sync.dataConfigMapName" -}}
{{- if .Values.existingDataConfigMap }}
{{- .Values.existingDataConfigMap }}
{{- else }}
{{- printf "%s-data" (include "rootly-catalog-sync.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Sync command args.
*/}}
{{- define "rootly-catalog-sync.syncArgs" -}}
{{- if eq .Values.mode "watch" }}
- watch
- --interval={{ .Values.watch.interval }}
{{- else }}
- sync
{{- end }}
- --config=/config/rootly-catalog-sync.yaml
{{- if .Values.sync.allowPrune }}
- --allow-prune
- --prune-threshold={{ .Values.sync.pruneThreshold }}
{{- end }}
{{- end }}

{{/*
Pod template spec (shared between CronJob and Deployment).
*/}}
{{- define "rootly-catalog-sync.podSpec" -}}
serviceAccountName: {{ include "rootly-catalog-sync.serviceAccountName" . }}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers:
  - name: catalog-sync
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    args:
      {{- include "rootly-catalog-sync.syncArgs" . | nindent 6 }}
    env:
      - name: ROOTLY_API_KEY
        valueFrom:
          secretKeyRef:
            name: {{ include "rootly-catalog-sync.secretName" . }}
            key: {{ .Values.rootly.secretKey }}
      {{- if .Values.rootly.apiUrl }}
      - name: ROOTLY_API_URL
        value: {{ .Values.rootly.apiUrl | quote }}
      {{- end }}
      {{- if .Values.rootly.apiPath }}
      - name: ROOTLY_API_PATH
        value: {{ .Values.rootly.apiPath | quote }}
      {{- end }}
      {{- with .Values.extraEnv }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    {{- with .Values.securityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      - name: config
        mountPath: /config
        readOnly: true
      {{- if or .Values.dataFiles .Values.existingDataConfigMap }}
      - name: data
        mountPath: /data
        readOnly: true
      {{- end }}
      {{- with .Values.extraVolumeMounts }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
volumes:
  - name: config
    configMap:
      name: {{ include "rootly-catalog-sync.configMapName" . }}
  {{- if or .Values.dataFiles .Values.existingDataConfigMap }}
  - name: data
    configMap:
      name: {{ include "rootly-catalog-sync.dataConfigMapName" . }}
  {{- end }}
  {{- with .Values.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Validate required values.
*/}}
{{- define "rootly-catalog-sync.validateValues" -}}
{{- if and (not .Values.rootly.apiKey) (not .Values.rootly.existingSecret) }}
{{- fail "rootly.apiKey or rootly.existingSecret is required" }}
{{- end }}
{{- if and (not .Values.configYaml) (not .Values.existingConfigMap) }}
{{- fail "configYaml or existingConfigMap is required" }}
{{- end }}
{{- end }}
