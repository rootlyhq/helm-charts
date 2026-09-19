{{/* Expand the chart name. */}}
{{- define "rootly-private-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create a fully qualified app name. */}}
{{- define "rootly-private-agent.fullname" -}}
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

{{- define "rootly-private-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "rootly-private-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rootly-private-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "rootly-private-agent.labels" -}}
helm.sh/chart: {{ include "rootly-private-agent.chart" . }}
{{ include "rootly-private-agent.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: rootly-private-connect
{{- end }}

{{- define "rootly-private-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rootly-private-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "rootly-private-agent.enrollmentSecretName" -}}
{{- default (include "rootly-private-agent.fullname" .) .Values.enrollment.existingSecret }}
{{- end }}

{{- define "rootly-private-agent.credentialClaimName" -}}
{{- default (include "rootly-private-agent.fullname" .) .Values.persistence.existingClaim }}
{{- end }}

{{- define "rootly-private-agent.agentName" -}}
{{- default (include "rootly-private-agent.fullname" .) .Values.agent.name }}
{{- end }}

{{- define "rootly-private-agent.providerID" -}}
{{- default (include "rootly-private-agent.agentName" .) .Values.providers.kubernetes.id }}
{{- end }}

{{- define "rootly-private-agent.image" -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) -}}
{{- end -}}
{{- end }}

{{- define "rootly-private-agent.validateValues" -}}
{{- if ne (int .Values.replicaCount) 1 }}
{{- fail "replicaCount must be 1 because one installation owns one durable agent identity" }}
{{- end }}
{{- if and .Values.agent.controlPlaneEnabled (not .Values.enrollment.token) (not .Values.enrollment.existingSecret) }}
{{- fail "enrollment.token or enrollment.existingSecret is required when agent.controlPlaneEnabled is true" }}
{{- end }}
{{- if and .Values.providers.kubernetes.enabled (not .Values.serviceAccount.create) (eq .Values.serviceAccount.name "") }}
{{- fail "serviceAccount.name is required when Kubernetes is enabled and serviceAccount.create is false" }}
{{- end }}
{{- if and .Values.rbac.create (not .Values.providers.kubernetes.enabled) }}
{{- fail "rbac.create must be false when the Kubernetes provider is disabled" }}
{{- end }}
{{- end }}
