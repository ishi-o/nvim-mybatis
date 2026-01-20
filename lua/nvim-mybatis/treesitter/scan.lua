--- `scan` always starts querying from the root node instead of querying upwards,
--- scanning to get all strings that meet the conditions
local M = {}

local query = require("nvim-mybatis.treesitter.query")

--- @return string? pkg_name
function M.package(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, "java")
	if not parser then
		return nil
	end
	local package_name
	local root = parser:parse()[1]:root()
	local query = vim.treesitter.query.parse(
		"java",
		[[
			(package_declaration
				(scoped_identifier) @pkg)
	]]
	)
	for _, match in query:iter_matches(root, bufnr, 0, -1) do
		if match[1] and #match[1] > 0 then
			package_name = vim.treesitter.get_node_text(match[1][1], bufnr)
			break
		end
	end
	return package_name
end

return M
