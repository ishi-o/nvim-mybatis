--- MyBatis parser registration and on-demand installation.

local M = {}

local constants = require("nvim-mybatis.constants")
local LANGUAGE = constants.MYBATIS_LANGUAGE
local FILETYPE = constants.MYBATIS_FILETYPE
local PARSER_INFO = {
	install_info = {
		url = "https://github.com/ishi-o/tree-sitter-mybatis",
		revision = "94bc45e819c83b17f3f61dfec783a57f46e865a2",
		queries = "queries/mybatis",
	},
}

local setup_done = false
local install_task
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
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end
	local filetype = vim.bo[bufnr].filetype
	if filetype ~= FILETYPE and filetype ~= LANGUAGE then
		return false
	end

	local ok, loaded, load_error = pcall(vim.treesitter.language.add, LANGUAGE)
	if not ok or loaded ~= true then
		return false, load_error or loaded
	end

	return pcall(vim.treesitter.start, bufnr, LANGUAGE)
end

local function finish_install(err, installed)
	local buffers = pending
	pending = {}
	if err or installed == false then
		if next(buffers) ~= nil then
			notify(
				"Could not install the tree-sitter-mybatis parser: "
					.. tostring(err or "unknown error"),
				vim.log.levels.ERROR
			)
		end
		return
	end

	for bufnr in pairs(buffers) do
		if not start(bufnr) then
			notify("Could not start the tree-sitter-mybatis parser", vim.log.levels.WARN)
		end
	end
end

local function install_parsers()
	local ok, treesitter = pcall(require, "nvim-treesitter")
	if not ok or type(treesitter.install) ~= "function" then
		notify("nvim-treesitter is required to install Tree-sitter parsers", vim.log.levels.WARN)
		return
	end

	local install_ok, task = pcall(treesitter.install, { "java", "xml", LANGUAGE })
	if not install_ok then
		notify("Could not install Tree-sitter parsers: " .. tostring(task), vim.log.levels.ERROR)
		return
	end
	install_task = task
end

--- Register the parser and the autocmd used by nvim-treesitter's installer.
function M.setup()
	if not setup_done then
		setup_done = true
		register_parser()
		vim.treesitter.language.register(LANGUAGE, { LANGUAGE, FILETYPE })
		vim.api.nvim_create_autocmd("User", {
			pattern = "TSUpdate",
			group = vim.api.nvim_create_augroup("NvimMybatisTreeSitter", { clear = true }),
			callback = function()
				register_parser()
			end,
		})
	end
	if not install_task then
		install_parsers()
	end
end

--- Install the parser if needed, then start it for `bufnr`.
--- @param bufnr integer
--- @return boolean scheduled whether installation or startup was scheduled
function M.ensure(bufnr)
	M.setup()
	if start(bufnr) then
		return true
	end
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end

	pending[bufnr] = true
	if not install_task then
		install_parsers()
	end
	if not install_task then
		pending[bufnr] = nil
		return false
	end
	if type(install_task) == "table" and type(install_task.await) == "function" then
		install_task:await(function(err, installed)
			vim.schedule(function()
				finish_install(err, installed)
			end)
		end)
		return true
	end
	finish_install(nil, install_task ~= false)
	return install_task ~= false
end

return M
