{{ define "AdminHandlerInterface" }}
package {{.Package}}

import (
	"github.com/gin-gonic/gin"
)

type Handler interface {
	Handle{{.ModelStructName}}API(g *gin.RouterGroup)
}
{{ end }}