--- @module 'mybatis.config'

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
	type_attributes = {
		"namespace",
		"resultType",
		"parameterType",
		"type",
		"javaType",
		"ofType",
		"typeHandler",
	},
	crud_tags = {
		"select",
		"update",
		"delete",
		"insert",
	},
	debug = false,
}

--- @type mybatis.NvimMybatisConfig
M.values = DEFAULT_CONFIG

--- @param config mybatis.NvimMybatisConfig?
function M.setup(config)
	vim.tbl_deep_extend("force", M.values, config or {})
	return M
end

--- @return mybatis.NvimMybatisConfig
function M.get()
	return M.values
end

return M
