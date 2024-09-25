{{ define "Mapper" }}
package {{.Package}}

import (
    "github.com/pkg/errors"
    "gorm.io/gorm"
    "gorm.io/gorm/clause"
    "gofastddd/internal/utils/pagination"

    {{$modelPkg :=  print .QueryStructName "Model"}}
    {{$modelPkg}} "{{.TemplatePkgPath.Model}}"
    {{$typesPkg := print .QueryStructName "Types"}}
    {{$typesPkg}} "{{.TemplatePkgPath.Types}}"
)

type mapper struct {
}

func New() Mapper {
	return &mapper{}
}


func (m *mapper) Create(db *gorm.DB, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error) {
	err := db.Create(model).Error
	if err != nil {
		return 0, errors.WithStack(err)
	}
	return model.ID, nil
}

func (m *mapper) Update(db *gorm.DB, id int64, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error) {
	expr := clause.Eq{Column: "id", Value: id}
	return m.updateByExpr(db, expr, model)
}

func (m *mapper) UpdateMap(db *gorm.DB, id int64, upo map[string]any) (int64, error) {
	cond := clause.Eq{Column: "id", Value: id}
	return m.updateMapByExpr(db, cond, upo)
}

func (m *mapper) Task(db *gorm.DB, id int64) (*{{$modelPkg}}.{{.ModelStructName}}, bool, error) {
	expr := clause.Eq{Column: "id", Value: id}
	return m.taskByExpr(db, expr)
}

func (m *mapper) Search(db *gorm.DB, searchVO *{{$typesPkg}}.SearchVO) ([]*{{$modelPkg}}.{{.ModelStructName}}, int64, error) {
	expr := searchVO.GetExpr()
	return m.search(db, expr, &searchVO.Pagination)
}

func (m *mapper) Find(db *gorm.DB, vo *{{$typesPkg}}.FindVO) ([]*{{$modelPkg}}.{{.ModelStructName}}, error) {
	return m.findByExpr(db, vo.GetExpr())
}

func (m *mapper) FindIDList(db *gorm.DB, vo *{{$typesPkg}}.FindVO, skip ...int) ([]int64, error) {
	var IDList []int64
	limit := pagination.MaxPageSize
	if len(skip) > 0 {
		limit = skip[0]
	}
	err := db.Model(&{{$modelPkg}}.{{.ModelStructName}}{}).Where(vo.GetExpr()).Limit(limit).Pluck("id", &IDList).Error
	if err != nil {
		return nil, errors.WithStack(err)
	}
	return IDList, nil
}

func (m *mapper) Find2Map(db *gorm.DB, vo *{{$typesPkg}}.FindVO) (map[int64]*{{$modelPkg}}.{{.ModelStructName}}, error) {
	list, err := m.findByExpr(db, vo.GetExpr())
	if err != nil {
		return nil, err
	}
	result := lo.SliceToMap(list, func(item *{{$modelPkg}}.{{.ModelStructName}}) (int64, *{{$modelPkg}}.{{.ModelStructName}}) {
		return item.ID, item
	})
	return result, err
}

func (m *mapper) FindByIdList(db *gorm.DB, idList []int64) ([]*{{$modelPkg}}.{{.ModelStructName}}, error) {
	return m.findByExpr(db, clause.IN{Column: "id", Values: lo.ToAnySlice(idList)})
}

func (m *mapper) search(db *gorm.DB,
	expr clause.Expression, pagination *pagination.Pagination) (
	[]*{{$modelPkg}}.{{.ModelStructName}}, int64, error) {
	query := db.Model(&{{$modelPkg}}.{{.ModelStructName}}{}).Where(expr)
	var count int64
	if err := query.Count(&count).Error; err != nil {
		return nil, 0, errors.WithStack(err)
	}
	var modelList []*{{$modelPkg}}.{{.ModelStructName}}
	if err := query.
		Offset(pagination.GetOffset()).
		Limit(pagination.GetLimit()).
		Order(pagination.GetOrderBy()).
		Find(&modelList).Error; err != nil {
		return nil, 0, errors.WithStack(err)
	}
	return modelList, count, nil
}

func (m *mapper) findByExpr(db *gorm.DB, expr clause.Expression, skip ...int) ([]*{{$modelPkg}}.{{.ModelStructName}}, error) {
	var modelList []*{{$modelPkg}}.{{.ModelStructName}}
	limit := pagination.MaxPageSize
	if len(skip) > 0 {
		limit = skip[0]
	}
	err := db.Model(&{{$modelPkg}}.{{.ModelStructName}}{}).Where(expr).Limit(limit).Find(&modelList).Error
	if err != nil {
		return nil, errors.WithStack(err)
	}
	return modelList, nil
}

func (m *mapper) updateMapByExpr(db *gorm.DB, expr clause.Expression, upo map[string]any) (int64, error) {
	result := db.Model(&{{$modelPkg}}.{{.ModelStructName}}{}).Where(expr).Updates(upo)
	err := result.Error
	if err != nil {
		return 0, errors.WithStack(err)
	}
	return result.RowsAffected, nil
}

func (m *mapper) updateByExpr(db *gorm.DB, expr clause.Expression, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error) {
	result := db.Where(expr).Updates(model)
	err := result.Error
	if err != nil {
		return 0, errors.WithStack(err)
	}
	return result.RowsAffected, nil
}

func (m *mapper) taskByExpr(db *gorm.DB, expr clause.Expression) (*{{$modelPkg}}.{{.ModelStructName}}, bool, error) {
	model := &{{$modelPkg}}.{{.ModelStructName}}{}
	err := db.Where(expr).First(model).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, errors.WithStack(err)
	}
	return model, true, nil
}

{{ end }}