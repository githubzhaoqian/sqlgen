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
    BatchCreate(db *gorm.DB, modelList []*{{$modelPkg}}.{{.ModelStructName}}) error
    Update(db *gorm.DB, id int64, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error)
    UpdateMap(db *gorm.DB, id int64, upo map[string]any) (int64, error)
    BatchUpdate(db *gorm.DB, idList []int64, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error)
    BatchUpdateMap(db *gorm.DB, idList []int64, upo map[string]any) (int64, error)
    GetByID(db *gorm.DB, id int64) (*{{$modelPkg}}.{{.ModelStructName}}, bool, error)
    Count(db *gorm.DB, vo *{{$typesPkg}}.FindVO) (int64, error)
    Exist(db *gorm.DB, vo *{{$typesPkg}}.FindVO) (bool, error)
    Search(db *gorm.DB, searchVO *{{$typesPkg}}.SearchVO) ([]*{{$modelPkg}}.{{.ModelStructName}}, int64, error)
    Find(db *gorm.DB, vo *{{$typesPkg}}.FindVO) ([]*{{$modelPkg}}.{{.ModelStructName}}, error)
    FindIDList(db *gorm.DB, vo *{{$typesPkg}}.FindVO, skip ...int) ([]int64, error)
    Find2Map(db *gorm.DB, vo *{{$typesPkg}}.FindVO) (map[int64]*{{$modelPkg}}.{{.ModelStructName}}, error)
    FindByIDList(db *gorm.DB, idList []int64) ([]*{{$modelPkg}}.{{.ModelStructName}}, error)
}

{{ end }}