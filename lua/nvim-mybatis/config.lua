local M = {}

M.DEFAULT_CONFIG = {
	enabled = true,
	xml_pattern = {
		".*Mapper%.xml",
	},
	classpath = {
		"src/main/java",
	},
}

function M.setup(config)
	M.values = vim.tbl_deep_extend("force", M.DEFAULT_CONFIG, config or {})
	return M
end

function M.get()
	return M.values
end

return M
