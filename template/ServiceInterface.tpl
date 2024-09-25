{{ define "ServiceInterface" }}
package {{.Package}}

import (
    "context"
    "gofastddd/internal/contextx"

    {{$modelPkg :=  print .QueryStructName "Model"}}
    {{$modelPkg}} "{{.TemplatePkgPath.Model}}"
    {{$typesPkg := print .QueryStructName "Types"}}
    {{$typesPkg}} "{{.TemplatePkgPath.Types}}"
    {{$beanPkg := print .QueryStructName "Bean"}}
    {{$beanPkg}} "{{.TemplatePkgPath.Bean}}"
)
type Service interface {
    Search(ctx context.Context, appCtx *contextx.AppContext, vo *{{$typesPkg}}.SearchVO) (*{{$typesPkg}}.PageData, error)
    Find(ctx context.Context, appCtx *contextx.AppContext, vo *{{$typesPkg}}.FindVO) ({{$beanPkg}}.{{.ModelStructName}}DTOList, error)
	Create(ctx context.Context, appCtx *contextx.AppContext, po *{{$typesPkg}}.Create{{.ModelStructName}}PO) (int64, error)
	Update(ctx context.Context, appCtx *contextx.AppContext, id int64, po *{{$typesPkg}}.Update{{.ModelStructName}}PO) error
	TaskOrFail(ctx context.Context, appCtx *contextx.AppContext, id int64) (*{{$beanPkg}}.{{.ModelStructName}}DTO, error)
	Task(ctx context.Context, appCtx *contextx.AppContext, id int64) (*{{$beanPkg}}.{{.ModelStructName}}DTO, bool, error)
}
{{ end }}