package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/githubzhaoqian/sqlgen"
	"gopkg.in/yaml.v3"
	"gorm.io/driver/clickhouse"
	"gorm.io/driver/mysql"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/driver/sqlserver"
	"gorm.io/gorm"
)

// DBType database type
type DBType string

const (
	// dbMySQL Gorm Drivers mysql || postgres || sqlite || sqlserver
	dbMySQL      DBType = "mysql"
	dbPostgres   DBType = "postgres"
	dbSQLite     DBType = "sqlite"
	dbSQLServer  DBType = "sqlserver"
	dbClickHouse DBType = "clickhouse"

	siteUrl = "github.com/githubzhaoqian/sqlgen"
	version = "v1.1.5"
)

// CmdParams is command line parameters
type CmdParams struct {
	DSN              string   `yaml:"dsn"`              // consult[https://gorm.io/docs/connecting_to_the_database.html]"
	DB               string   `yaml:"db"`               // input mysql or postgres or sqlite or sqlserver. consult[https://gorm.io/docs/connecting_to_the_database.html]
	outputTemplate   string   `yaml:"-"`                // output template
	Tables           []string `yaml:"tables"`           // enter the required data table or leave it blank
	DefaultAllTable  bool     `yaml:"defaultAllTable"`  // 默认全部表
	FieldNullable    bool     `yaml:"fieldNullable"`    // generate with pointer when field is nullable
	FieldCoverable   bool     `yaml:"fieldCoverable"`   // generate with pointer when field has default value
	FieldSignable    bool     `yaml:"fieldSignable"`    // detect integer field's unsigned type, adjust generated data type
	TemplateDir      string   `yaml:"templateDir"`      // generated with template directory
	FieldWithTags    []string `yaml:"fieldWithTags"`    // generate field with custom tag
	Overwrite        bool     `yaml:"overwrite"`        // overwrite existing file
	TableRegexp      string   `yaml:"tableRegexp"`      // table regexp
	TableRegexpStyle string   `yaml:"tableRegexpStyle"` // table regexp style
	ModelName        string   `yaml:"modelName"`        // 模型名称
	// 附加模板
	Templates []Template `yaml:"templates"` // append templates
	// 动态常量
	DynamicConstSuffixes []string `yaml:"dynamicConstSuffixes"` // dynamic const suffix
	DynamicConstOutPath  string   `yaml:"dynamicConstOutPath"`  // dynamic const out path
	DynamicConstTemplate string   `yaml:"dynamicConstTemplate"` // 动态常量模板
	DynamicAliasSuffix   string   `yaml:"dynamicAliasSuffix"`   // 动态常量包别名后缀 userConst
	DynamicConstImport   bool     `yaml:"dynamicConstImport"`   // 动态常量自动导入
	AutoValueFields      []string `yaml:"autoValueFields"`      // 自动默认值的字段
	// 自定义类型
	ConvTypeMap    map[string]string `yaml:"convTypeMap"`    // conv type
	ConvTypePkgMap map[string]string `yaml:"convTypePkgMap"` // conv type pkg
}

type Template struct {
	OutPath     string `yaml:"outPath"`     // specify a directory for output
	Name        string `yaml:"name"`        // template name
	DynamicType bool   `yaml:"dynamicType"` // template name
}

func (c *CmdParams) revise() *CmdParams {
	if c == nil {
		return c
	}
	if c.DB == "" {
		c.DB = string(dbMySQL)
	}
	if len(c.Tables) == 0 {
		return c
	}

	tableList := make([]string, 0, len(c.Tables))
	for _, tableName := range c.Tables {
		_tableName := strings.TrimSpace(tableName) // trim leading and trailing space in tableName
		if _tableName == "" {                      // skip empty tableName
			continue
		}
		tableList = append(tableList, _tableName)
	}
	c.Tables = tableList
	return c
}

// YamlConfig is yaml config struct
type YamlConfig struct {
	Version  string     `yaml:"version"`  //
	Database *CmdParams `yaml:"database"` //
}

// connectDB choose db type for connection to database
func connectDB(t DBType, dsn string) (*gorm.DB, error) {
	if dsn == "" {
		return nil, fmt.Errorf("dsn cannot be empty")
	}

	switch t {
	case dbMySQL:
		return gorm.Open(mysql.Open(dsn))
	case dbPostgres:
		return gorm.Open(postgres.Open(dsn))
	case dbSQLite:
		return gorm.Open(sqlite.Open(dsn))
	case dbSQLServer:
		return gorm.Open(sqlserver.Open(dsn))
	case dbClickHouse:
		return gorm.Open(clickhouse.Open(dsn))
	default:
		return nil, fmt.Errorf("unknow db %q (support mysql || postgres || sqlite || sqlserver for now)", t)
	}
}

// genModels is gorm/gen generated models
func genModels(g *sqlgen.Generator, db *gorm.DB, tables []string) (models []interface{}, err error) {
	if len(tables) == 0 {
		if !g.DefaultAllTable {
			return nil, fmt.Errorf("GORM migrator get all tables disabled")
		}
		// Execute tasks for all tables in the database
		tables, err = db.Migrator().GetTables()
		if err != nil {
			return nil, fmt.Errorf("GORM migrator get all tables fail: %w", err)
		}
	}

	// Execute some data table tasks
	models = make([]interface{}, len(tables))
	for i, tableName := range tables {
		models[i] = g.GenerateModel(tableName)
	}
	return models, nil
}

