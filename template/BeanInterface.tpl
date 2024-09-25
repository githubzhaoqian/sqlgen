{{ define "BeanInterface" }}
package {{.Package}}

import (
	{{$modelPkg :=  print .QueryStructName "Model"}}
    {{$modelPkg}} "{{.TemplatePkgPath.Model}}"
)

type EventModeler interface {
    ToModel() *{{$modelPkg}}.{{.ModelStructName}}
}

type EventModelLister interface {
    ToModelList() []*{{$modelPkg}}.{{.ModelStructName}}
}
{{ end }}