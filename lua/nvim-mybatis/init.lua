local M = {}

local autocmd = require("nvim-mybatis.autocmd")

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
	M.config = vim.tbl_deep_extend("force", M.DEFAULT_CONFIG, config or {})
	if M.config.enabled then
		autocmd.setup()
	end
end

return M
