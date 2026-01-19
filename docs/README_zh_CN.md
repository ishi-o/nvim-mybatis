# nvim-mybatis

简体中文|[English](./README_en.md)

一个基于 Tree-sitter 的轻量级 Neovim 插件，用于增强 Java MyBatis Mapper 接口与其对应 XML 文件之间的导航。

## ✨ 特性

- 从 XML 文件中的 `namespace` 或 `resultType` 属性，导航到其对应的 Java 接口或类。
- 从 XML 文件中 CRUD 标签 (`select`, `insert`, `update`, `delete`) 的 `id` 属性，导航到 Java Mapper 接口中的对应方法。
- 从 Java Mapper 接口，导航到其关联 XML 文件中的 `namespace` 声明处。
- 从 Java Mapper 接口内部的方法，导航到 XML 文件中对应的 CRUD 标签处。

## 📦 安装

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

## ⚙️ 配置

可以通过设置 `nvim-mybatis` 模块来配置插件。以下是默认设置：

```lua
--- @class NvimMybatisConfig
--- @field enabled boolean 启用 nvim-mybatis 插件
--- @field xml_search_pattern string[] 用于搜索 XML 文件的模式
--- @field mapper_name_pattern string[] 用于识别 Mapper 文件以加载插件的模式
--- @field classpath string[] 从类路径到项目根目录的相对路径
--- @field debug boolean 启用调试模式

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

## 📝 注意事项

- 本插件依赖于 `nvim-treesitter` 的 Java 和 XML 语法解析器。请确保已安装并启用这些解析器。
- `xml_search_pattern` 中的搜索模式相对于项目根目录（通过检测 `pom.xml` 文件的存在来确定）。
- `mapper_name_pattern` 设置决定了插件将为哪些文件（包括 `.java` 和 `.xml`）覆盖默认的 `gd` (转到定义) 行为，以提供 MyBatis 特定的导航。默认情况下，它适用于任何文件名中包含 “Mapper” 或 “mapper” 的文件。
- 启用 `debug` 选项时，将打印诊断信息以帮助排查问题。

## 🤝 贡献

欢迎提交贡献、问题报告和功能请求。如果您想参与贡献，请随时查看 [issues 页面](https://github.com/ishi-o/nvim-mybatis/issues)。

## 📄 许可证

本项目基于 [MIT 许可证](LICENSE) 授权。
