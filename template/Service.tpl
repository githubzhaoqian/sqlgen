{{ define "Service" }}
package {{.Package}}

import (
    "gofastddd/internal/config"
    "context"
    "gofastddd/internal/contextx"
    "gofastddd/internal/utils/logx"

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
    mapper {{$mapperPkg}}.Mapper
    cfg              *config.Config
}

func New(
    cfg *config.Config,
) Service {
    mapper := {{$mapperPkg}}.New()
	return &service{
	    mapper: mapper,
	    cfg: config,
	}
}

// {{.ModelStructName}}SearchErr = 0
// {{.ModelStructName}}CreateErr = 0
// {{.ModelStructName}}UpdateErr = 0
// {{.ModelStructName}}NotExistErr = 0
func (s *service) Search(ctx context.Context, appCtx *contextx.AppContext, vo *{{$typesPkg}}.SearchVO) (*{{$typesPkg}}.PageData, error) {
    daoList, total, err := s.mapper.Search(appCtx.DB, vo)
    if err != nil {
        logx.Errorf(ctx, "mapper.Search err: %+v", err)
        // todo return nil, errorx.NewErr(code.{{.ModelStructName}}SearchErr)
        return nil, err
    }
    return &{{$typesPkg}}.PageData{
        Total: total,
        List:  {{$beanPkg}}.{{.ModelStructName}}DTOListFromModelList(daoList),
    }, nil
}

func (s *service) Find(ctx context.Context, appCtx *contextx.AppContext, vo *{{$typesPkg}}.FindVO) ({{$beanPkg}}.{{.ModelStructName}}DTOList, error) {
   daoList, total, err := s.mapper.Find(appCtx.DB, vo)
       if err != nil {
           logx.Errorf(ctx, "mapper.Find err: %+v", err)
           // todo return nil, errorx.NewErr(code.{{.ModelStructName}}SearchErr)
           return nil, err
       }
       return {{$beanPkg}}.{{.ModelStructName}}DTOListFromModelList(daoList), nil
}

func (s *service) Create(ctx context.Context, appCtx *contextx.AppContext, po *{{$typesPkg}}.Create{{.ModelStructName}}PO) (int64, error) {
   model := &{{$modelPkg}}.{{.ModelStructName}}{}
   	id, err := s.mapper.Create(appCtx.DB, model)
   	if err != nil {
   		logx.Errorf(ctx, "mapper.Create err:%+v", err)
   		// todo return 0, errorx.NewErr(code.{{.ModelStructName}}CreateErr)
   		return 0, err
   	}
   	return id, nil
}

func (s *service) Update(ctx context.Context, appCtx *contextx.AppContext, id int64, po *{{$typesPkg}}.Update{{.ModelStructName}}PO) error {
    	model := &{{$modelPkg}}.{{.ModelStructName}}{}
    	_, err := s.mapper.Update(appCtx.DB, id, model)
    	if err != nil {
    		logx.Errorf(ctx, "mapper.Update err:%+v", err)
    		// todo return errorx.NewErr(code.{{.ModelStructName}}UpdateErr)
    		return err
    	}
    	return nil
}

func (s *service) TaskOrFail(ctx context.Context, appCtx *contextx.AppContext, id int64) (*{{$beanPkg}}.{{.ModelStructName}}DTO, error) {
    dto, exist, err := s.Task(ctx, appCtx, id)
    if err != nil {
        return nil, err
    }
    if !exist {
        // todo return nil, errorx.NewErr(code.{{.ModelStructName}}NotExistErr)
        return nil, errors.New("not exist")
    }
    return dto, nil
}

func (s *service) Task(ctx context.Context, appCtx *contextx.AppContext, id int64) (*{{$beanPkg}}.{{.ModelStructName}}DTO, bool, error) {
    model, exist, err := s.mapper.Task(appCtx.DB, id)
    	if err != nil {
    		logx.Errorf(ctx, "mapper.Task err:%+v", err)
    		// todo return nil, false, errorx.NewErr(code.{{.ModelStructName}}rSearchErr)
    		return nil, false, err
    	}
    	dto := {{$beanPkg}}.{{.ModelStructName}}DtoFromModel(model)
    	return dto, exist, nil
}

{{ end }}