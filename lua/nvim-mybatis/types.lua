--- @module 'mybatis.types'
--- Public EmmyLua types used by nvim-mybatis.

--- @alias mybatis.completion.ContextKind
--- | "class" completion of fully-qualified java class names
--- | "method" completion of mapper interface method names
--- | "field" completion of entity field names
--- | "refid" completion of `<sql id>` fragment ids

--- @class mybatis.completion.Context
--- @field kind mybatis.completion.ContextKind
--- @field bufnr? integer buffer the completion was requested in
--- @field value_node? TSNode the AttValue node being completed
--- @field namespace? string mapper namespace (`method` context)
--- @field type? string owning entity type (`field` context)

--- @alias mybatis.completion.Provider
--- | "index"
--- | "jdtls"
--- | "default"

--- @class mybatis.completion.Backend
--- @field get_completion_items fun(partial: string, ctx: mybatis.completion.Context, callback: fun(items: lsp.CompletionItem[])): nil
--- @field get_completion_items_sync? fun(partial: string, ctx: mybatis.completion.Context): lsp.CompletionItem[]
--- @field is_available fun():boolean

--- @class mybatis.completion.IndexBackend: mybatis.completion.Backend
--- @field resolve fun(simple_name: string): string?
--- @field refresh fun(): nil

--- @class mybatis.treesitter.Query
--- @field lang string
--- @field query string

--- @class mybatis.NvimMybatisConfig
--- @field autocmd? boolean Enable filetype autocmds and buffer-local gd navigation mappings
--- @field xml_search_pattern? string[] Patterns to search for XML files
--- @field completion_provider? mybatis.completion.Provider Mapper completion provider, "default": try all providers in order "index", "jdtls"
--- @field mapper_name_pattern? string[] Lua string.match patterns to identify Mapper files. Mapper-file autocmds only apply when the filename matches these patterns
--- @field classpaths? { java?: string[], xml?: string[] } Relative paths from classpath to project/module root
--- @field root_file? string[] Root build files to locate project/module root (searches upward from current file)
--- @field debug? boolean Enable debug mode

--- @class mybatis.action.CrudTagArgs
--- @field interface string interface name
--- @field method string method name
--- @field resultType string `resultType` attribute
--- @field bufnr integer Java source file buffer number
