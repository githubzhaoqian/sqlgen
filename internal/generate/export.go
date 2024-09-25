package generate

import (
	"fmt"
	"reflect"
	"strings"

	"gorm.io/gorm"
	"gorm.io/gorm/utils/tests"

	"github.com/githubzhaoqian/sqlgen/internal/model"
)

// GetStructMeta generate db model by table name
func GetStructMeta(db *gorm.DB, conf *model.Config) (*StructMeta, error) {
	if _, ok := db.Config.Dialector.(tests.DummyDialector); ok {
		return nil, fmt.Errorf("UseDB() is necessary to generate model struct [%s] from database table [%s]", conf.ModelName, conf.TableName)
	}

	tableName, structName, fileName := conf.TableName, conf.ModelName, strings.ToLower(conf.TableName)
	if tableName == "" {
		return nil, nil
	}
	if err := checkStructName(structName); err != nil {
		return nil, fmt.Errorf("model name %q is invalid: %w", structName, err)
	}

	columns, err := getTableColumns(db, "", tableName)
	if err != nil {
		return nil, err
	}

	pkgLit, fields := getFields(db, conf, columns)
	autoValueFields := make(map[string]struct{}, len(conf.AutoValueFields))
	for _, field := range conf.AutoValueFields {
		autoValueFields[field] = struct{}{}
	}
	return &StructMeta{
		db:                   db,
		Generated:            true,
		FileName:             fileName,
		TableName:            tableName,
		TableComment:         getTableComment(db, tableName),
		ModelStructName:      structName,
		QueryStructName:      uncaptialize(structName),
		S:                    strings.ToLower(structName[0:1]),
		ImportPkgPaths:       pkgLit,
		TemplatePkgPath:      map[string]string{},
		Fields:               fields,
		ConvTypeMap:          conf.ConvTypeMap,
		ConvTypePkgMap:       conf.ConvTypePkgMap,
		DynamicConstSuffixes: conf.DynamicConstSuffixes,
		FieldWithTags:        conf.FieldWithTags,
		AutoValueFields:      autoValueFields,
	}, nil
}

// ConvertStructs convert to base structures
func ConvertStructs(db *gorm.DB, structs ...interface{}) (metas []*StructMeta, err error) {
	for _, st := range structs {
		if isNil(st) {
			continue
		}
		if base, ok := st.(*StructMeta); ok {
			metas = append(metas, base)
			continue
		}
		//if !isStructType(reflect.ValueOf(st)) {
		//	return nil, fmt.Errorf("%s is not a struct", reflect.TypeOf(st).String())
		//}

		structType := reflect.TypeOf(st)
		name := getStructName(structType.String())
		newStructName := name
		if st, ok := st.(interface{ GenInternalDoName() string }); ok {
			newStructName = st.GenInternalDoName()
		}

		meta := &StructMeta{
			Generated:       true,
			S:               getPureName(name),
			ModelStructName: name,
			QueryStructName: uncaptialize(newStructName),
			db:              db,
		}

		metas = append(metas, meta)
	}
	return
}

func isNil(i interface{}) bool {
	if i == nil {
		return true
	}

	// if v is not ptr, return false(i is not nil)
	// if v is ptr, return v.IsNil()
	v := reflect.ValueOf(i)
	return v.Kind() == reflect.Ptr && v.IsNil()
}

// GetStructNames get struct names from base structs
func GetStructNames(bases []*StructMeta) (names []string) {
	for _, base := range bases {
		names = append(names, base.ModelStructName)
	}
	return names
}
