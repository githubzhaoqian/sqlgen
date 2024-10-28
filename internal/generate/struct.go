package generate

import (
	"gorm.io/gorm"

	"github.com/githubzhaoqian/sqlgen/internal/model"
)

type StructMeta struct {
	db *gorm.DB

	Generated            bool   // whether to generate db model
	FileName             string // generated file name
	S                    string // the first letter(lower case)of simple Name (receiver)
	QueryStructName      string // internal query struct name
	ModelStructName      string // origin/model struct name
	TableName            string // table name in db server
	TableComment         string // table comment in db server
	Fields               []*model.Field
	ImportPkgPaths       []string
	TemplatePkgPath      map[string]string // 模板的包路径
	PkgPath              string            // package's path: internal/model
	Package              string            // package's name: model
	Type                 string            // param's type: User
	ConvTypeMap          map[string]string
	ConvTypePkgMap       map[string]string
	DynamicConstSuffixes []string            // dynamic const suffix
	AutoValueFields      map[string]struct{} // dynamic const suffix
	FieldWithTags        []string
	SubMatch             []string
}
