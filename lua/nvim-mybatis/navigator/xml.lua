local M = {}

local ts = vim.treesitter
local utils = require("nvim-mybatis.utils")
local treesitter = require("nvim-mybatis.treesitter")
local logger = require("nvim-mybatis.logger")

--- from xml to java
--- @param bufnr integer
--- @return boolean
function M.navigate_java(bufnr)
	local node = ts.get_node()
	if not node then
		return false
	end
	-- if the cursor on `namespace` attribute
	local clsname = treesitter.extract.classname(node, bufnr)
	if clsname then
		return M.navigate_class(clsname)
	end
	-- if the cursor on sql tag and `id` attribute
	local sql_id = treesitter.extract.crud_id(node, bufnr)
	if sql_id then
		local current_namespace = treesitter.extract.belong_namespace(node, bufnr)
		if current_namespace then
			return M.navigate_method(current_namespace, sql_id)
		end
	end
	-- if the cursor on `refid` attribute
	local refid = treesitter.extract.refid(node, bufnr)
	if refid then
		return treesitter.locate.locate_sqlid(refid)
	end
	logger.info("Not a valid MyBatis jump target")
	return false
end

--- navigate class position (xml to java)
--- @param clsname string
--- @return boolean
function M.navigate_class(clsname)
	local file_path = clsname:gsub("%.", "/") .. ".java"
	return utils.foreach_classpath(function(classpath)
		if vim.fn.filereadable(classpath .. file_path) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(classpath .. file_path))
			vim.defer_fn(function()
				if not treesitter.locate.locate_interface() then
					logger.warn("Class not found")
				end
			end, 50)
			return true
		end
	end)
end

--- navigate method position (xml to java)
--- @param clsname string
--- @param method string
--- @return boolean
function M.navigate_method(clsname, method)
	local file_path = clsname:gsub("%.", "/") .. ".java"
	return utils.foreach_classpath(function(classpath)
		if vim.fn.filereadable(classpath .. file_path) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(classpath .. file_path))
			vim.defer_fn(function()
				if not treesitter.locate.locate_method(method) then
					logger.warn("Method not found")
				end
			end, 50)
			return true
		end
	end)
end

return M
