--- MyBatis parser registration and on-demand installation.

local M = {}

local LANGUAGE = "mybatis"
local PARSER_INFO = {
	install_info = {
		url = "https://github.com/ishi-o/tree-sitter-mybatis",
		revision = "0ecea601bd6b531a87c0f083f76ed96ac4c23949",
		queries = "queries/mybatis",
	},
}

local setup_done = false
local pending = {}

local function notify(message, level)
	vim.notify("[MyBatis] " .. message, level)
end

--- Register the parser with nvim-treesitter's custom parser table.
---
--- nvim-treesitter reloads this table when it runs `TSUpdate`, so this same
--- function is also used by the `User TSUpdate` autocmd below.
--- @return boolean registered
local function register_parser()
	local ok, parsers = pcall(require, "nvim-treesitter.parsers")
	if not ok then
		return false
	end
	parsers[LANGUAGE] = vim.deepcopy(PARSER_INFO)
	return true
end

--- Start Tree-sitter for a MyBatis buffer when the parser is available.
--- @param bufnr integer
--- @return boolean started
local function start(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= LANGUAGE then
		return false
	end

	local ok, loaded, load_error = pcall(vim.treesitter.language.add, LANGUAGE)
	if not ok or loaded == false then
		return false, load_error or loaded
	end

	local started = pcall(vim.treesitter.start, bufnr, LANGUAGE)
	return started
end

local function finish_install(err, installed)
	local buffers = pending[LANGUAGE]
	pending[LANGUAGE] = nil

	if err or installed == false then
		notify(
			"Could not install the tree-sitter-mybatis parser: " .. tostring(err or "unknown error"),
			vim.log.levels.ERROR
		)
		return
	end

	for _, bufnr in ipairs(buffers or {}) do
		if not start(bufnr) then
			notify("Could not start the tree-sitter-mybatis parser", vim.log.levels.WARN)
		end
	end
end

--- Register the parser and the autocmd used by nvim-treesitter's installer.
function M.setup()
	if setup_done then
		return
	end
	setup_done = true

	register_parser()
	vim.treesitter.language.register(LANGUAGE, { LANGUAGE })
	vim.api.nvim_create_autocmd("User", {
		pattern = "TSUpdate",
		group = vim.api.nvim_create_augroup("NvimMybatisTreeSitter", { clear = true }),
		callback = register_parser,
	})
end

--- Install the parser if needed, then start it for `bufnr`.
--- @param bufnr integer
--- @return boolean scheduled whether installation or startup was scheduled
function M.ensure(bufnr)
	M.setup()
	if start(bufnr) then
		return true
	end

	local ok, treesitter = pcall(require, "nvim-treesitter")
	if not ok or type(treesitter.install) ~= "function" then
		notify("nvim-treesitter is required to install tree-sitter-mybatis", vim.log.levels.WARN)
		return false
	end

	register_parser()
	pending[LANGUAGE] = pending[LANGUAGE] or {}
	table.insert(pending[LANGUAGE], bufnr)
	if #pending[LANGUAGE] > 1 then
		return true
	end

	local install_ok, task = pcall(treesitter.install, { LANGUAGE })
	if not install_ok then
		finish_install(task, false)
		return false
	end

	local has_await = (type(task) == "table" or type(task) == "userdata")
		and type(task.await) == "function"
	if not has_await then
		finish_install(nil, task ~= false)
		return task ~= false
	end

	task:await(function(err, installed)
		vim.schedule(function()
			finish_install(err, installed)
		end)
	end)
	return true
end

return M
