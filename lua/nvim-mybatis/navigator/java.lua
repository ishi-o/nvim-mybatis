local M = {}

local ts = vim.treesitter
local treesitter = require("nvim-mybatis.treesitter")

--- from java to xml
--- @param bufnr integer
--- @return boolean
function M.navigate_from_java(bufnr)
	local interface, method = treesitter.extract.interface_method(ts.get_node(), bufnr)
	if not interface then
		return false
	end
	local package_name = treesitter.scan.package(bufnr)
	local clsname = package_name .. "." .. interface
	return method and treesitter.navigate_mapper(clsname, treesitter.query.crud_id(method))
		or treesitter.navigate_mapper(clsname, treesitter.query.namespace(clsname))
end

return M
