--- `scan` always starts querying from the root node instead of querying upwards,
--- scanning to get all strings that meet the conditions
local M = {}

local ts = vim.treesitter
local query = require("nvim-mybatis.treesitter.query")

--- @param bufnr integer
--- @return string? pkg_name
function M.package(bufnr)
	local qry = query.package()
	for _, node in query.iter_query(bufnr, qry.lang, query.parse(qry)) do
		return ts.get_node_text(node, bufnr)
	end
	return nil
end

--- collect all method names declared in a java buffer
--- @param bufnr integer
--- @return string[] method names
function M.methods(bufnr)
	local names = {}
	local qry = query.methods()
	for _, node in query.iter_query(bufnr, qry.lang, query.parse(qry)) do
		table.insert(names, ts.get_node_text(node, bufnr))
	end
	return names
end

--- collect all field names declared in a java buffer
--- @param bufnr integer
--- @return string[] field names
function M.fields(bufnr)
	local names = {}
	local qry = query.fields()
	for _, node in query.iter_query(bufnr, qry.lang, query.parse(qry)) do
		table.insert(names, ts.get_node_text(node, bufnr))
	end
	return names
end

return M
