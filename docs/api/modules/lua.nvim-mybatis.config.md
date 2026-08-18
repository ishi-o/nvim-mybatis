# global lua.nvim-mybatis.config








---

## methods
---

### M.setup
---
```lua
function M.setup(config: mybatis.NvimMybatisConfig?) ->  table
```





Defaults: `autocmd = true`, `xml_search_pattern = { "**/*Mapper*.xml" }`,
`xml_search_tool = "default"`, `completion_provider = "default"`,
`mapper_name_pattern = { "[Mm]apper" }`, Java/XML classpaths of
`src/main/java` and `src/main/resources`, Maven/Gradle root files, and
`debug = false`.








### M.get
---
```lua
function M.get() ->  mybatis.NvimMybatisConfig {
    autocmd = boolean?,
    xml_search_pattern = string[]?,
    xml_search_tool = mybatis.utils.SearchTool?,
    completion_provider = mybatis.completion.Provider?,
    mapper_name_pattern = string[]?,
    classpaths = { java: string[]?, xml: string[]? }?,
    root_file = string[]?,
    debug = boolean?,
}
```















## fields
---

### M.values
---
```lua
M.values : mybatis.NvimMybatisConfig {
    autocmd: boolean?,
    xml_search_pattern: string[]?,
    xml_search_tool: mybatis.utils.SearchTool?,
    completion_provider: mybatis.completion.Provider?,
    mapper_name_pattern: string[]?,
    classpaths: { java: string[]?, xml: string[]? }?,
    root_file: string[]?,
    debug: boolean?,
}
```
