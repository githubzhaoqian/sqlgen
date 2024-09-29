{{ define "Types" }}

package {{.Package}}

import (
	"gofastddd/internal/utils/pagination"
	"gofastddd/internal/utils/builder"
	"gofastddd/internal/utils/timex"
	{{$beanPkg := print .QueryStructName "Bean"}}
    {{$beanPkg}} "{{.TemplatePkgPath.Bean}}"
)

type SearchVO struct {
	pagination.PagePO
	FindVO
}

type FindVO struct {
    IDList         []int64          // id 列表
    UpdateTimeList []timex.Time     // 更新时间
    CreateTimeList []timex.Time     // 创建时间
    pagination.SortPO
}

func (f *FindVO) GetExpr() clause.Expression {
	expr := builder.And()
	return expr
}

type PageData struct {
	List  {{$beanPkg}}.{{.ModelStructName}}DTOList // 列表
	Total int64                         // 总数
}

{{ end }}