package model

import (
	"reflect"
	"strings"

	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

var (
	defaultDataType             = "string"
	dataType        dataTypeMap = map[string]dataTypeMapping{
		"numeric":    func(string) string { return "int32" },
		"integer":    func(string) string { return "int32" },
		"int":        func(string) string { return "int32" },
		"smallint":   func(string) string { return "int32" },
		"mediumint":  func(string) string { return "int32" },
		"bigint":     func(string) string { return "int64" },
		"float":      func(string) string { return "float32" },
		"real":       func(string) string { return "float64" },
		"double":     func(string) string { return "float64" },
		"decimal":    func(string) string { return "float64" },
		"char":       func(string) string { return "string" },
		"varchar":    func(string) string { return "string" },
		"tinytext":   func(string) string { return "string" },
		"mediumtext": func(string) string { return "string" },
		"longtext":   func(string) string { return "string" },
		"binary":     func(string) string { return "[]byte" },
		"varbinary":  func(string) string { return "[]byte" },
		"tinyblob":   func(string) string { return "[]byte" },
		"blob":       func(string) string { return "[]byte" },
		"mediumblob": func(string) string { return "[]byte" },
		"longblob":   func(string) string { return "[]byte" },
		"text":       func(string) string { return "string" },
		"json":       func(string) string { return "string" },
		"enum":       func(string) string { return "string" },
		"time":       func(string) string { return "time.Time" },
		"date":       func(string) string { return "time.Time" },
		"datetime":   func(string) string { return "time.Time" },
		"timestamp":  func(string) string { return "time.Time" },
		"year":       func(string) string { return "int32" },
		"bit":        func(string) string { return "[]uint8" },
		"boolean":    func(string) string { return "bool" },
		"tinyint": func(detailType string) string {
			if strings.HasPrefix(strings.TrimSpace(detailType), "tinyint(1)") {
				return "bool"
			}
			return "int32"
		},
	}
)

type dataTypeMapping func(detailType string) (finalType string)

type dataTypeMap map[string]dataTypeMapping

func (m dataTypeMap) Get(dataType, detailType string) string {
	if convert, ok := m[strings.ToLower(dataType)]; ok {
		return convert(detailType)
	}
	return defaultDataType
}

type Field struct {
	Name                 string
	ColumnName           string
	TypeName             string
	OriginalTypeName     string // 原始类型
	DatabaseTypeName     string // varchar
	ColumnType           string // varchar(64)
	PrimaryKey           bool
	AutoIncrement        bool
	Length               int64
	DecimalSizeOK        bool
	DecimalSizeScale     int64
	DecimalSizePrecision int64
	Nullable             bool
	Unique               bool
	ScanType             reflect.Type
	Comment              string
	DefaultValueOK       bool
	DefaultValue         string
	CustomTypeMap        map[string]string // 自定义类型映射
}

// GenType ...
func (m *Field) GenType() string {
	typ := strings.TrimLeft(m.DatabaseTypeName, "*")
	if customType, ok := m.CustomTypeMap[typ]; ok {
		return customType
	}
	cTitle := cases.Title(language.English)
	switch typ {
	case "string", "bytes":
		return cTitle.String(typ)
	case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64":
		return cTitle.String(typ)
	case "float64", "float32":
		return cTitle.String(typ)
	case "bool":
		return cTitle.String(typ)
	case "time.Time":
		return "Time"
	case "json.RawMessage", "[]byte":
		return "Bytes"
	case "serializer":
		return "Serializer"
	default:
		return "Field"
	}
}
