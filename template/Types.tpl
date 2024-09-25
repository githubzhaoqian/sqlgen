{{ define "Types" }}

package {{.Package}}

import (
	"gofastddd/internal/utils/pagination"
	"gofastddd/internal/utils/builder"
	{{$beanPkg := print .QueryStructName "Bean"}}
    {{$beanPkg}} "{{.TemplatePkgPath.Bean}}"
)

type SearchVO struct {
	pagination.Pagination
	FindVO
}

type FindVO struct {
}

func (f *FindVO) GetExpr() clause.Expression {
	expr := builder.And()
	return expr
}

type Create{{.ModelStructName}}PO struct {
}

type Update{{.ModelStructName}}PO struct {
}

type PageData struct {
	List  {{$beanPkg}}.{{.ModelStructName}}DTOList // 列表
	Total int64                         // 总数
}

{{ end }}