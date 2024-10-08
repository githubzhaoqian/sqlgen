{{ define "Service" }}
package {{.Package}}

import (
    "gofastddd/internal/config"
    "context"
    "gofastddd/internal/contextx"
    "gofastddd/internal/utils/logx"
    "gofastddd/internal/common/code"
    "gofastddd/internal/utils/errorx"

    {{$modelPkg :=  print .QueryStructName "Model"}}
    {{$modelPkg}} "{{.TemplatePkgPath.Model}}"
    {{$typesPkg := print .QueryStructName "Types"}}
    {{$typesPkg}} "{{.TemplatePkgPath.Types}}"
    {{$beanPkg := print .QueryStructName "Bean"}}
    {{$beanPkg}} "{{.TemplatePkgPath.Bean}}"
    {{$mapperPkg := print .QueryStructName "Mapper"}}
    {{$mapperPkg}} "{{.TemplatePkgPath.Mapper}}"
)

type service struct {
    {{$mapperPkg}} {{$mapperPkg}}.Mapper
    cfg              *config.Config
}

func New(
    cfg *config.Config,
) Service {
	return &service{
	    {{$mapperPkg}}: {{$mapperPkg}}.New(),
	    cfg: cfg,
	}
}

// todo
// {{.ModelStructName}}SearchErr = 0
// {{.ModelStructName}}CreateErr = 0
// {{.ModelStructName}}UpdateErr = 0
// {{.ModelStructName}}NotExistErr = 0

// {{.ModelStructName}}SearchErr : "{{.TableComment}}查询失败"
// {{.ModelStructName}}CreateErr : "{{.TableComment}}创建失败"
// {{.ModelStructName}}UpdateErr : "{{.TableComment}}更新失败"
// {{.ModelStructName}}NotExistErr : "{{.TableComment}}不存在"
func (s *service) Search(ctx context.Context, appCtx *contextx.AppContext, vo *{{$typesPkg}}.SearchVO) (*{{$typesPkg}}.PageData, error) {
    daoList, total, err := s.{{$mapperPkg}}.Search(appCtx.DB, vo)
    if err != nil {
        logx.Errorf(ctx, "mapper.Search err: %+v", err)
        return nil, errorx.NewErr(code.{{.ModelStructName}}SearchErr)
    }
    return &{{$typesPkg}}.PageData{
        Total: total,
        List:  {{$beanPkg}}.{{.ModelStructName}}DTOListFromModelList(daoList),
    }, nil
}

func (s *service) Find(ctx context.Context, appCtx *contextx.AppContext, vo *{{$typesPkg}}.FindVO) ({{$beanPkg}}.{{.ModelStructName}}DTOList, error) {
   daoList, err := s.{{$mapperPkg}}.Find(appCtx.DB, vo)
       if err != nil {
           logx.Errorf(ctx, "mapper.Find err: %+v", err)
           return nil, errorx.NewErr(code.{{.ModelStructName}}SearchErr)
       }
       return {{$beanPkg}}.{{.ModelStructName}}DTOListFromModelList(daoList), nil
}

func (s *service) Create(ctx context.Context, appCtx *contextx.AppContext, po *{{$beanPkg}}.Save{{.ModelStructName}}PO) (int64, error) {
   model := po.ToModel()
   	id, err := s.{{$mapperPkg}}.Create(appCtx.DB, model)
   	if err != nil {
   		logx.Errorf(ctx, "mapper.Create err:%+v", err)
   		return 0, errorx.NewErr(code.{{.ModelStructName}}CreateErr)
   	}
   	return id, nil
}

func (s *service) Update(ctx context.Context, appCtx *contextx.AppContext, id int64, po *{{$beanPkg}}.Save{{.ModelStructName}}PO) error {
    	model := po.ToModel()
    	_, err := s.{{$mapperPkg}}.Update(appCtx.DB, id, model)
    	if err != nil {
    		logx.Errorf(ctx, "mapper.Update err:%+v", err)
    		return errorx.NewErr(code.{{.ModelStructName}}UpdateErr)
    	}
    	return nil
}

func (s *service) TaskOrFail(ctx context.Context, appCtx *contextx.AppContext, id int64) (*{{$beanPkg}}.{{.ModelStructName}}DTO, error) {
    dto, exist, err := s.Task(ctx, appCtx, id)
    if err != nil {
        return nil, err
    }
    if !exist {
        return nil, errorx.NewErr(code.{{.ModelStructName}}NotExistErr)
    }
    return dto, nil
}

func (s *service) Task(ctx context.Context, appCtx *contextx.AppContext, id int64) (*{{$beanPkg}}.{{.ModelStructName}}DTO, bool, error) {
    model, exist, err := s.{{$mapperPkg}}.GetByID(appCtx.DB, id)
    	if err != nil {
    		logx.Errorf(ctx, "mapper.Task err:%+v", err)
    		return nil, false, errorx.NewErr(code.{{.ModelStructName}}SearchErr)
    	}
    	dto := {{$beanPkg}}.{{.ModelStructName}}DTOFromModel(model)
    	return dto, exist, nil
}

{{ end }}