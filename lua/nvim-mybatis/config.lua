--- @module 'mybatis.config'
--- Configuration values and defaults for nvim-mybatis.

local M = {}

--- @type mybatis.NvimMybatisConfig
local DEFAULT_CONFIG = {
	autocmd = true,
	xml_search_pattern = {
		"**/*Mapper*.xml",
	},
	xml_search_tool = "default",
	completion_provider = "default",
	mapper_name_pattern = {
		"[Mm]apper",
	},
	classpaths = {
		java = {
			"src/main/java",
		},
		xml = {
			"src/main/resources",
		},
	},
	root_file = {
		"pom.xml",
		"build.gradle",
		"build.gradle.kts",
	},
	debug = false,
}

--- @type mybatis.NvimMybatisConfig
M.values = vim.deepcopy(DEFAULT_CONFIG)

--- Defaults: `autocmd = true`, `xml_search_pattern = { "**/*Mapper*.xml" }`,
--- `xml_search_tool = "default"`, `completion_provider = "default"`,
--- `mapper_name_pattern = { "[Mm]apper" }`, Java/XML classpaths of
--- `src/main/java` and `src/main/resources`, Maven/Gradle root files, and
--- `debug = false`.
--- @param config mybatis.NvimMybatisConfig?
function M.setup(config)
	local overrides = vim.deepcopy(config or {})
	local values = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), overrides)
	-- Keep the table identity stable because other modules retain this reference.
	for key in pairs(M.values) do
		M.values[key] = nil
	end
	for key, value in pairs(values) do
		M.values[key] = value
	end
	return M
end

--- @return mybatis.NvimMybatisConfig
function M.get()
	return M.values
end

return M
