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
M.values = {}

--- @param config mybatis.NvimMybatisConfig?
function M.setup(config)
	local values = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), config or {})
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
