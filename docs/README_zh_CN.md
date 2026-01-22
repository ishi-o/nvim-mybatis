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
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
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
--- @field autocmd? boolean 启用 nvim-mybatis
--- @field xml_search_pattern? string[] 用于搜索 XML 文件的模式
--- @field mapper_name_pattern? string[] 用于识别应加载插件的 Mapper 文件的模式
--- @field classpath? string[] 从 classpath 到项目根目录的相对路径
--- @field root_file? string[] 项目根目录构建文件标识
--- @field refresh_strategy? "os_watch"|"manual_watch"|"polling"|"none" 刷新策略
--- @field polling_interval? integer 轮询间隔（毫秒）
--- @field debug? boolean 启用调试模式

--- @type NvimMybatisConfig
local DEFAULT_CONFIG = {
	autocmd = true,
	xml_search_pattern = {
		"**/*Mapper*.xml",
	},
	mapper_name_pattern = {
		"[Mm]apper",
	},
	classpath = {
		"src/main/java",
	},
	root_file = {
		"pom.xml",
		"build.gradle",
		"build.gradle.kts",
	},
	refresh_strategy = "manual_watch",
	polling_interval = 10000,
	debug = false,
}
```

## 📝 注意事项

- **Tree-sitter 依赖**: 需要正确安装并启用 Java 和 XML 的 Tree-sitter 语法解析器（请执行 `:TSInstall java xml`）。
- **ripgrep 依赖**: 本插件依赖 ripgrep (rg) 来实现快速的文件搜索和索引。
- **文件模式匹配**: `mapper_name_pattern` 参数控制着哪些文件会激活本插件的导航功能。
- **项目根目录检测**: 插件会从当前文件所在目录向上搜索，根据 `root_file` 参数中定义的文件名来定位项目的根目录。
- **刷新策略说明**：决定插件如何更新其内部类索引：`os_watch`（通过 libuv 监听文件系统事件，可能失效）、`manual_watch`（监控特定目录）、`polling`（定期扫描）或 `none`（不自动刷新）。

## 🤝 参与贡献

欢迎提交问题报告和功能请求，请访问 [GitHub Issues 页面](https://github.com/ishi-o/nvim-mybatis/issues)。

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。
