--- @module 'mybatis.types'

--- @class mybatis.completion.blink.MyBatisSource: blink.cmp.Source
--- @field config table
--- @field opts table
--- @field cache table
--- @field watchers table

--- @class mybatis.treesitter.Query
--- @field lang string
--- @field query string

--- @class mybatis.NvimMybatisConfig
--- @field autocmd? boolean Enable nvim-mybatis
--- @field xml_search_pattern? string[] Patterns to search for XML files
--- @field mapper_name_pattern? string[] Patterns to identify Mapper files for plugin loading
--- @field classpath? string[] Relative paths from classpath to project root
--- @field root_file? string[] Root build files
--- @field refresh_strategy? "os_watch"|"manual_watch"|"polling"|"none" Refresh strategy
--- @field polling_interval? integer Polling interval (ms)
--- @field debug? boolean Enable debug mode

--- @class mybatis.action.CrudTagArgs
--- @field interface string
--- @field method string
--- @field bufnr integer
