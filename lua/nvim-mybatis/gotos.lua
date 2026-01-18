local M = {}

local config = require("nvim-mybatis.config"):get()
local locate = require("nvim-mybatis.locate")

function M.goto_java(bufnr) end

function M.goto_mapper(classname)
	local file_path = classname:gsub("%.", "/") .. ".java"
	local root_file = vim.fn.findfile("pom.xml", ".;")
	if root_file == "" then
		vim.notify("No pom.xml found", vim.log.levels.ERROR)
		return
	end
	for _, classpath in ipairs(config.classpath) do
		local project_root = vim.fn.fnamemodify(root_file, ":p:h")
		local full_path = project_root .. "/" .. classpath .. "/" .. file_path

		if vim.fn.filereadable(full_path) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))
			vim.defer_fn(locate.locate_interface, 50)
			return
		end
	end
	vim.notify("Class not found", vim.log.levels.WARN)
end

function M.goto_method() end

function M.goto_xml(bufnr) end

return M
