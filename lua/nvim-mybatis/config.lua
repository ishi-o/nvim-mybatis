local M = {}

--- @class NvimMybatisConfig
--- @field enabled? boolean Enable nvim-mybatis
--- @field xml_search_pattern? string[] Patterns to search for XML files
--- @field mapper_name_pattern? string[] Patterns to identify Mapper files for plugin loading
--- @field classpath? string[] Relative paths from classpath to project root
--- @field root_file? string[] Root build files
--- @field refresh_strategy? "os_watch"|"manual_watch"|"polling"|"none" Refresh strategy
--- @field polling_interval? integer Polling interval
--- @field debug? boolean Enable debug mode

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
	root_file = {
		"pom.xml",
		"build.gradle",
		"build.gradle.kts",
	},
	refresh_strategy = "manual_watch",
	polling_interval = 10000,
	debug = false,
}

--- @type NvimMybatisConfig
M.values = DEFAULT_CONFIG

--- @param config NvimMybatisConfig?
function M.setup(config)
	M.values = vim.tbl_deep_extend("force", M.values, config or {})
	return M
end

--- @return NvimMybatisConfig
function M.get()
	return M.values
end

return M
