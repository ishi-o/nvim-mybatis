# nvim-mybatis

[简体中文](/docs/README_zh_CN.md) | English

A lightweight Neovim plugin powered by Tree-sitter for enhanced navigation between Java MyBatis Mapper interfaces and their corresponding XML files.

## ✨ Features

### 🔄 **Navigation**

#### XML Mapping File → Java Code

- Navigate from MyBatis XML type attributes to their corresponding Java types, supporting attributes: `namespace`, `resultType`, `parameterType`, `type`, `javaType`, `ofType`, `typeHandler`.
- Navigate from the `id` attribute of SQL statement tags to the corresponding method in the Mapper interface.
- Navigate from a `<result property="...">` tag to the corresponding field in its Java entity class.

#### Java Code → XML Mapping File

- Navigate from a Mapper interface to the `<mapper namespace="...">` declaration in its XML file.
- Navigate from a Mapper interface method to its corresponding SQL statement tag in the XML file.

#### XML → XML Navigation

- Navigate from an `<include refid="...">` tag to its target `<sql id="...">` definition, supporting both simple and fully-qualified references.
- Navigate from a `<resultMap extends="...">` or `<select resultMap="...">` tag to its target `<resultMap>` definition.

### 🎯 **Intelligent Code Completion**

- **[blink.cmp](https://github.com/Saghen/blink.cmp) Integration**: Auto-completion for `namespace`, `resultType`, `parameterType`, `type`, `javaType`, or `ofType` attributes with package/class suggestions

### **Code Action**

- `nvim-mybatis` injects `Code Action` into the language server named `jdtls`. Qualified entries will be provided when `vim.lsp.buf.code_action` is invoked, which requires a connected `jdtls` server.
- `Generate MyBatis Tag`: When the cursor points to a method in a Mapper interface, this action intelligently determines the `CRUD` type and generates the corresponding `XML tag` snippet in the associated `XML` file.

## 📦 Installation

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
<summary>blink.cmp Integration</summary>

For auto-completion support, configure blink.cmp as follows:

```lua
require("blink.cmp").setup({
	sources = {
		default = {
			"lsp",
			"path",
			"snippets",
			"buffer",
			"mybatis", -- Add this source
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

## ⚙️ Configuration

```lua
--- @class mybatis.NvimMybatisConfig
--- @field autocmd? boolean  Enable auto-loading of nvim-mybatis. When enabled, hooks into LSP jump behavior (vim.lsp.buf.definition) on file open
--- @field xml_search_pattern? string[] Patterns to search for XML files
--- @field xml_search_tool? "rg"|"ag"|"grep"|"default" Tool to search XML files, "default": auto fallback to built-in grep
--- @field mapper_name_pattern? string[] Lua string.match patterns to identify Mapper XML files. Plugin navigation is only enabled when an opened XML filename matches these patterns
--- @field classpath? string[] Relative paths from classpath to project/module root
--- @field root_file? string[] Root build files to locate project/module root (searches upward from current file)
--- @field refresh_strategy? "os_watch"|"manual_watch"|"polling"|"none" Refresh strategy
--- @field polling_interval? integer Polling interval (ms)
--- @field debug? boolean Enable debug mode

--- @type NvimMybatisConfig
local DEFAULT_CONFIG = {
	autocmd = true,
	xml_search_pattern = {
		"**/*Mapper*.xml",
	},
	xml_search_tool = "default",
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

## 📝 Notes

- **tree-sitter**: Requires Java and XML parsers
- **Determines how the plugin updates its internal class index**: `os_watch` (filesystem events via libuv, may fail), `manual_watch` (monitors specific directories), `polling` (periodic scans), or `none` (no auto-refresh).

## 🤝 Contributing

Issues and feature requests are welcome on the [GitHub Issues page](https://github.com/ishi-o/nvim-mybatis/issues).

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
