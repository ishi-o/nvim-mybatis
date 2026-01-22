--- `scan` always starts querying from the root node instead of querying upwards,
--- scanning to get all strings that meet the conditions
local M = {}

local query = require("nvim-mybatis.treesitter.query")

--- @param bufnr integer
--- @return string? pkg_name
function M.package(bufnr)
	local qry = query.package()
	for _, node in query.iter_query(bufnr, qry.lang, query.parse(qry)) do
		return vim.treesitter.get_node_text(node, bufnr)
	end
	return nil
end

--- @param bufnr integer
--- @return string? pkg_name
function M.methods(bufnr) end

return M
