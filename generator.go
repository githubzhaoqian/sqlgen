package sqlgen

import (
	"bytes"
	"context"
	"database/sql"
	"embed"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"text/template"

	"github.com/gobeam/stringy"
	"golang.org/x/tools/go/packages"
	"golang.org/x/tools/imports"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"

	"github.com/githubzhaoqian/sqlgen/internal/consts"
	"github.com/githubzhaoqian/sqlgen/internal/generate"
	"github.com/githubzhaoqian/sqlgen/internal/model"
	"github.com/githubzhaoqian/sqlgen/internal/utils/funcs"
)

var (
	ErrFileExist = errors.New("file exist skip overwrite")
)

const TemplateName = "template"
const TemplatePrefix = "*tpl"

//go:embed template
var TemplateFs embed.FS

// T generic type
type T interface{}

// M map[string]interface{}
type M map[string]interface{}

// SQLResult sql.result
type SQLResult sql.Result

// SQLRow sql.Row
type SQLRow sql.Row

// SQLRows sql.Rows
type SQLRows sql.Rows

// RowsAffected execute affected raws
type RowsAffected int64

var concurrent = runtime.NumCPU()

// NewGenerator create a new generator
func NewGenerator(cfg Config) *Generator {
	if err := cfg.Revise(); err != nil {
		panic(fmt.Errorf("create generator fail: %w", err))
	}
	tpl := template.New("_")
	tpl.Funcs(funcs.FuncMap)
	if cfg.TemplateDir != "" {
		templateDir, err := filepath.Abs(cfg.TemplateDir)
		if err != nil {
			panic(fmt.Errorf("filepath.Abs(cfg.TemplateDir) fail: %w", err))
		}
		templateFs := os.DirFS(templateDir)
		tpl, err = tpl.ParseFS(templateFs, TemplatePrefix)
		if err != nil {
			panic(fmt.Errorf("create generator template.ParseFS fail: %w", err))
		}
	} else {
		templateFs := TemplateFs
		entryList, err := templateFs.ReadDir(TemplateName)
		if err != nil {
			panic(fmt.Errorf("templateFs.ReadDir fail: %w", err))
		}
		for _, entry := range entryList {
			if entry.IsDir() {
				continue
			}
			name := entry.Name()
			fileName := filepath.Join(TemplateName, name)
			contentBytes, err := templateFs.ReadFile(fileName)
			if err != nil {
				panic(fmt.Errorf("create generator tpl readFile %s fail: %w", fileName, err))
			}
			tpl, err = tpl.Parse(string(contentBytes))
			if err != nil {
				panic(fmt.Errorf("create generator tpl parse %s fail: %w", fileName, err))
			}
		}
	}
	g := &Generator{
		Config:               cfg,
		Data:                 make(map[string]*genInfo),
		models:               make(map[string]*generate.StructMeta),
		template:             tpl,
		templateList:         cfg.Templates,
		dynamicConstSuffixes: cfg.DynamicConstSuffixes,
		dynamicConstOutPath:  cfg.DynamicConstOutPath,
		dynamicConstTemplate: cfg.DynamicConstTemplate,
	}
	if cfg.TableRegexp != "" {
		g.tableRegexp = regexp.MustCompile(cfg.TableRegexp)
	}
	return g
}

func OutputTemplate(dir string) error {
	entryList, err := TemplateFs.ReadDir(TemplateName)
	if err != nil {
		return fmt.Errorf("TemplateFs.ReadDir %v", err)
	}
	dirPath := filepath.Join(dir, TemplateName)
	err = os.MkdirAll(dirPath, os.ModePerm)
	if err != nil {
		return fmt.Errorf("os.MkdirAll %s err:%v", dirPath, err)
	}
	for _, entry := range entryList {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		contentBytes, err := TemplateFs.ReadFile(filepath.Join(TemplateName, name))
		if err != nil {
			return fmt.Errorf("TemplateFs.ReadFile err:%v", err)
		}
		fileName := filepath.Join(dir, TemplateName, name)
		err = os.WriteFile(fileName, contentBytes, os.ModePerm)
		if err != nil {
			return fmt.Errorf("os.WriteFile %s err:%v", fileName, err)
		}
	}
	return nil
}

// genInfo info about generated code
type genInfo struct {
	*generate.StructMeta
}

// Generator code generator
type Generator struct {
	Config

	Data         map[string]*genInfo             //gen query data
	models       map[string]*generate.StructMeta //gen model data
	template     *template.Template
	templateList []Template
	tableRegexp  *regexp.Regexp

	// 动态常量
	dynamicConstSuffixes []string // dynamic const suffix
	dynamicConstOutPath  string   // dynamic const out path
	dynamicConstTemplate string   // 动态常来那个模板
}

type Template struct {
	OutPath string // specify a directory for output
	Name    string // template name
	IsGo    bool
}

// UseDB set db connection
func (g *Generator) UseDB(db *gorm.DB) {
	if db != nil {
		g.db = db
	}
}

/*
** The feature of mapping table from database server to Golang struct
** Provided by @qqxhb
 */

