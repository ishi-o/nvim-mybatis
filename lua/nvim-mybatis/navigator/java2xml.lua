local M = {}

local ts = vim.treesitter
local config = require("nvim-mybatis.config"):get()
local treesitter = require("nvim-mybatis.treesitter")
local utils = require("nvim-mybatis.utils")
local logger = require("nvim-mybatis.logger")

--- from java to xml
--- @param bufnr integer
--- @return boolean
function M.navigate_xml(bufnr)
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
	return method_name and M.navigate_sqlid(clsname, method_name) or M.navigate_namespace(clsname)
end

--- navigate namespace (java to xml)
--- @param clsname string
--- @return boolean
function M.navigate_namespace(clsname)
	local project_root = utils.get_module_root()
	local xml_files = {}
	for _, xml_glob in ipairs(config.xml_search_pattern) do
		local search_path = project_root .. "/" .. xml_glob
		local files = vim.fn.glob(search_path, true, true)
		vim.list_extend(xml_files, files)
	end
	if #xml_files == 0 then
		logger.warn("No XML files found for mapper: " .. clsname)
		return false
	end

	local namespace_pattern = string.format("'namespace=\"%s\"'", clsname)
	local candidate_files = {}
	local cmd = { "rg", "-l", "--color=never", "--fixed-strings", namespace_pattern }
	for _, file in ipairs(xml_files) do
		table.insert(cmd, file)
	end
	local handle = io.popen(table.concat(cmd, " "))
	if handle then
		for line in handle:lines() do
			table.insert(candidate_files, line)
		end
		handle:close()
	end
	if #candidate_files == 0 then
		logger.warn(string.format("No mapper found for namespace: '%s'", clsname))
		return false
	end
	local target_file = candidate_files[1]
	local bufnr = vim.fn.bufadd(target_file)
	vim.cmd("edit " .. vim.fn.fnameescape(target_file))
	vim.fn.bufload(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, "xml")
	local tree = parser:parse()[1]
	local root = tree:root()

	local query_string = string.format(
		[[
    (STag
        (Name) @tag_name (#eq? @tag_name "mapper")
        (Attribute
            (Name) @attr_name (#eq? @attr_name "namespace")
            (AttValue) @attr_value (#eq? @attr_value "\"%s\"")
        ) @namespace_attr
    ) @mapper_tag
]],
		clsname
	)
	local query = vim.treesitter.query.parse("xml", query_string)

	for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
		local capture_name = query.captures[id]
		if capture_name == "attr_value" then
			local row, col = node:range()
			vim.api.nvim_win_set_cursor(0, { row + 1, col })
			return true
		end
	end

	vim.api.nvim_buf_delete(bufnr, { force = true })
	logger.warn(string.format("Class '%s' not found", clsname))
	return false
end

--- navigate sql id (java to xml)
--- @param clsname string
--- @param method string
--- @return boolean
function M.navigate_sqlid(clsname, method)
	local project_root = utils.get_module_root()
	local xml_files = {}
	for _, xml_glob in ipairs(config.xml_search_pattern) do
		local search_path = project_root .. "/" .. xml_glob
		local files = vim.fn.glob(search_path, true, true)
		vim.list_extend(xml_files, files)
	end
	if #xml_files == 0 then
		logger.warn("No XML files found for mapper: " .. clsname)
		return false
	end

	local namespace_pattern = string.format("'namespace=\"%s\"'", clsname)
	local candidate_files = {}
	local cmd = { "rg", "-l", "--color=never", "--fixed-strings", namespace_pattern }
	for _, file in ipairs(xml_files) do
		table.insert(cmd, file)
	end
	local handle = io.popen(table.concat(cmd, " "))
	if handle then
		for line in handle:lines() do
			table.insert(candidate_files, line)
		end
		handle:close()
	end
	if #candidate_files == 0 then
		logger.warn(string.format("No mapper found for namespace: '%s'", clsname))
		return false
	end
	local target_file = candidate_files[1]
	local bufnr = vim.fn.bufadd(target_file)
	vim.cmd("edit " .. vim.fn.fnameescape(target_file))
	vim.fn.bufload(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, "xml")
	local tree = parser:parse()[1]
	local root = tree:root()

	local query_string = string.format(
		[[
        (Attribute
            (Name) @attr_name (#eq? @attr_name "id")
            (AttValue) @attr_value (#eq? @attr_value "\"%s\"")
        )
    ]],
		method
	)

	local query = vim.treesitter.query.parse("xml", query_string)

	for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
		local capture_name = query.captures[id]
		if capture_name == "attr_value" then
			local row, col = node:range()
			vim.api.nvim_win_set_cursor(0, { row + 1, col })
			return true
		end
	end

	vim.api.nvim_buf_delete(bufnr, { force = true })
	logger.warn(string.format("Method '%s' not found in mapper '%s'", method, clsname))
	return false
end

return M
