{{ define "Model" }}
{{$ModelStructName := .ModelStructName}}
{{$s := .S}}
{{$fieldWithTags := .FieldWithTags}}

package {{.Package}}

import (
    {{$constsPkg := print .QueryStructName "Consts"}}
    {{if .TemplatePkgPath.Consts -}}{{$constsPkg}} "{{.TemplatePkgPath.Consts}}"{{- end}}
	{{range .ImportPkgPaths}}"{{.}}"{{end}}
)

const Table = "{{.TableName}}"

// {{.ModelStructName}} {{.TableComment}}
type {{.ModelStructName}} struct {
    {{range .Fields}}{{$columnName := .ColumnName}}{{.Name}} {{.TypeName}} `gorm:"column:{{.ColumnName}};type:{{.ColumnType}};{{if not .Nullable -}}NOT NULL;{{- end}}{{if .DefaultValueOK -}}default:'{{.DefaultValue}}'{{- end}}"{{range $fieldWithTags}} {{.}}:"{{$columnName}}"{{end}}` {{if .Comment -}}// {{.Comment}}{{- end}}
    {{end}}
}

func ({{ $s }} *{{$ModelStructName}})TableName() string{
        return Table
}

{{range .Fields}}
    func ({{ $s }} *{{$ModelStructName}})Get{{.Name}}() {{.TypeName}}{
        return {{ $s }}.{{.Name}}
    }
{{end}}
{{ end }}