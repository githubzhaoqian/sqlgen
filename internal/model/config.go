package model

// Config model configuration
type Config struct {
	ModelPkg  string
	TableName string
	ModelName string
	//ImportPkgPaths []string
	TemplateDir          string
	FieldWithTags        []string
	ConvTypeMap          map[string]string
	ConvTypePkgMap       map[string]string
	DynamicConstSuffixes []string // dynamic const suffix
	AutoValueFields      []string

	FieldConfig
}

// FieldConfig field configuration
type FieldConfig struct {
	DataTypeMap    map[string]string
	DataTypePkgMap map[string]string

	FieldNullable  bool // generate pointer when field is nullable
	FieldCoverable bool // generate pointer when field has default value
	FieldSignable  bool // detect integer field's unsigned type, adjust generated data type
	//FieldWithIndexTag bool // generate with gorm index tag
	//FieldWithTypeTag  bool // generate with gorm column type tag

	FieldJSONTagNS func(columnName string) string
}
