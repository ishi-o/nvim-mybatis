--- @module 'mybatis.config'

local M = {}

--- @type mybatis.NvimMybatisConfig
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

--- @type mybatis.NvimMybatisConfig
M.values = DEFAULT_CONFIG

--- @param config mybatis.NvimMybatisConfig?
function M.setup(config)
	M.values = vim.tbl_deep_extend("force", M.values, config or {})
	return M
end

--- @return mybatis.NvimMybatisConfig
function M.get()
	return M.values
end

return M
