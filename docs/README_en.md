# nvim-mybatis

[简体中文](/docs/README_zh_CN.md) | English

A lightweight Neovim plugin powered by Tree-sitter for enhanced navigation between Java MyBatis Mapper interfaces and their corresponding XML files.

## ✨ Features

### 🔄 **Bi-directional Navigation**

- **XML → Java**:
  - From `namespace`, `resultType`, `parameterType`, `type`, `javaType`, or `ofType` attributes to their corresponding Java interface or class.
  - From SQL tag `id` attribute (`<select>`, `<insert>`, `<update>`, `<delete>`) to corresponding Java method.

- **Java → XML**:
  - From Mapper interface to XML file's `namespace` declaration.
  - From interface method to corresponding SQL tag in XML.

### 🎯 **Intelligent Code Completion**

- **[blink.cmp](https://github.com/Saghen/blink.cmp) Integration**: Auto-completion for `namespace`, `resultType`, `parameterType`, `type`, `javaType`, or `ofType` attributes with package/class suggestions

## 📦 Installation

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
--- @field autocmd? boolean Enable nvim-mybatis
--- @field xml_search_pattern? string[] Patterns to search for XML files
--- @field mapper_name_pattern? string[] Patterns to identify Mapper files for plugin loading
--- @field classpath? string[] Relative paths from classpath to project root
--- @field root_file? string[] Root build files
--- @field refresh_strategy? "os_watch"|"manual_watch"|"polling"|"none" Refresh strategy
--- @field polling_interval? integer Polling interval (ms)
--- @field debug? boolean Enable debug mode

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

## 📝 Notes

- **Tree-sitter Dependency**: Requires Java and XML parsers (`:TSInstall java xml`)
- **ripgrep Dependency**: The plugin relies on ripgrep (rg) for fast file searching and indexing.
- **File Pattern Matching**: `mapper_name_pattern` controls which files activate the plugin's navigation features
- **Project Detection**: Searches upward for `root_file` patterns to locate project boundaries
- **Determines how the plugin updates its internal class index**: `os_watch` (filesystem events via libuv, may fail), `manual_watch` (monitors specific directories), `polling` (periodic scans), or `none` (no auto-refresh).

## 🤝 Contributing

Issues and feature requests are welcome on the [GitHub Issues page](https://github.com/ishi-o/nvim-mybatis/issues).

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
