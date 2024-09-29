{{ define "PO" }}
package {{.Package}}

{{$ModelStructName := .ModelStructName}}
{{$AutoValueFields := .AutoValueFields}}


import (
	"github.com/samber/lo"
	{{$modelPkg := print .QueryStructName "Model"}}
    {{$modelPkg}} "{{.TemplatePkgPath.Model}}"
    {{$constsPkg := print .QueryStructName "Consts"}}
    {{if .TemplatePkgPath.Consts -}}{{$constsPkg}} "{{.TemplatePkgPath.Consts}}"{{- end}}
    {{range .ImportPkgPaths}}"{{.}}"{{end}}
)

type Save{{$ModelStructName}}PO struct {
{{range .Fields}}{{$autoValueFields := inMap .Name $AutoValueFields}}{{if not $autoValueFields -}}{{.Name}} {{.TypeName}}{{- end}}
{{end}}
}

func (po *Save{{$ModelStructName}}PO) ToModel() *{{$modelPkg}}.{{$ModelStructName}} {
	return &{{$modelPkg}}.{{$ModelStructName}}{
		{{range .Fields}}{{$autoValueFields := inMap .Name $AutoValueFields}}{{if not $autoValueFields -}}{{.Name}}: po.{{.Name}},{{- end}}
		{{end}}
	}
}
{{ end }}