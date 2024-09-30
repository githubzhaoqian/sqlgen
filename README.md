# sql gen

由 Gen Guides [https://gorm.io/gen/index.html](https://gorm.io/gen/index.html) 改写。

# 功能
- [X] 输出默认模板
- [X] 指定模板路径
- [X] 指定tag
- [X] 生成 model 属性get方法
- [X] 是否覆盖已生成的文件
- [X] table 正则并生成 model query 路径
- [X] table 路径风格
- [X] 动态常量类型生成
- [X] 自定义类型对应包的导入
- [X] 动态模板生成代码

# 安装
go install github.com/githubzhaoqian/sqlgen/tools/gentool@latest

# 命令
```text
  -c string
        is path for .sqlgen.yml (default ".sqlgen.yaml")
  -db string
        input mysql|postgres|sqlite|sqlserver|clickhouse. consult[https://gorm.io/docs/connecting_to_the_database.html]
  -dsn string
        consult[https://gorm.io/docs/connecting_to_the_database.html]
  -fieldCoverable
        generate with pointer when field has default value
  -fieldNullable
        generate with pointer when field is nullable
  -fieldSignable
        detect integer field's unsigned type, adjust generated data type
  -fieldWithTags string
        generate field with custom tag
  -ot string
        output template 指定模板输出目录
  -overwrite
        overwrite existing file
  -tableRegexp string
        table regexp
  -tableRegexpStyle string
        table regexp style: lower/camel/snake
  -tables string
        enter the required data table or leave it blank
  -templateDir string
        generated with template directory
```

# 配置文件
```yaml
version: "0.1"
database:
  # 数据库连接 consult[https://gorm.io/docs/connecting_to_the_database.html]"
  dsn: "dbUser:dbPassword@tcp(host:port)/dbName?charset=utf8mb4&parseTime=true&loc=Asia%2FShanghai"
  # 数据库类型 consult[https://gorm.io/docs/connecting_to_the_database.html]
  db: "mysql"
  # 表类型 You can cli input : orders,users,goods
  tables: # 指定表 可以在命令行使用 tables
    - failed_job
    - server_user
    - admin_user
  defaultAllTable: false  # 未指定table 是否生成全部表
  # generate with pointer when field is nullable
  #  nullable 生成指针
  fieldNullable: false  
  fieldCoverable: false
  # Signable生成 无符号类型
  fieldSignable: true 

  # 是否覆盖文件
  overwrite: false
  # table 正则用于替换路径使用
  tableRegexp: ^([a-z]+)_([a-z_]+)$
  modelName: "{2}"
  #  table 正则风格
  tableRegexpStyle: lower  # lower/camel/snake
  # 自定义tag 按json 蛇形添加
  fieldWithTags:
    - json
  # 指定模板目录，默认系统模板
  templateDir:
  templates:
    - outPath: "./internal/domain/{1}/internal/model/{2}/model.go"
      name: "Model"
      isGo: true # 是否是go文件
    - outPath: "./internal/domain/{1}/bean/{2}/interface.go"
      name: "BeanInterface"
      isGo: true
    - outPath: "./internal/domain/{1}/bean/{2}/bean.go"
      name: "Bean"
      isGo: true
    - outPath: "./internal/domain/{1}/bean/{2}/po.go"
      name: "PO"
      isGo: true
    - outPath: "./internal/types/{2}/types.go"
      name: "Types"
      isGo: true
    - outPath: "./internal/domain/{1}/internal/mapper/{2}/interface.go"
      name: "MapperInterface"
      isGo: true
    - outPath: "./internal/domain/{1}/internal/mapper/{2}/mapper.go"
      name: "Mapper"
      isGo: true
    - outPath: "./internal/domain/{1}/service/{2}/interface.go"
      name: "ServiceInterface"
      isGo: true
    - outPath: "./internal/domain/{1}/service/{2}/service.go"
      name: "Service"
      isGo: true
  # 动态常量
  dynamicConstSuffixes:
    - "Status"
    - "Type"
  # 哪些是自动生成值的字段
  autoValueFields:
    - "ID"
    - "UpdateTime"
    - "CreateTime"
  dynamicConstOutPath: "./internal/consts/{2}/consts.go"
  dynamicConstTemplate: "Consts"
  # 常量包是否自动导入 ImportPkgPaths 变量中
  dynamicConstImport: false
  # 常量包后缀
  dynamicAliasSuffix: "Consts"
  # 禁用表名复数
  singularTable: true
  # 首字母缩略 
  # "API", "ASCII", "CPU", "CSS", "DNS", "EOF", "GUID", "HTML", "HTTP", "HTTPS", "ID", "IP", 
  # "JSON", "LHS", "QPS", "RAM", "RHS", "RPC", "SLA", "SMTP", "SSH", "TLS", "TTL", "UID", "UI", 
  # "UUID", "URI", "URL", "UTF8", "VM", "XML", "XSRF", "XSS"
  initialisms: true 
  # 自定义类型转换
  convTypeMap:
    timestamp: "timex.Time"
    datetime: "timex.Time"
  # 自定义类型包
  convTypePkgMap:
    "timex.Time": "gofastddd/internal/utils/timex"
```

# template 值说明
```sql
CREATE TABLE `admin_user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mobile` varchar(11) DEFAULT NULL COMMENT '手机',
  `email` varchar(255) DEFAULT NULL COMMENT '邮箱',
  `nice_name` varchar(50) NOT NULL DEFAULT '' COMMENT '昵称',
  `password` varchar(32) NOT NULL DEFAULT '' COMMENT '密码',
  `salt` char(5) NOT NULL COMMENT '加盐',
  `avatar` varchar(255) NOT NULL DEFAULT '' COMMENT '头像',
  `status` tinyint(3) unsigned NOT NULL DEFAULT '1' COMMENT '状态',
  `reason` varchar(255) DEFAULT '' COMMENT '原因',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_mobile` (`mobile`),
  UNIQUE KEY `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员表';

```

```json
{
    "Generated": true,
    "FileName": "admin_user",
    "S": "u",
    "QueryStructName": "user",
    "ModelStructName": "User",
    "TableName": "admin_user",
    "TableComment": "管理员表",
    "Fields": [
        {
            "Name": "ID",
            "ColumnName": "id",
            "TypeName": "uint32",
            "OriginalTypeName": "uint32",
            "DatabaseTypeName": "int",
            "ColumnType": "int(10) unsigned",
            "PrimaryKey": true,
            "AutoIncrement": true,
            "Length": 0,
            "DecimalSizeOK": true,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 10,
            "Nullable": false,
            "Unique": false,
            "ScanType": {},
            "Comment": "",
            "DefaultValueOK": false,
            "DefaultValue": "",
            "CustomTypeMap": {}
        },
        {
            "Name": "Mobile",
            "ColumnName": "mobile",
            "TypeName": "string",
            "OriginalTypeName": "string",
            "DatabaseTypeName": "varchar",
            "ColumnType": "varchar(11)",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 11,
            "DecimalSizeOK": false,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": true,
            "Unique": true,
            "ScanType": {},
            "Comment": "手机",
            "DefaultValueOK": false,
            "DefaultValue": "",
            "CustomTypeMap": {}
        },
        {
            "Name": "Email",
            "ColumnName": "email",
            "TypeName": "string",
            "OriginalTypeName": "string",
            "DatabaseTypeName": "varchar",
            "ColumnType": "varchar(255)",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 255,
            "DecimalSizeOK": false,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": true,
            "Unique": true,
            "ScanType": {},
            "Comment": "邮箱",
            "DefaultValueOK": false,
            "DefaultValue": "",
            "CustomTypeMap": {}
        },
        {
            "Name": "NiceName",
            "ColumnName": "nice_name",
            "TypeName": "string",
            "OriginalTypeName": "string",
            "DatabaseTypeName": "varchar",
            "ColumnType": "varchar(50)",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 50,
            "DecimalSizeOK": false,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": false,
            "Unique": false,
            "ScanType": {},
            "Comment": "昵称",
            "DefaultValueOK": true,
            "DefaultValue": "",
            "CustomTypeMap": {}
        },
        {
            "Name": "Password",
            "ColumnName": "password",
            "TypeName": "string",
            "OriginalTypeName": "string",
            "DatabaseTypeName": "varchar",
            "ColumnType": "varchar(32)",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 32,
            "DecimalSizeOK": false,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": false,
            "Unique": false,
            "ScanType": {},
            "Comment": "密码",
            "DefaultValueOK": true,
            "DefaultValue": "",
            "CustomTypeMap": {}
        },
        {
            "Name": "Salt",
            "ColumnName": "salt",
            "TypeName": "string",
            "OriginalTypeName": "string",
            "DatabaseTypeName": "char",
            "ColumnType": "char(5)",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 5,
            "DecimalSizeOK": false,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": false,
            "Unique": false,
            "ScanType": {},
            "Comment": "加盐",
            "DefaultValueOK": false,
            "DefaultValue": "",
            "CustomTypeMap": {}
        },
        {
            "Name": "Avatar",
            "ColumnName": "avatar",
            "TypeName": "string",
            "OriginalTypeName": "string",
            "DatabaseTypeName": "varchar",
            "ColumnType": "varchar(255)",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 255,
            "DecimalSizeOK": false,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": false,
            "Unique": false,
            "ScanType": {},
            "Comment": "头像",
            "DefaultValueOK": true,
            "DefaultValue": "",
            "CustomTypeMap": {}
        },
        {
            "Name": "Status",
            "ColumnName": "status",
            "TypeName": "userConsts.Status",
            "OriginalTypeName": "uint32",
            "DatabaseTypeName": "tinyint",
            "ColumnType": "tinyint(3) unsigned",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 0,
            "DecimalSizeOK": true,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 3,
            "Nullable": false,
            "Unique": false,
            "ScanType": {},
            "Comment": "状态",
            "DefaultValueOK": true,
            "DefaultValue": "1",
            "CustomTypeMap": {}
        },
        {
            "Name": "Reason",
            "ColumnName": "reason",
            "TypeName": "string",
            "OriginalTypeName": "string",
            "DatabaseTypeName": "varchar",
            "ColumnType": "varchar(255)",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 255,
            "DecimalSizeOK": false,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": true,
            "Unique": false,
            "ScanType": {},
            "Comment": "原因",
            "DefaultValueOK": true,
            "DefaultValue": "",
            "CustomTypeMap": {}
        },
        {
            "Name": "UpdateTime",
            "ColumnName": "update_time",
            "TypeName": "timex.Time",
            "OriginalTypeName": "timex.Time",
            "DatabaseTypeName": "timestamp",
            "ColumnType": "timestamp",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 0,
            "DecimalSizeOK": true,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": false,
            "Unique": false,
            "ScanType": {},
            "Comment": "",
            "DefaultValueOK": true,
            "DefaultValue": "CURRENT_TIMESTAMP",
            "CustomTypeMap": {}
        },
        {
            "Name": "CreateTime",
            "ColumnName": "create_time",
            "TypeName": "timex.Time",
            "OriginalTypeName": "timex.Time",
            "DatabaseTypeName": "timestamp",
            "ColumnType": "timestamp",
            "PrimaryKey": false,
            "AutoIncrement": false,
            "Length": 0,
            "DecimalSizeOK": true,
            "DecimalSizeScale": 0,
            "DecimalSizePrecision": 0,
            "Nullable": false,
            "Unique": false,
            "ScanType": {},
            "Comment": "",
            "DefaultValueOK": true,
            "DefaultValue": "CURRENT_TIMESTAMP",
            "CustomTypeMap": {}
        }
    ],
    "ImportPkgPaths": [
        "gofastddd/internal/utils/timex"
    ],
    "TemplatePkgPath": {
        "Consts": "github.com/githubzhaoqian/sqlgen/tools/gentool/internal/consts/user"
    },
    "PkgPath": "",
    "Package": "user",
    "Type": "",
    "ConvTypeMap": {
        "datetime": "timex.Time",
        "timestamp": "timex.Time"
    },
    "ConvTypePkgMap": {
        "timex.Time": "gofastddd/internal/utils/timex"
    },
    "DynamicConstSuffixes": [
        "Status",
        "Type"
    ],
    "AutoValueFields": {},
    "FieldWithTags": [
        "json"
    ]
}
```

# 增加方法
```golang
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
func LcFirst(src string) string {
    str := stringy.New(src)
    return str.LcFirst()
}
```
## License

Released under the [MIT License](https://github.com/githubzhaoqian/sqlgen/blob/master/License)
