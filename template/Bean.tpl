{{ define "Bean" }}
package {{.Package}}

{{$ModelStructName := .ModelStructName}}

import (
	"github.com/samber/lo"
	{{$modelPkg :=  print .QueryStructName "Model"}}
    {{$modelPkg}} "{{.TemplatePkgPath.Model}}"
    {{$constsPkg := print .QueryStructName "Consts"}}
    {{if .TemplatePkgPath.Consts -}}{{$constsPkg}} "{{.TemplatePkgPath.Consts}}"{{- end}}
    {{range .ImportPkgPaths}}"{{.}}"{{end}}
)

type {{$ModelStructName}}DTO struct {
{{range .Fields}}{{.Name}} {{.TypeName}}
{{end}}
}

{{range .Fields}}
    func (dto *{{$ModelStructName}}DTO)Get{{.Name}}() {{.TypeName}}{
        return dto.{{.Name}}
    }
{{end}}

func (dto *{{$ModelStructName}}DTO) ToModel() *{{$modelPkg}}.{{$ModelStructName}} {
	return &{{$modelPkg}}.{{$ModelStructName}}{
		{{range .Fields}}{{.Name}}: dto.{{.Name}},
		{{end}}
	}
}

func {{$ModelStructName}}DTOFromModel(model *{{$modelPkg}}.{{$ModelStructName}}) *{{$ModelStructName}}DTO {
    if model == nil {
		return nil
	}
	return &{{$ModelStructName}}DTO{
		{{range .Fields}}{{.Name}}: model.{{.Name}},
		{{end}}
	}
}

type {{$ModelStructName}}DTOList []*{{$ModelStructName}}DTO

func (i {{$ModelStructName}}DTOList) ToModelList() []*{{$modelPkg}}.{{$ModelStructName}} {
	list := lo.Map(i, func(item *{{$ModelStructName}}DTO, index int) *{{$modelPkg}}.{{$ModelStructName}} {
		return item.ToModel()
	})
	return list
}

func {{$ModelStructName}}DTOListFromModelList(list []*{{$modelPkg}}.{{$ModelStructName}}) {{$ModelStructName}}DTOList {
	dtoList := lo.Map(list, func(item *{{$modelPkg}}.{{$ModelStructName}}, index int) *{{$ModelStructName}}DTO {
		return {{$ModelStructName}}DTOFromModel(item)
	})
	return dtoList
}
{{ end }}