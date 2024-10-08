{{ define "Types" }}

package {{.Package}}

import (
	"gofastddd/internal/utils/pagination"
	"gofastddd/internal/utils/builder"
	"gofastddd/internal/utils/timex"
	"github.com/samber/lo"
	{{$beanPkg := print .QueryStructName "Bean"}}
    {{$beanPkg}} "{{.TemplatePkgPath.Bean}}"
    {{$constsPkg := print .QueryStructName "Consts"}}
    {{if .TemplatePkgPath.Consts -}}{{$constsPkg}} "{{.TemplatePkgPath.Consts}}"{{- end}}
)

type SearchVO struct {
	pagination.PagePO
	FindVO
}

type FindVO struct {
    {{range .Fields -}}
        {{if contains .DatabaseTypeName "int" -}}
            {{.Name}} {{.TypeName}} // {{.Comment}}
            {{.Name}}List []{{.TypeName}} // {{.Comment}}列表
        {{ else if contains .DatabaseTypeName "varchar" -}}
            {{.Name}} {{.TypeName}}
        {{ else -}}
            // {{.Name}} {{.TypeName}} // {{.Comment}}
        {{ end -}}
    {{ end -}}
    UpdateTimeList []timex.Time     // 更新时间
    CreateTimeList []timex.Time     // 创建时间
    pagination.SortPO
}

func (f *FindVO) GetExpr() clause.Expression {
	expr := builder.And(
	    {{range .Fields -}}
	    {{if contains .DatabaseTypeName "int" -}}
            builder.If(f.{{.Name}} > 0,
                builder.Eq{Column: "{{.ColumnName}}", Value: f.{{.Name}}}),
            builder.If(len(f.{{.Name}}List) > 0,
                builder.IN{Column: "{{.ColumnName}}", Values: lo.ToAnySlice(f.{{.Name}}List)}),
        {{ else if contains .DatabaseTypeName "varchar" -}}
            builder.If(len(f.{{.Name}}) > 0,
                builder.Like{Column: "{{.ColumnName}}", Value: f.{{.Name}}}),
        {{ else -}}
            // {{.Name}} {{.TypeName}}
        {{ end -}}
        {{ end -}}
        builder.If(len(f.UpdateTimeList) > 0,
            builder.GteOrBetween{Column: "update_time", Values: lo.ToAnySlice(f.UpdateTimeList)}),
        builder.If(len(f.CreateTimeList) == 1,
            builder.GteOrBetween{Column: "update_time", Values: lo.ToAnySlice(f.CreateTimeList)}),
	)
	return expr
}

type PageData struct {
	List  {{$beanPkg}}.{{.ModelStructName}}DTOList // 列表
	Total int64                         // 总数
}

{{ end }}