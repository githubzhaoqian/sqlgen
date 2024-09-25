{{ define "MapperInterface" }}
package {{.Package}}

import (
    "gorm.io/gorm"
    "gorm.io/gorm/clause"

    {{$modelPkg :=  print .QueryStructName "Model"}}
    {{$modelPkg}} "{{.TemplatePkgPath.Model}}"
    {{$typesPkg := print .QueryStructName "Types"}}
    {{$typesPkg}} "{{.TemplatePkgPath.Types}}"
)

type Mapper interface {
    Create(db *gorm.DB, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error)
    Update(db *gorm.DB, id int64, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error)
    UpdateMap(db *gorm.DB, id int64, upo map[string]any) (int64, error)
    Task(db *gorm.DB, id int64) (*{{$modelPkg}}.{{.ModelStructName}}, bool, error)
    Search(db *gorm.DB, searchVO *{{$typesPkg}}.SearchVO) ([]*{{$modelPkg}}.{{.ModelStructName}}, int64, error)
    Find(db *gorm.DB, vo *{{$typesPkg}}.FindVO) ([]*{{$modelPkg}}.{{.ModelStructName}}, error)
    FindIDList(db *gorm.DB, vo *{{$typesPkg}}.FindVO, skip ...int) ([]int64, error)
    Find2Map(db *gorm.DB, vo *{{$typesPkg}}.FindVO) (map[int64]*{{$modelPkg}}.{{.ModelStructName}}, error)
    FindByIdList(db *gorm.DB, idList []int64) ([]*{{$modelPkg}}.{{.ModelStructName}}, error)
    search(db *gorm.DB,expr clause.Expression, pagination *pagination.Pagination)
    findByExpr(db *gorm.DB, expr clause.Expression, skip ...int) ([]*{{$modelPkg}}.{{.ModelStructName}}, error)
    updateMapByExpr(db *gorm.DB, expr clause.Expression, upo map[string]any) (int64, error)
    updateByExpr(db *gorm.DB, expr clause.Expression, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error)
    taskByExpr(db *gorm.DB, expr clause.Expression) (*{{$modelPkg}}.{{.ModelStructName}}, bool, error)
}

{{ end }}