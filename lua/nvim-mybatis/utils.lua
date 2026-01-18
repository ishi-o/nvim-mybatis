local M = {}

local config = require("nvim-mybatis").config

function M.is_mybatis_xml(bufnr)
	local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
	for _, pattern in ipairs(config.xml_pattern) do
		if filename:match(pattern) then
			return true
		end
	end
	return false
end

function M.is_mapper(bufnr) end

return M
