--- `find` searches upward from the current TSNode and returns the matching TSNode
local M = {}

local ts = vim.treesitter
local utils = require("nvim-mybatis.utils")

--- get interface and method node
--- @return TSNode?
--- @return TSNode?
function M.find_interface_method()
	if not utils.is_mybatis_java() then
		return nil, nil
	end
	local node = ts.get_node()
	if not node then
		return nil, nil
	end
	local interface_node, method_node
	local current = node

	while current do
		local node_type = current:type()
		if not interface_node and node_type == "interface_declaration" then
			interface_node = current
		end
		if not method_node and node_type == "method_declaration" then
			method_node = current
		end
		current = current:parent()
	end

	return interface_node, method_node
end

--- find namespace node
--- @param bufnr integer bufnr to get node text
--- @return TSNode? namespace Attribute node
function M.find_namespace(bufnr)
	local current = ts.get_node()
	while current do
		if current:type() == "Attribute" then
			local name_node = current:field("Name")[1]
			if name_node then
				local name_text = ts.get_node_text(name_node, bufnr)
				if name_text == "namespace" then
					return current
				end
			end
		end
		current = current:parent()
	end

	return nil
end

return M
