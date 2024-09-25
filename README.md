# sql gen

由 Gen Guides [https://gorm.io/gen/index.html](https://gorm.io/gen/index.html) 改写。
# 安装
go install github.com/githubzhaoqian/sqlgen/tools/gentool@latest

# 命令
```text
  -c string
        is path for sqlgen.yml
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
        output template 指定模板数据目录
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
  #  默认生成指针类型
  fieldNullable: false  
  fieldCoverable: false
  # 数字类型是否支持 无负数类型
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
    - outPath: "./internal/domain/{1}/bean/{2}/interface.go"
      name: "BeanInterface"
    - outPath: "./internal/domain/{1}/bean/{2}/bean.go"
      name: "Bean"
    - outPath: "./internal/domain/{1}/bean/{2}/po.go"
      name: "PO"
    - outPath: "./internal/types/{2}/types.go"
      name: "Types"
    - outPath: "./internal/domain/{1}/internal/mapper/{2}/interface.go"
      name: "MapperInterface"
    - outPath: "./internal/domain/{1}/internal/mapper/{2}/mapper.go"
      name: "Mapper"
    - outPath: "./internal/domain/{1}/service/{2}/interface.go"
      name: "ServiceInterface"
    - outPath: "./internal/domain/{1}/service/{2}/service.go"
      name: "Service"
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
  # 自定义类型转换
  convTypeMap:
    timestamp: "timex.Time"
    datetime: "timex.Time"
  # 自定义类型包
  convTypePkgMap:
    "timex.Time": "gofastddd/internal/utils/timex"
```


## 功能
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

## License

Released under the [MIT License](https://github.com/githubzhaoqian/sqlgen/blob/master/License)
