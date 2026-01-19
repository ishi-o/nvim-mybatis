local M = {}

--- @class NvimMybatisConfig
--- @field enabled boolean enable nvim-mybatis
--- @field xml_search_pattern string[] where to search xml files
--- @field mapper_name_pattern string[] if the file need to load nvim-mybatis
--- @field classpath string[] relative path from classpath to project_path
--- @field debug boolean enable debug mode

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
	debug = true,
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
