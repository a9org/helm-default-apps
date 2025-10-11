{{- define "app.name" -}}
my-web-app
{{- end }}

{{- define "app.fullname" -}}
{{- printf "%s" (include "app.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
