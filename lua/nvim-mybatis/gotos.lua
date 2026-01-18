local M = {}

local config = require("nvim-mybatis.config"):get()
local ts = require("nvim-mybatis.treesitter")
local utils = require("nvim-mybatis.utils")

function M.goto_java(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local parser = vim.treesitter.get_parser(bufnr, "xml")
	if not parser then
		return nil
	end

	local tree = parser:parse()[1]
	local root = tree:root()
	local node = root:named_descendant_for_range(row, col, row, col)
	if not node then
		return nil
	end

	local clsname = ts.get_class(node, bufnr)
	if clsname then
		return M.goto_class(clsname)
	end

	local sql_id = ts.get_sql_id(node, bufnr)
	if sql_id then
		local current_namespace = ts.get_belongto_namespace(node, bufnr)
		if current_namespace then
			return M.goto_method(current_namespace, sql_id)
		end
	end

	utils.log("Not a valid MyBatis jump target")
	return nil
end

function M.goto_class(clsname)
	local file_path = clsname:gsub("%.", "/") .. ".java"
	local root_file = vim.fn.findfile("pom.xml", ".;")
	if root_file == "" then
		utils.log("No pom.xml found", vim.log.levels.ERROR)
		return nil
	end
	for _, classpath in ipairs(config.classpath) do
		local project_root = vim.fn.fnamemodify(root_file, ":p:h")
		local full_path = project_root .. "/" .. classpath .. "/" .. file_path

		if vim.fn.filereadable(full_path) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))
			vim.defer_fn(ts.locate_interface, 50)
			return true
		end
	end
	utils.log("Class not found", vim.log.levels.WARN)
	return nil
end

function M.goto_method(clsname, method)
	local file_path = clsname:gsub("%.", "/") .. ".java"
	local root_file = vim.fn.findfile("pom.xml", ".;")
	if root_file == "" then
		utils.log("No pom.xml found", vim.log.levels.ERROR)
		return nil
	end
	for _, classpath in ipairs(config.classpath) do
		local project_root = vim.fn.fnamemodify(root_file, ":p:h")
		local full_path = project_root .. "/" .. classpath .. "/" .. file_path

		if vim.fn.filereadable(full_path) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))
			vim.defer_fn(function()
				ts.locate_method(method)
			end, 50)
			return true
		end
	end
	utils.log("Class not found", vim.log.levels.WARN)
	return nil
end

function M.goto_xml(bufnr) end

return M
