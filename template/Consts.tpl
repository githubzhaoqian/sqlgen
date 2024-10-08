{{ define "Consts" }}

package {{.Package}}

{{$dynamicConstSuffixes := .DynamicConstSuffixes}}
{{range .Fields}}
    {{if suffixes .Name $dynamicConstSuffixes -}}
        type {{.Name}} {{.TypeName}} // {{.Comment}}
    {{- end}}
{{end}}

{{ end }}