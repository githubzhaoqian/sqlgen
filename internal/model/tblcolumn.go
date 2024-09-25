package model

import (
	"reflect"
	"strings"

	"gorm.io/gorm"
)

// Column table column's info
type Column struct {
	gorm.ColumnType
	TableName      string                         `gorm:"column:TABLE_NAME"`
	UseScanType    bool                           `gorm:"-"`
	dataTypeMap    map[string]string              `gorm:"-"`
	dataTypePkgMap map[string]string              `gorm:"-"`
	jsonTagNS      func(columnName string) string `gorm:"-"`
}

// SetDataTypeMap set data type map
func (c *Column) SetDataTypeMap(m map[string]string) {
	c.dataTypeMap = m
}

func (c *Column) AddDataTypeMap(key, value string) {
	c.dataTypeMap[key] = value
}

func (c *Column) AddDataTypePkgMap(key, value string) {
	c.dataTypePkgMap[key] = value
}

// SetDataTypePkgMap set data type pkg map
func (c *Column) SetDataTypePkgMap(m map[string]string) {
	c.dataTypePkgMap = m
}

// GetDataType get data type
func (c *Column) GetDataType() (fieldtype string) {
	if mapping, ok := c.dataTypeMap[c.DatabaseTypeName()]; ok {
		return mapping
	}
	if c.UseScanType && c.ScanType() != nil {
		return c.ScanType().String()
	}
	return dataType.Get(c.DatabaseTypeName(), c.columnType())
}

// WithNS with name strategy
func (c *Column) WithNS(jsonTagNS func(columnName string) string) {
	c.jsonTagNS = jsonTagNS
	if c.jsonTagNS == nil {
		c.jsonTagNS = func(n string) string { return n }
	}
}

// ToField convert to field
func (c *Column) ToField(nullable, coverable, signable bool) (string, *Field) {
	fieldType := c.GetDataType()
	if signable && strings.Contains(c.columnType(), "unsigned") && strings.HasPrefix(fieldType, "int") {
		fieldType = "u" + fieldType
	}
	fieldTypeRaw := fieldType
	switch {
	case c.Name() == "deleted_at" && fieldType == "time.Time":
		fieldType = "gorm.DeletedAt"
	case coverable && c.needDefaultTag(c.defaultTagValue()):
		fieldType = "*" + fieldType
	case nullable && !strings.HasPrefix(fieldType, "*"):
		if n, ok := c.Nullable(); ok && n {
			fieldType = "*" + fieldType
		}
	}

	var comment string
	if commentValue, ok := c.Comment(); ok {
		comment = commentValue
	}
	isPrimaryKey, _ := c.PrimaryKey()
	isAutoIncrement, _ := c.AutoIncrement()
	length, _ := c.Length()
	precision, scale, decimalOK := c.DecimalSize()
	cNullable, _ := c.Nullable()
	unique, _ := c.Unique()
	defaultValue, defaultValueOK := c.DefaultValue()
	pkg := c.dataTypePkgMap[fieldTypeRaw]
	//c.ColumnType.DatabaseTypeName()
	return pkg, &Field{
		Name:                 c.Name(),
		ColumnName:           c.Name(),
		CustomTypeMap:        map[string]string{},
		TypeName:             fieldType,
		OriginalTypeName:     fieldTypeRaw,
		DatabaseTypeName:     c.DatabaseTypeName(),
		ColumnType:           c.columnType(),
		PrimaryKey:           isPrimaryKey,
		AutoIncrement:        isAutoIncrement,
		Length:               length,
		DecimalSizePrecision: precision,
		DecimalSizeScale:     scale,
		DecimalSizeOK:        decimalOK,
		Nullable:             cNullable,
		Unique:               unique,
		ScanType:             c.ScanType(),
		Comment:              comment,
		DefaultValue:         defaultValue,
		DefaultValueOK:       defaultValueOK,
	}
}

func (c *Column) multilineComment() bool {
	cm, ok := c.Comment()
	return ok && strings.Contains(cm, "\n")
}

// needDefaultTag check if default tag needed
func (c *Column) needDefaultTag(defaultTagValue string) bool {
	if defaultTagValue == "" {
		return false
	}
	switch c.ScanType().Kind() {
	case reflect.Bool:
		return defaultTagValue != "false"
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64, reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64, reflect.Float32, reflect.Float64:
		return defaultTagValue != "0"
	case reflect.String:
		return defaultTagValue != ""
	case reflect.Struct:
		return strings.Trim(defaultTagValue, "'0:- ") != ""
	}
	return c.Name() != "created_at" && c.Name() != "updated_at"
}

// defaultTagValue return gorm default tag's value
func (c *Column) defaultTagValue() string {
	value, ok := c.DefaultValue()
	if !ok {
		return ""
	}
	if value != "" && strings.TrimSpace(value) == "" {
		return "'" + value + "'"
	}
	return value
}

func (c *Column) columnType() (v string) {
	if cl, ok := c.ColumnType.ColumnType(); ok {
		return cl
	}
	return c.DatabaseTypeName()
}
