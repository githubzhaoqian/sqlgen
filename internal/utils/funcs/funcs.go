package funcs

import (
	"path/filepath"
	"strings"
	"text/template"

	"github.com/gobeam/stringy"
)

var FuncMap = template.FuncMap{
	"suffixes": Suffixes,
	"suffix":   suffix,
	"pathBase": pathBase,
	"inMap":    inMap,
	"lcFirst":  LcFirst,
	"contains": Contains,
}

// Suffixes 后缀
func Suffixes(name string, suffixList []string) bool {
	for _, suffix := range suffixList {
		if strings.HasSuffix(name, suffix) {
			return true
		}
	}
	return false
}

// Contains 包含
func Contains(name string, contains ...string) bool {
	for _, item := range contains {
		if strings.Contains(name, item) {
			return true
		}
	}
	return false
}

// suffix 后缀
func suffix(name, fix string) bool {
	return strings.HasSuffix(name, fix)
}

// pathBase 目录名
func pathBase(path string) string {
	return filepath.Base(path)
}

// inMap 判断key是否在map中
func inMap(key string, data map[string]struct{}) bool {
	_, ok := data[key]
	return ok
}

func ToLower(src string) string {
	str := stringy.New(src)
	return str.CamelCase().ToLower()
}

func Camel(src string) string {
	str := stringy.New(src)
	return str.CamelCase().Get()
}

func Snake(src string) string {
	str := stringy.New(src)
	return str.SnakeCase().ToLower()
}

func LcFirst(src string) string {
	str := stringy.New(src)
	return str.LcFirst()
}
