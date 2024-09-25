package generate

import (
	"fmt"
	"regexp"

	"github.com/samber/lo"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"

	"github.com/githubzhaoqian/sqlgen/internal/model"
)

/*
** The feature of mapping table from database server to Golang struct
** Provided by @qqxhb
 */

func getFields(db *gorm.DB, conf *model.Config, columns []*model.Column) ([]string, []*model.Field) {
	var pgkList []string
	var fields []*model.Field
	for _, col := range columns {
		col.SetDataTypeMap(conf.ConvTypeMap)
		col.SetDataTypePkgMap(conf.ConvTypePkgMap)
		col.WithNS(conf.FieldJSONTagNS)

		pkg, m := col.ToField(conf.FieldNullable, conf.FieldCoverable, conf.FieldSignable)
		if pkg != "" {
			pgkList = append(pgkList, pkg)
		}

		if ns, ok := db.NamingStrategy.(schema.NamingStrategy); ok {
			ns.SingularTable = true
			m.Name = ns.SchemaName(ns.TablePrefix + m.Name)
		} else if db.NamingStrategy != nil {
			m.Name = db.NamingStrategy.SchemaName(m.Name)
		}

		fields = append(fields, m)
	}

	return lo.Uniq(pgkList), fields
}

// get mysql db' name
var modelNameReg = regexp.MustCompile(`^\w+$`)

func checkStructName(name string) error {
	if name == "" {
		return nil
	}
	if !modelNameReg.MatchString(name) {
		return fmt.Errorf("model name cannot contains invalid character")
	}
	if name[0] < 'A' || name[0] > 'Z' {
		return fmt.Errorf("model name must be initial capital")
	}
	return nil
}
