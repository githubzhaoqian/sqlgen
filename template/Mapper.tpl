{{ define "Mapper" }}
package {{.Package}}

import (
    "github.com/pkg/errors"
    "gorm.io/gorm"
    "gorm.io/gorm/clause"
    "gofastddd/internal/consts"

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

func (m *mapper) BatchCreate(db *gorm.DB, modelList []*{{$modelPkg}}.{{.ModelStructName}}) error {
    err := db.CreateInBatches(modelList, consts.BatchCreateSize).Error
    if err != nil {
        return errors.WithStack(err)
    }
    return nil
}

func (m *mapper) Update(db *gorm.DB, id int64, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error) {
	expr := clause.Eq{Column: "id", Value: id}
	return m.updateByExpr(db, expr, model)
}

func (m *mapper) UpdateMap(db *gorm.DB, id int64, upo map[string]any) (int64, error) {
	cond := clause.Eq{Column: "id", Value: id}
	return m.updateMapByExpr(db, cond, upo)
}

func (m *mapper) BatchUpdate(db *gorm.DB, idList []int64, model *{{$modelPkg}}.{{.ModelStructName}}) (int64, error) {
	expr := clause.IN{Column: "id", Values: lo.ToAnySlice(idList)}
	return m.updateByExpr(db, expr, model)
}

func (m *mapper) BatchUpdateMap(db *gorm.DB, idList []int64, upo map[string]any) (int64, error) {
	expr := clause.IN{Column: "id", Values: lo.ToAnySlice(idList)}
	return m.updateMapByExpr(db, expr, upo)
}


func (m *mapper) GetByID(db *gorm.DB, id int64) (*{{$modelPkg}}.{{.ModelStructName}}, bool, error) {
	expr := clause.Eq{Column: "id", Value: id}
	return m.getByExpr(db, expr)
}

func (m *mapper) Search(db *gorm.DB, searchVO *{{$typesPkg}}.SearchVO) ([]*{{$modelPkg}}.{{.ModelStructName}}, int64, error) {
	expr := searchVO.GetExpr()
	return m.search(db, expr, searchVO.GetOffset(), searchVO.GetLimit(), searchVO.GetOrderBy())
}

func (m *mapper) Find(db *gorm.DB, vo *{{$typesPkg}}.FindVO) ([]*{{$modelPkg}}.{{.ModelStructName}}, error) {
	return m.findByExpr(db, vo.GetExpr())
}

func (m *mapper) FindIDList(db *gorm.DB, vo *{{$typesPkg}}.FindVO, skip ...int) ([]int64, error) {
	var IDList []int64
	err := db.Model(&{{$modelPkg}}.{{.ModelStructName}}{}).Where(vo.GetExpr()).Pluck("id", &IDList).Error
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

func (m *mapper) FindByIDList(db *gorm.DB, idList []int64) ([]*{{$modelPkg}}.{{.ModelStructName}}, error) {
	return m.findByExpr(db, clause.IN{Column: "id", Values: lo.ToAnySlice(idList)})
}

func (m *mapper) Count(db *gorm.DB, vo *{{$typesPkg}}.FindVO) (int64, error) {
	return m.count(db, vo.GetExpr())
}

func (m *mapper) Exist(db *gorm.DB, vo *{{$typesPkg}}.FindVO) (bool, error) {
	return m.exist(db, vo.GetExpr())
}

func (m *mapper) search(db *gorm.DB,
	expr clause.Expression, offset, limit int, orderBy string) (
	[]*{{$modelPkg}}.{{.ModelStructName}}, int64, error) {
	count, err := m.count(db, expr)
    if err != nil {
        return nil, 0, err
    }
    if count == 0 {
        return nil, 0, err
    }
    modelList, err := m.list(db, expr, offset, limit, orderBy)
    if err != nil {
        return nil, 0, errors.WithStack(err)
    }
	return modelList, count, nil
}

func (m *mapper) list(db *gorm.DB,
	expr clause.Expression, offset, limit int, orderBy string) (
	[]*{{$modelPkg}}.{{.ModelStructName}}, error) {
	query := db.Model(&{{$modelPkg}}.{{.ModelStructName}}{}).Where(expr)
	var modelList []*{{$modelPkg}}.{{.ModelStructName}}
	if err := query.
		Offset(offset).
		Limit(limit).
		Order(orderBy).
		Find(&modelList).Error; err != nil {
		return nil, errors.WithStack(err)
	}
	return modelList, nil
}

func (m *mapper) findByExpr(db *gorm.DB, expr clause.Expression, orderBy ...string) ([]*{{$modelPkg}}.{{.ModelStructName}}, error) {
	var modelList []*{{$modelPkg}}.{{.ModelStructName}}

	query := db.Model(&{{$modelPkg}}.{{.ModelStructName}}{}).Where(expr)
    if len(orderBy) > 0 {
        query = query.Order(orderBy[0])
    }
    err := query.Find(&modelList).Error

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

func (m *mapper) getByExpr(db *gorm.DB, expr clause.Expression) (*{{$modelPkg}}.{{.ModelStructName}}, bool, error) {
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

func (m *mapper) count(db *gorm.DB, expr clause.Expression) (int64, error) {
	query := db.Model(&{{$modelPkg}}.{{.ModelStructName}}{}).Where(expr)
	var count int64
	if err := query.Count(&count).Error; err != nil {
		return 0, errors.WithStack(err)
	}
	return count, nil
}

func (m *mapper) exist(db *gorm.DB, expr clause.Expression) (bool, error) {
	_, exist, err := m.getByExpr(db, expr)
	return exist, err
}

{{ end }}