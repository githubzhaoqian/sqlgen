{{ define "Consts" }}

package {{.Package}}

{{$dynamicConstSuffixes := .DynamicConstSuffixes}}
{{range .Fields}}
    {{if suffixes .Name $dynamicConstSuffixes -}}
        type {{.Name}} {{.TypeName}}
    {{- end}}
{{end}}

{{ end }}