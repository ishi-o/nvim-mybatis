--- @module 'mybatis.types'

--- @alias mybatis.completion.Context
--- | "class"
--- | "method"
--- | "field"

--- @alias mybatis.completion.Provider
--- | "index"
--- | "jdtls"
--- | "default"

--- @class mybatis.completion.Backend
--- @field name mybatis.completion.Provider
--- @field get_completion_items fun(partial: string, ctx: mybatis.completion.Context): lsp.CompletionItem[]
--- @field refresh fun(): nil
--- @field is_available fun():boolean
--- @field on_change fun(calback: fun()): nil

--- @class mybatis.treesitter.Query
--- @field lang string
--- @field query string

--- @alias mybatis.utils.SearchTool
--- | "rg"
--- | "ag"
--- | "grep"
--- | "default"

--- @alias mybatis.utils.SearchToolHandler fun(namespace_pattern: string, mapper_dir: string): string?

--- @class mybatis.NvimMybatisConfig
--- @field autocmd? boolean Enable auto-loading of nvim-mybatis. When enabled, hooks into LSP jump behavior (vim.lsp.buf.definition) on file open
--- @field xml_search_pattern? string[] Patterns to search for XML files
--- @field xml_search_tool? mybatis.utils.SearchTool Tool to search XML files, "default": try all tools in order "rg", "ag", "grep"
--- @field completion_provider? mybatis.completion.Provider XML Completion provider, "default": try all providers in order "index", "jdtls"
--- @field mapper_name_pattern? string[] Lua string.match patterns to identify Mapper XML files. Plugin navigation is only enabled when an opened XML filename matches these patterns
--- @field classpaths? { java?: string[], xml?: string[] } Relative paths from classpath to project/module root
--- @field root_file? string[] Root build files to locate project/module root (searches upward from current file)
--- @field type_attributes? string[] XML attributes which indicate a type
--- @field crud_tags? string[] XML tags which indicate a crud mapping
--- @field debug? boolean Enable debug mode

--- @class mybatis.action.CrudTagArgs
--- @field interface string interface name
--- @field method string method name
--- @field resultType string `resultType` attribute
--- @field bufnr integer Java source file buffer number