// GenerateModel catch table info from db, return a BaseStruct
func (g *Generator) GenerateModel(tableName string) *generate.StructMeta {
	modelName := g.ModelName
	strList := g.tableRegexp.FindAllStringSubmatch(tableName, -1)
	if len(strList) > 0 {
		for i, str := range strList[0] {
			newStr := funcs.Camel(str)
			modelName = strings.ReplaceAll(modelName, fmt.Sprintf("{%d}", i), newStr)
		}
	}

	modelName = g.db.Config.NamingStrategy.SchemaName(modelName)
	return g.GenerateModelAs(tableName, modelName)
}

// GenerateModelAs catch table info from db, return a BaseStruct
func (g *Generator) GenerateModelAs(tableName string, modelName string) *generate.StructMeta {
	meta, err := generate.GetStructMeta(g.db, g.genModelConfig(tableName, modelName))
	if err != nil {
		g.db.Logger.Error(context.Background(), "generate struct from table fail: %s", err)
		panic("generate struct fail")
	}
	if meta == nil {
		g.info(fmt.Sprintf("ignore table <%s>", tableName))
		return nil
	}
	g.models[meta.ModelStructName] = meta

	g.info(fmt.Sprintf("got %d columns from table <%s>", len(meta.Fields), meta.TableName))
	return meta
}

// GenerateAllTable generate all tables in db
func (g *Generator) GenerateAllTable() (tableModels []interface{}) {
	tableList, err := g.db.Migrator().GetTables()
	if err != nil {
		panic(fmt.Errorf("get all tables fail: %w", err))
	}

	g.info(fmt.Sprintf("find %d table from db: %s", len(tableList), tableList))

	tableModels = make([]interface{}, len(tableList))
	for i, tableName := range tableList {
		tableModels[i] = g.GenerateModel(tableName)
	}
	return tableModels
}

func (g *Generator) genModelConfig(tableName string, modelName string) *model.Config {
	return &model.Config{
		TableName: tableName,
		ModelName: modelName,
		FieldConfig: model.FieldConfig{
			DataTypeMap:    g.ConvTypeMap,
			DataTypePkgMap: g.ConvTypePkgMap,

			FieldSignable:  g.FieldSignable,
			FieldNullable:  g.FieldNullable,
			FieldCoverable: g.FieldCoverable,

			FieldJSONTagNS: g.fieldJSONTagNS,
		},
		TemplateDir:          g.TemplateDir,
		FieldWithTags:        g.FieldWithTags,
		ConvTypeMap:          g.Config.ConvTypeMap,
		ConvTypePkgMap:       g.Config.ConvTypePkgMap,
		DynamicConstSuffixes: g.Config.DynamicConstSuffixes,
		AutoValueFields:      g.Config.AutoValueFields,
	}
}

func (g *Generator) getTablePrefix() string {
	if ns, ok := g.db.NamingStrategy.(schema.NamingStrategy); ok {
		return ns.TablePrefix
	}
	return ""
}

// ApplyBasic specify models which will implement basic .diy_method
func (g *Generator) ApplyBasic(models ...interface{}) {
	g.ApplyInterface(func() {}, models...)
}

// ApplyInterface specifies .diy_method interfaces on structures, implment codes will be generated after calling g.Execute()
// eg: g.ApplyInterface(func(model.Method){}, model.User{}, model.Company{})
func (g *Generator) ApplyInterface(fc interface{}, models ...interface{}) {
	structs, err := generate.ConvertStructs(g.db, models...)
	if err != nil {
		g.db.Logger.Error(context.Background(), "check struct fail: %v", err)
		panic("check struct fail")
	}
	g.apply(fc, structs)
}

func (g *Generator) apply(fc interface{}, structs []*generate.StructMeta) {
	for _, interfaceStructMeta := range structs {
		_, err := g.pushQueryStructMeta(interfaceStructMeta)
		if err != nil {
			g.db.Logger.Error(context.Background(), "gen struct fail: %v", err)
			panic("gen struct fail")
		}
	}
}

// Execute generate code to output path
func (g *Generator) Execute() {
	g.info("Start generating code.")

	if err := g.generateModelFile(); err != nil {
		g.db.Logger.Error(context.Background(), "generate model struct fail: %s", err)
		panic("generate model struct fail")
	}

	g.info("Generate code done.")
}

// info logger
func (g *Generator) info(logInfos ...string) {
	for _, l := range logInfos {
		g.db.Logger.Info(context.Background(), l)
		log.Println(l)
	}
}

func (g *Generator) error(logInfos ...string) {
	for _, l := range logInfos {
		g.db.Logger.Error(context.Background(), l)
		log.Println(l)
	}
}

func (g *Generator) warn(logInfos ...string) {
	for _, l := range logInfos {
		g.db.Logger.Warn(context.Background(), l)
		log.Println(l)
	}
}

