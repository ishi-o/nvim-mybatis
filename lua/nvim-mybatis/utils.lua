local M = {}

local config = require("nvim-mybatis.config"):get()

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

--- Log a message.
--- @param msg string Message to log
--- @param level? integer Log level from `vim.log.levels` (default: INFO)
function M.log(msg, level)
	level = level or vim.log.levels.INFO
	vim.notify("[MyBatis] " .. msg, level)
end

--- Log a message with conditional `debug` config filtering.
--- @param msg string Message to log
--- @param level? integer Log level from `vim.log.levels` (default: INFO)
function M.debug(msg, level)
	if not config.debug then
		return
	end
	level = level or vim.log.levels.INFO
	vim.notify("[MyBatis] " .. msg, level)
end

return M
