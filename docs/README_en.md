# nvim-mybatis

[简体中文](./docs/README_zh_CN.md)|English

A lightweight Neovim plugin powered by Tree-sitter for enhanced navigation between Java MyBatis Mapper interfaces and their corresponding XML files.

## ✨ Features

- Navigate from the `namespace`or `resultType`attribute in an XML file to its corresponding Java interface or class.
- Navigate from the `id`attribute of a CRUD tag (`select`, `insert`, `update`, `delete`) in an XML file to its corresponding method in the Java Mapper interface.
- Navigate from a Java Mapper interface to the `namespace`declaration in its associated XML file.
- Navigate from a method within a Java Mapper interface to its corresponding CRUD tag in the XML file.

## 📦 Installation

<details>
<summary>Lazy.nvim</summary>

```lua
{
  "ishi-o/nvim-mybatis",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    build = ":TSUpdate",
    config = function()
      require("config.langservice.treesitter")
    end,
  },
}
```

</details>

## ⚙️ Configuration

The plugin can be configured by setting up the `nvim-mybatis` module. Below are the default settings:

```lua
--- @class NvimMybatisConfig
--- @field enabled boolean Enable nvim-mybatis
--- @field xml_search_pattern string[] Patterns to search for XML files
--- @field mapper_name_pattern string[] Patterns to identify Mapper files for plugin loading
--- @field classpath string[] Relative paths from classpath to project root
--- @field debug boolean Enable debug mode

--- @type NvimMybatisConfig
local DEFAULT_CONFIG = {
	enabled = true,
	xml_search_pattern = {
		"**/*Mapper*.xml",
	},
	mapper_name_pattern = {
		"[Mm]apper",
	},
	classpath = {
		"src/main/java",
	},
	debug = false,
}
```

## 📝 Notes

- This plugin depends on the `nvim-treesitter` parser for Java and XML. Ensure these parsers are installed and active.
- The search patterns in `xml_search_pattern` are relative to the project root (detected by the presence of a `pom.xml` file).
- The `mapper_name_pattern` setting determines for which files (both `.java` and `.xml`) the plugin will override the default `gd` (go-to-definition) behavior to provide MyBatis-specific navigation. By default, it applies to any file with "Mapper" or "mapper" in its filename.
- The `debug` option, when enabled, will print diagnostic information to help with troubleshooting.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome. Feel free to check the [issues page](https://github.com/ishi-o/nvim-mybatis/issues) if you want to contribute.

## 📄 License

This project is licensed under the [MIT License](LICENSE).
