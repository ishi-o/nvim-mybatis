local M = {}

local prefix = "[MyBatis] "
local config = require("nvim-mybatis.config")

--- Log a message.
--- @param msg string Message to log
--- @param level? integer Log level from `vim.log.levels` (default: INFO)
function M.log(msg, level)
	level = level or vim.log.levels.INFO
	vim.notify(prefix .. msg, level)
end

--- Log a INFO message.
--- @param msg string Message to log
function M.info(msg)
	M.log(msg, vim.log.levels.INFO)
end

--- Log a WARN message.
--- @param msg string Message to log
function M.warn(msg)
	M.log(msg, vim.log.levels.WARN)
end

--- Log a ERROR message.
--- @param msg string Message to log
function M.error(msg)
	M.log(msg, vim.log.levels.ERROR)
end

--- Log a message with conditional `debug` config filtering.
--- @param msg string Message to log
--- @param level? integer Log level from `vim.log.levels` (default: INFO)
function M.debug(msg, level)
	if not config.debug then
		return
	end
	level = level or vim.log.levels.INFO
	vim.notify(prefix .. msg, level)
end

return M