// generateModelFile generate model structures and save to file
func (g *Generator) generateModelFile() error {
	if len(g.models) == 0 {
		return nil
	}

	for _, data := range g.models {
		if data == nil || !data.Generated {
			continue
		}

		// 自定义常常量
		if g.DynamicConstTemplate != "" {
			err := g.templateOutput(&Template{
				OutPath: g.DynamicConstOutPath,
				Name:    g.DynamicConstTemplate,
			}, data)
			if err != nil {
				return err
			}
			var hasDynamicConst bool
			constPkg := data.TemplatePkgPath[g.DynamicConstTemplate]
			constPkgName := filepath.Base(constPkg)
			if g.DynamicAliasSuffix != "" {
				constPkgName = data.QueryStructName + g.DynamicAliasSuffix
			}
			for _, field := range data.Fields {
				if funcs.Suffixes(field.Name, g.dynamicConstSuffixes) {
					hasDynamicConst = true
					field.TypeName = constPkgName + "." + field.Name
				}
			}
			if hasDynamicConst && g.DynamicConstImport {
				data.ImportPkgPaths = append(data.ImportPkgPaths, constPkg)
			}
		}

		for _, tpl := range g.templateList {
			err := g.templateOutput(&tpl, data)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

func (g *Generator) templateOutput(tpl *Template, data *generate.StructMeta) error {
	outFile, err := g.getOutFile(tpl.OutPath, data.TableName)
	if err != nil {
		return err
	}

	modelDir := filepath.Dir(outFile)
	if err = os.MkdirAll(modelDir, os.ModePerm); err != nil {
		return fmt.Errorf("create model pkg path(%s) fail: %s", modelDir, err)
	}

	var buf bytes.Buffer
	if tpl.IsGo {
		data.Package = g.getPkgPath(modelDir)
	}
	err = g.render(tpl.Name, &buf, data)
	if err != nil {
		return err
	}
	err = g.output(outFile, buf.Bytes())
	if err != nil {
		if errors.Is(err, ErrFileExist) {
			g.warn(fmt.Sprintf("%s is exist skip overwrite", outFile))
		} else {
			return err
		}
	}
	g.info(fmt.Sprintf("generate file(table <%s> -> %s", data.TableName, outFile))
	if tpl.IsGo {
		g.fillModelPkgPath(tpl.Name, data.TableName, modelDir, data)
	}
	return nil
}

func (g *Generator) tableStyle(src string) string {
	str := stringy.New(src)
	switch g.TableRegexpStyle {
	case consts.Lower:
		return str.CamelCase().ToLower()
	case consts.Camel:
		return str.CamelCase().Get()
	case consts.Snake:
		return str.SnakeCase().ToLower()
	}
	return str.CamelCase().ToLower()
}

func (g *Generator) getOutFile(path, table string) (outPath string, err error) {
	strList := g.tableRegexp.FindAllStringSubmatch(table, -1)
	if len(strList) == 0 {
		return "", fmt.Errorf("table name(%s) not match regexp(%s)", table, g.tableRegexp.String())
	}
	for i, str := range strList[0] {
		newStr := g.tableStyle(str)
		path = strings.ReplaceAll(path, fmt.Sprintf("{%d}", i), newStr)
	}
	outPath, err = filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("cannot parse outPath: %w", err)
	}
	return outPath, nil
}

func (g *Generator) getPkgPath(dir string) string {
	return filepath.Base(dir)
}

func (g *Generator) fillModelPkgPath(tplName, table, filePath string, data *generate.StructMeta) {
	pkgs, err := packages.Load(&packages.Config{
		Mode: packages.NeedName,
		Dir:  filePath,
	})
	if err != nil {
		g.db.Logger.Warn(context.Background(), "parse model pkg path fail: %s", err)
		return
	}
	if len(pkgs) == 0 {
		g.db.Logger.Warn(context.Background(), "parse model pkg path fail: got 0 packages")
		return
	}
	data.TemplatePkgPath[tplName] = pkgs[0].PkgPath
}

// output format and output
func (g *Generator) output(fileName string, content []byte) error {
	result, err := imports.Process(fileName, content, nil)
	if err != nil {
		lines := strings.Split(string(content), "\n")
		errLine, _ := strconv.Atoi(strings.Split(err.Error(), ":")[1])
		startLine, endLine := errLine-5, errLine+5
		//fmt.Println("Format fail:", errLine, err)
		if startLine < 0 {
			startLine = 0
		}
		if endLine > len(lines)-1 {
			endLine = len(lines) - 1
		}
		for i := startLine; i <= endLine; i++ {
			fmt.Println(i, lines[i])
		}
		return fmt.Errorf("cannot format file: %w", err)
	}
	_, statErr := os.Stat(fileName)
	if !g.Overwrite && (statErr == nil || os.IsExist(statErr)) {
		return ErrFileExist
	}
	//fmt.Println(fileInfo)
	return os.WriteFile(fileName, result, 0640)
}

func (g *Generator) pushQueryStructMeta(meta *generate.StructMeta) (*genInfo, error) {
	structName := meta.ModelStructName
	if g.Data[structName] == nil {
		g.Data[structName] = &genInfo{StructMeta: meta}
	}
	return g.Data[structName], nil
}

func (g *Generator) render(tmpl string, wr io.Writer, data interface{}) error {
	err := g.template.ExecuteTemplate(wr, tmpl, data)
	return err
}
