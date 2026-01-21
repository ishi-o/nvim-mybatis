local M = {}

local ts = vim.treesitter
local treesitter = require("nvim-mybatis.treesitter")
local utils = require("nvim-mybatis.utils")
local logger = require("nvim-mybatis.logger")

--- from java to xml
--- @param bufnr integer
--- @return boolean
function M.navigate_from_java(bufnr)
	local interface_name, method_name
	local interface, method = treesitter.find.find_interface_method()
	if interface then
		interface_name = ts.get_node_text(interface:field("name")[1], bufnr)
		if method then
			method_name = ts.get_node_text(method:field("name")[1], bufnr)
		end
	else
		return false
	end
	local package_name = treesitter.scan.package(bufnr)
	local clsname = package_name .. "." .. interface_name
	return method_name and M.navigate_crud(clsname, method_name) or M.navigate_namespace(clsname)
end

--- navigate namespace (java to xml)
--- @param namespace string
--- @return boolean
function M.navigate_namespace(namespace)
	local candidate_files = utils.search_mapper(namespace)
	if not candidate_files or #candidate_files == 0 then
		logger.warn(string.format("No mapper found for namespace: '%s'", namespace))
		return false
	end
	local target_file = candidate_files[1]
	vim.cmd("edit " .. vim.fn.fnameescape(target_file))
	vim.defer_fn(function()
		treesitter.locate(treesitter.query.namespace(namespace))
	end, 50)
	logger.warn(string.format("Class '%s' not found", namespace))
	return false
end

--- navigate sql id (java to xml)
--- @param clsname string
--- @param method string
--- @return boolean
function M.navigate_crud(clsname, method)
	local candidate_files = utils.search_mapper(clsname)
	if not candidate_files or #candidate_files == 0 then
		logger.warn(string.format("No mapper found for namespace: '%s'", clsname))
		return false
	end
	local target_file = candidate_files[1]
	vim.cmd("edit " .. vim.fn.fnameescape(target_file))
	vim.defer_fn(function()
		treesitter.locate(treesitter.query.crud_id(method))
	end, 50)
	logger.warn(string.format("Method '%s' not found in mapper '%s'", method, clsname))
	return false
end

return M
