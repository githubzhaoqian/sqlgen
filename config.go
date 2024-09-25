package sqlgen

import (
	"gorm.io/gorm"
	"gorm.io/gorm/utils/tests"
)

// GenerateMode generate mode
type GenerateMode uint

const (
	// WithDefaultQuery create default query in generated code
	WithDefaultQuery GenerateMode = 1 << iota

	// WithoutContext generate code without context constrain
	WithoutContext

	// WithQueryInterface generate code with exported interface object
	WithQueryInterface
)

// Config generator's basic configuration
type Config struct {
	db *gorm.DB // db connection

	// generate model global configuration
	FieldNullable  bool // generate pointer when field is nullable
	FieldCoverable bool // generate pointer when field has default value, to fix problem zero value cannot be assign: https://gorm.io/docs/create.html#Default-Values
	FieldSignable  bool // detect integer field's unsigned type, adjust generated data type

	Mode GenerateMode // generate mode

	QueryPkgName string // generated query code's package name

	fieldJSONTagNS func(columnName string) (tagContent string)

	TemplateDir      string   // generated with template directory
	FieldWithTags    []string // generate field with custom tag
	Overwrite        bool     // overwrite existing file
	DefaultAllTable  bool     // 默认全部表
	TableRegexp      string   // table regexp
	TableRegexpStyle string   // table regexp style
	ModelName        string   // model 名称

	Templates            []Template // dynamic const suffix
	DynamicConstSuffixes []string   // dynamic const suffix
	DynamicConstOutPath  string     // dynamic const out path
	DynamicConstTemplate string     // 动态常量模板
	DynamicAliasSuffix   string     // 动态常量包别名后缀
	DynamicConstImport   bool       // 动态常量自动导入
	AutoValueFields      []string   // dynamic const suffix

	ConvTypeMap    map[string]string `yaml:"convType"`    // conv type
	ConvTypePkgMap map[string]string `yaml:"convTypePkg"` // conv type pkg
}

// WithJSONTagNameStrategy specify json tag naming strategy
func (cfg *Config) WithJSONTagNameStrategy(ns func(columnName string) (tagContent string)) {
	cfg.fieldJSONTagNS = ns
}

// Revise format path and db
func (cfg *Config) Revise() (err error) {
	if cfg.db == nil {
		cfg.db, _ = gorm.Open(tests.DummyDialector{})
	}

	return nil
}

func (cfg *Config) judgeMode(mode GenerateMode) bool { return cfg.Mode&mode != 0 }
