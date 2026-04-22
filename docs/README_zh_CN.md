# nvim-mybatis

简体中文 | [English](/docs/README_en.md)

一款基于 Tree-sitter 的轻量级 Neovim 插件，用于增强 Java MyBatis Mapper 接口与其对应 XML 文件之间的导航体验。

## ✨ 功能特性

### 🔄 **导航**

#### XML → Java

- 从 MyBatis XML 类型属性跳转到其对应的 Java 类型，支持的属性包括：`namespace`, `resultType`, `parameterType`, `type`, `javaType`, `ofType`, `typeHandler`。
- 从 SQL 语句标签的 `id` 属性跳转到 Mapper 接口中对应的方法。
- 从 `<result property="...">` 标签跳转到其 Java 实体类中的对应字段。

#### Java 代码 → XML 映射文件

- 从 Mapper 接口跳转到其 XML 文件中的 `<mapper namespace="...">` 声明处。
- 从 Mapper 接口方法跳转到 XML 文件中对应的 SQL 语句标签处。

#### XML → XML 导航

- 从 `<include refid="...">` 标签跳转到其目标 `<sql id="...">` 定义处，支持简单引用和全限定引用。
- 从 `<resultMap extends="...">` 或 `<select resultMap="...">` 标签跳转到其目标 `<resultMap>` 定义处。

### 🎯 **智能代码补全**

- **[blink.cmp](https://github.com/Saghen/blink.cmp) 集成**: 为 `namespace`、`resultType`、`parameterType`、`type`、`javaType` 和 `ofType` 属性提供包含包名/类名建议的自动补全。

### **代码操作（`Code Action`）**

- `nvim-mybatis` 会将`Code Action`注入到名为`jdtls`的语言服务器中。符合条件的条目会在调用`vim.lsp.buf.code_action`时提供，这需要一个已连接的`jdtls`服务器。
- `Generate MyBatis Tag`：当光标指向 Mapper 接口中的一个方法时，此操作会智能判断`CRUD`类型，并在相关联的`XML`文件中生成对应的`XML tag`代码片段。

## 📦 安装

<details>
<summary>Lazy.nvim</summary>

```lua
{
  "ishi-o/nvim-mybatis",
  opts = {},
}
```

</details>

<details>
<summary>blink.cmp 集成配置</summary>

如需启用自动补全支持，请按如下方式配置 blink.cmp：

```lua
require("blink.cmp").setup({
	sources = {
		default = {
			"lsp",
			"path",
			"snippets",
			"buffer",
			"mybatis", -- 添加此补全源
		},
		providers = {
			mybatis = {
				name = "Mybatis",
				module = "nvim-mybatis.completion.blink",
			},
		},
	},
})
```

</details>

## ⚙️ 配置

```lua
--- @class mybatis.NvimMybatisConfig
--- @field autocmd? boolean 启用 nvim-mybatis 的自动加载。启用后，在打开文件时会挂钩 LSP 跳转行为（vim.lsp.buf.definition）
--- @field xml_search_pattern? string[] 搜索 XML 文件的模式
--- @field xml_search_tool? mybatis.utils.SearchTool 搜索 XML 文件的工具，"default" 表示按顺序尝试 "rg"、"ag"、"grep"
--- @field completion_provider? mybatis.completion.Provider XML 补全提供者，"default" 表示按顺序尝试 "index"、"jdtls"
--- @field mapper_name_pattern? string[] 用于识别 Mapper XML 文件的 Lua string.match 模式。仅当打开的 XML 文件名匹配这些模式时，才启用插件的导航功能
--- @field classpaths? { java?: string[], xml?: string[] } 从 classpath 到项目/模块根目录的相对路径
--- @field root_file? string[] 根构建文件，用于定位项目/模块根目录（从当前文件向上搜索）
--- @field type_attributes? string[] 表示类型的 XML 属性名
--- @field crud_tags? string[] 表示 CRUD 映射的 XML 标签名
--- @field debug? boolean 启用调试模式

--- @type NvimMybatisConfig
local DEFAULT_CONFIG = {
	autocmd = true,
	xml_search_pattern = {
		"**/*Mapper*.xml",
	},
	xml_search_tool = "default",
	completion_provider = "default",
	mapper_name_pattern = {
		"[Mm]apper",
	},
	classpaths = {
		java = {
			"src/main/java",
		},
		xml = {
			"src/main/resources",
		},
	},
	root_file = {
		"pom.xml",
		"build.gradle",
		"build.gradle.kts",
	},
	type_attributes = {
		"namespace",
		"resultType",
		"parameterType",
		"type",
		"javaType",
		"ofType",
		"typeHandler",
	},
	crud_tags = {
		"select",
		"update",
		"delete",
		"insert",
	},
	debug = false,
}
```

## 📝 注意事项

- **tree-sitter**: 需要安装并启用`Java`与`XML`的解析器

## 🤝 参与贡献

欢迎提交问题报告和功能请求，请访问 [GitHub Issues 页面](https://github.com/ishi-o/nvim-mybatis/issues)。

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。
