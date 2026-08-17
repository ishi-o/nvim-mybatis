# class NvimMybatisConfig



- namespace: mybatis









---



## fields
---

### NvimMybatisConfig.autocmd
---
```lua
NvimMybatisConfig.autocmd : boolean?
```



Enable filetype autocmds and buffer-local gd navigation mappings








### NvimMybatisConfig.xml_search_pattern
---
```lua
NvimMybatisConfig.xml_search_pattern : string[]?
```



Patterns to search for XML files








### NvimMybatisConfig.xml_search_tool
---
```lua
NvimMybatisConfig.xml_search_tool : mybatis.utils.SearchTool?
```



Tool to search XML files, "default": try all tools in order "rg", "ag", "grep"








### NvimMybatisConfig.completion_provider
---
```lua
NvimMybatisConfig.completion_provider : mybatis.completion.Provider?
```



XML Completion provider, "default": try all providers in order "index", "jdtls"








### NvimMybatisConfig.mapper_name_pattern
---
```lua
NvimMybatisConfig.mapper_name_pattern : string[]?
```



Lua string.match patterns to identify Mapper XML files. Plugin navigation is only enabled when an opened XML filename matches these patterns








### NvimMybatisConfig.classpaths
---
```lua
NvimMybatisConfig.classpaths : { java: string[]?, xml: string[]? }?
```



Relative paths from classpath to project/module root








### NvimMybatisConfig.root_file
---
```lua
NvimMybatisConfig.root_file : string[]?
```



Root build files to locate project/module root (searches upward from current file)








### NvimMybatisConfig.debug
---
```lua
NvimMybatisConfig.debug : boolean?
```



Enable debug mode
