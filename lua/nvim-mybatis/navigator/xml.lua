local M = {}

local ts = vim.treesitter
local utils = require("nvim-mybatis.utils")
local treesitter = require("nvim-mybatis.treesitter")
local logger = require("nvim-mybatis.logger")

--- from xml to java
--- @param bufnr integer
--- @return boolean
function M.navigate_from_xml(bufnr)
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
	local crud_id = treesitter.extract.crud_id(node, bufnr)
	if crud_id then
		local current_namespace = treesitter.extract.belong_namespace(node, bufnr)
		if current_namespace then
			return M.navigate_method(current_namespace, crud_id)
		end
	end
	-- if the cursor on `refid` attribute
	local refid = treesitter.extract.refid(node, bufnr)
	if refid then
		if refid:find("%.") == nil then
			return treesitter.locate(treesitter.query.sqlid(refid))
		else
			local namespace, sql_id = refid:match("^(.*)%.([^%.]+)$")
			local files = utils.search_mapper(namespace)
			if files and #files > 0 then
				vim.cmd("edit " .. files[1])
				vim.defer_fn(function()
					treesitter.locate(treesitter.query.sqlid(sql_id))
				end, 50)
			end
		end
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
				if not treesitter.locate(treesitter.query.interface()) then
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
				if not treesitter.locate(treesitter.query.method(method)) then
					logger.warn("Method not found")
				end
			end, 50)
			return true
		end
	end)
end

return M
