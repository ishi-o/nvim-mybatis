local M = {}

local config = require("nvim-mybatis.config"):get()
local ts = require("nvim-mybatis.treesitter")
local utils = require("nvim-mybatis.utils")

--- from xml to java
--- @param bufnr integer
--- @return boolean?
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

--- goto class position (xml to java)
--- @param clsname string
--- @return boolean?
function M.goto_class(clsname)
	local file_path = clsname:gsub("%.", "/") .. ".java"
	local project_root = utils.get_module_root()
	for _, classpath in ipairs(config.classpath) do
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

--- goto method position (xml to java)
--- @param clsname string
--- @param method string
--- @return boolean?
function M.goto_method(clsname, method)
	local file_path = clsname:gsub("%.", "/") .. ".java"
	local project_root = utils.get_module_root()
	for _, classpath in ipairs(config.classpath) do
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

--- from java to xml
--- @param bufnr integer
--- @return boolean?
function M.goto_xml(bufnr)
	local interface_name, method_name
	local interface, method = ts.get_interface_method_node()
	if interface then
		interface_name = vim.treesitter.get_node_text(interface, bufnr)
		if method then
			method_name = vim.treesitter.get_node_text(method, bufnr)
		end
	else
		return nil
	end

	local package_name = utils.get_pkgname(bufnr)
	local clsname = package_name .. "." .. interface_name
	return method_name and M.goto_sql_id(clsname, method_name) or M.goto_namespace(clsname)
end

--- goto namespace (java to xml)
--- @param clsname string
--- @return boolean?
function M.goto_namespace(clsname)
	local project_root = utils.get_module_root()

	for _, xml_glob in ipairs(config.xml_search_pattern) do
		local search_path = project_root .. "/" .. xml_glob
		local xml_files = vim.fn.glob(search_path, true, true)

		for _, xml_file in ipairs(xml_files) do
			local namespace_node = ts.try_get_namespace(xml_file, clsname)
			if namespace_node then
				vim.cmd("edit " .. vim.fn.fnameescape(xml_file))
				ts.locate(namespace_node)
				return true
			end
		end
	end

	utils.log("No XML file found for mapper: " .. clsname)
	return nil
end

--- goto sql id (java to xml)
--- @param clsname string
--- @param method string
--- @return boolean?
function M.goto_sql_id(clsname, method)
	local project_root = utils.get_module_root()

	for _, xml_glob in ipairs(config.xml_search_pattern) do
		local search_path = project_root .. "/" .. xml_glob
		local xml_files = vim.fn.glob(search_path, true, true)

		for _, xml_file in ipairs(xml_files) do
			local namespace_node = ts.try_get_namespace(xml_file, clsname)
			if namespace_node then
				local sql_node = ts.try_get_sql_id(xml_file, method)
				vim.cmd("edit " .. vim.fn.fnameescape(xml_file))
				if sql_node then
					ts.locate(sql_node)
					return true
				else
					ts.locate(namespace_node)
				end
			end
		end
	end

	utils.log("No SQL found for method: " .. method .. " in mapper: " .. clsname)
	return nil
end

return M
