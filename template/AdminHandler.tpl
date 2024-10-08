{{ define "AdminHandler" }}
package {{.Package}}
import (
	"github.com/gin-gonic/gin"
    "gofastddd/internal/types/common"
    "gofastddd/internal/utils/errorx"
    "gofastddd/internal/utils/httpx"
    "gofastddd/internal/contextx"
    "gofastddd/internal/router/middleware"
    adminmenuc "gofastddd/internal/consts/adminmenu"

    {{$typesPkg := print .QueryStructName "Types"}}
    {{$typesPkg}} "{{.TemplatePkgPath.Types}}"

    {{$beanPkg := print .QueryStructName "Bean"}}
    {{$beanPkg}} "{{.TemplatePkgPath.Bean}}"

    {{$servicePkg := print .QueryStructName "Service"}}
    {{$servicePkg}} "{{.TemplatePkgPath.Service}}"
)

type handler struct {
	appCtxBox        *contextx.AppCtxBox
	adminAuthority   *middleware.AdminAuthority
	{{$servicePkg}} {{$servicePkg}}.Service
}

// todo
func New(
	appCtxBox *contextx.AppCtxBox,
	adminAuthority *middleware.AdminAuthority,
	{{$servicePkg}} {{$servicePkg}}.Service,
) Handler {
	return &handler{
		appCtxBox:        appCtxBox,
		adminAuthority:   adminAuthority,
		{{$servicePkg}}:  {{$servicePkg}},
	}
}

// todo
// {{.ModelStructName}}Search Permission = "{{ .QueryStructName }}Search"
// {{.ModelStructName}}Create Permission = "{{ .QueryStructName }}Create"
// {{.ModelStructName}}Update Permission = "{{ .QueryStructName }}Update"
// {{.ModelStructName}}View Permission = "{{ .QueryStructName }}View"

func (h *handler) Handle{{.ModelStructName}}API(g *gin.RouterGroup) {
	j := httpx.NewJSONHandler(g)
	j.POST("/search", h.handleSearch, h.adminAuthority.CheckPermission(adminmenuc.{{.ModelStructName}}Search))
	j.POST("", h.handleCreate, h.adminAuthority.CheckPermission(adminmenuc.{{.ModelStructName}}Create))
	j.PUT("/:ID", h.handleUpdate, h.adminAuthority.CheckPermission(adminmenuc.{{.ModelStructName}}Update))
	j.GET("/:ID", h.handleView, h.adminAuthority.CheckPermission(
		adminmenuc.{{.ModelStructName}}Create, adminmenuc.{{.ModelStructName}}Update, adminmenuc.{{.ModelStructName}}View))
}

// @Summary 搜索
// @Description 搜索
// @Tags {{.ModelStructName}}
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param body body {{ $typesPkg }}.SearchVO true "搜索参数"
// @Success 200 {object} httpx.Response{Data={{ $typesPkg }}.PageData} "请求成功"
// @Failure 400 {object} httpx.Response{} "参数有误"
// @Failure 500 {object} httpx.Response{} "服务器内部错误"
// @Router /v1/{{ kebabCase .QueryStructName }}/search [post]
func (h *handler) handleSearch(gCtx *gin.Context) (interface{}, error) {
	body := &{{ $typesPkg }}.SearchVO{}
	err := gCtx.ShouldBindJSON(body)
	if err != nil {
		return nil, errorx.NewParamsErr(err)
	}
	ctx := gCtx.Request.Context()
	appCtx := h.appCtxBox.GetAppCtx(ctx)
	return h.{{$servicePkg}}.Search(ctx, appCtx, body)
}

// @Summary 创建
// @Description 创建
// @Tags {{.ModelStructName}}
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param body body {{ $beanPkg }}.Save{{.ModelStructName}}PO true "创建参数"
// @Success 200 {object} httpx.Response{Data=common.CreateSuccess} "请求成功"
// @Failure 400 {object} httpx.Response{} "参数有误"
// @Failure 500 {object} httpx.Response{} "服务器内部错误"
// @Router /v1/{{ kebabCase .QueryStructName }} [post]
func (h *handler) handleCreate(gCtx *gin.Context) (interface{}, error) {
	body := &{{ $beanPkg }}.Save{{.ModelStructName}}PO{}
	err := gCtx.ShouldBindJSON(body)
	if err != nil {
		return nil, errorx.NewParamsErr(err)
	}
	ctx := gCtx.Request.Context()
	appCtx := h.appCtxBox.GetAppCtx(ctx)
	// todo
	// adminUserAble, _ := contextx.GetAdminUserAble(gCtx)
	// body.OperatorID = adminUserAble.GetAminID()
	id, err := h.{{$servicePkg}}.Create(ctx, appCtx, body)
	return &common.CreateSuccess{
		ID: id,
	}, err
}

// @Summary 修改
// @Description 修改
// @Tags {{.ModelStructName}}
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param ID path int true "ID"
// @Param body body {{ $beanPkg }}.Save{{.ModelStructName}}PO true "修改参数"
// @Success 200 {object} httpx.Response{} "请求成功"
// @Failure 400 {object} httpx.Response{} "参数有误"
// @Failure 500 {object} httpx.Response{} "服务器内部错误"
// @Router /v1/{{ kebabCase .QueryStructName }}/{ID} [put]
func (h *handler) handleUpdate(gCtx *gin.Context) (interface{}, error) {
	body := &{{ $beanPkg }}.Save{{.ModelStructName}}PO{}
	err := gCtx.ShouldBindJSON(body)
	if err != nil {
		return nil, errorx.NewParamsErr(err)
	}
	IDVO := &common.IDVO{}
	err = gCtx.ShouldBindUri(IDVO)
	if err != nil {
		return nil, errorx.NewParamsErr(err)
	}
	ctx := gCtx.Request.Context()
	appCtx := h.appCtxBox.GetAppCtx(ctx)
	// todo
	// adminUserAble, _ := contextx.GetAdminUserAble(gCtx)
	// body.OperatorID = adminUserAble.GetAminID()
	return nil, h.{{$servicePkg}}.Update(ctx, appCtx, IDVO.ID, body)
}

// @Summary 详情
// @Description 详情
// @Tags {{.ModelStructName}}
// @Accept json
// @Produce json
// @Security ApiKeyAuth
// @Param ID path int true "ID"
// @Success 200 {object} httpx.Response{Data={{ $beanPkg }}.{{ .QueryStructName }}DTO} "请求成功"
// @Failure 400 {object} httpx.Response{} "参数有误"
// @Failure 500 {object} httpx.Response{} "服务器内部错误"
// @Router /v1/{{ kebabCase .QueryStructName }}/{ID} [get]
func (h *handler) handleView(gCtx *gin.Context) (interface{}, error) {
	IDVO := &common.IDVO{}
	err := gCtx.ShouldBindUri(IDVO)
	if err != nil {
		return nil, errorx.NewParamsErr(err)
	}
	ctx := gCtx.Request.Context()
	appCtx := h.appCtxBox.GetAppCtx(ctx)
	return h.{{$servicePkg}}.TaskOrFail(ctx, appCtx, IDVO.ID)
}
{{ end }}