// parseCmdFromYaml parse cmd param from yaml
func parseCmdFromYaml(path string) *CmdParams {
	file, err := os.Open(path)
	if err != nil {
		log.Fatalf("parseCmdFromYaml fail %s", err.Error())
		return nil
	}
	defer file.Close() // nolint
	var yamlConfig YamlConfig
	if err = yaml.NewDecoder(file).Decode(&yamlConfig); err != nil {
		log.Fatalf("parseCmdFromYaml fail %s", err.Error())
		return nil
	}
	return yamlConfig.Database
}

// argParse is parser for cmd
func argParse() *CmdParams {
	// choose is file or flag
	genPath := flag.String("c", ".sqlgen.yaml", "is path for .sqlgen.yml")
	dsn := flag.String("dsn", "", "consult[https://gorm.io/docs/connecting_to_the_database.html]")
	db := flag.String("db", "", "input mysql|postgres|sqlite|sqlserver|clickhouse. consult[https://gorm.io/docs/connecting_to_the_database.html]")
	tableList := flag.String("tables", "", "enter the required data table or leave it blank")
	fieldNullable := flag.Bool("fieldNullable", false, "generate with pointer when field is nullable")
	fieldCoverable := flag.Bool("fieldCoverable", false, "generate with pointer when field has default value")
	fieldSignable := flag.Bool("fieldSignable", false, "detect integer field's unsigned type, adjust generated data type")
	templateDir := flag.String("templateDir", "", "generated with template directory")
	outputTemplate := flag.String("ot", "", "output template")
	fieldWithTags := flag.String("fieldWithTags", "", "generate field with custom tag")
	overwrite := flag.Bool("overwrite", false, "overwrite existing file")
	tableRegexp := flag.String("tableRegexp", "", "table regexp")
	tableRegexpStyle := flag.String("tableRegexpStyle", "", "table regexp style: lower/camel/snake")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "sqlgen\n version: %s:\n siteUrl: [%s]:\n\n", version, siteUrl)
		flag.PrintDefaults()
	}
	flag.Parse()

	cmdParse := &CmdParams{}
	if *genPath != "" { //use yml config
		yamlFile, err := filepath.Abs(*genPath)
		if err != nil {
			panic(err)
		}
		cmdParse = parseCmdFromYaml(yamlFile)
	}
	// cmd first
	if *dsn != "" {
		cmdParse.DSN = *dsn
	}
	if *db != "" {
		cmdParse.DB = *db
	}
	if *tableList != "" {
		cmdParse.Tables = strings.Split(*tableList, ",")
	}
	//if *modelPkgName != "" {
	//	cmdParse.ModelPkgName = *modelPkgName
	//}
	if *fieldNullable {
		cmdParse.FieldNullable = *fieldNullable
	}
	if *fieldCoverable {
		cmdParse.FieldCoverable = *fieldCoverable
	}
	if *fieldSignable {
		cmdParse.FieldSignable = *fieldSignable
	}
	if *templateDir != "" {
		cmdParse.TemplateDir = *templateDir
	}
	if *fieldWithTags != "" {
		cmdParse.FieldWithTags = strings.Split(*fieldWithTags, ",")
	}
	if *overwrite {
		cmdParse.Overwrite = *overwrite
	}
	if *outputTemplate != "" {
		cmdParse.outputTemplate = *outputTemplate
	}
	if *tableRegexp != "" {
		cmdParse.TableRegexp = *tableRegexp
	}
	if *tableRegexpStyle != "" {
		cmdParse.TableRegexpStyle = *tableRegexpStyle
	}
	return cmdParse
}

func main() {
	// cmdParse
	config := argParse().revise()
	if config == nil {
		log.Fatalln("parse config fail")
	}

	if config.outputTemplate != "" {
		err := sqlgen.OutputTemplate(config.outputTemplate)
		if err != nil {
			log.Fatalf("OutputTemplate fail:%v", err)
		}
		log.Println("OutputTemplate end")
		return
	}
	db, err := connectDB(DBType(config.DB), config.DSN)
	if err != nil {
		log.Fatalln("connect db server fail:", err)
	}
	var templates []sqlgen.Template
	for _, tpl := range config.Templates {
		templates = append(templates, sqlgen.Template{
			OutPath:     tpl.OutPath,
			Name:        tpl.Name,
			DynamicType: tpl.DynamicType,
		})
	}
	g := sqlgen.NewGenerator(sqlgen.Config{
		FieldNullable:    config.FieldNullable,
		FieldCoverable:   config.FieldCoverable,
		FieldSignable:    config.FieldSignable,
		TemplateDir:      config.TemplateDir,
		FieldWithTags:    config.FieldWithTags,
		Overwrite:        config.Overwrite,
		TableRegexp:      config.TableRegexp,
		DefaultAllTable:  config.DefaultAllTable,
		TableRegexpStyle: config.TableRegexpStyle,
		ModelName:        config.ModelName,
		Templates:        templates,

		DynamicConstSuffixes: config.DynamicConstSuffixes,
		DynamicConstOutPath:  config.DynamicConstOutPath,
		DynamicConstTemplate: config.DynamicConstTemplate,
		DynamicAliasSuffix:   config.DynamicAliasSuffix,
		DynamicConstImport:   config.DynamicConstImport,

		ConvTypeMap:     config.ConvTypeMap,
		ConvTypePkgMap:  config.ConvTypePkgMap,
		AutoValueFields: config.AutoValueFields,
	})

	g.UseDB(db)

	models, err := genModels(g, db, config.Tables)
	if err != nil {
		log.Fatalln("get tables info fail:", err)
	}

	g.ApplyBasic(models...)

	g.Execute()
}
