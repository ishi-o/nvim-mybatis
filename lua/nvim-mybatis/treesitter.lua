local M = {}

local utils = require("nvim-mybatis.utils")

function M.locate_interface()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr, "java")
	if not parser then
		return
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"java",
		[[
        (interface_declaration name: (identifier) @name)
        (class_declaration name: (identifier) @name)
    ]]
	)

	for _, node in query:iter_captures(root, bufnr, 0, -1) do
		local row, col, _, _ = node:range()
		vim.api.nvim_win_set_cursor(0, { row + 1, col })
		return
	end
end

function M.locate_method(method)
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr, "java")
	if not parser then
		return
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse("java", [[
        (method_declaration
          name: (identifier) @method_name
          (#eq? @method_name "]] .. method .. [[")
        )
    ]])

	for _, node in query:iter_captures(root, bufnr, 0, -1) do
		local row, col, _, _ = node:range()
		vim.api.nvim_win_set_cursor(0, { row + 1, col })
		return
	end
	utils.log("Method not found: " .. method)
end

function M.get_class(node, bufnr)
	local parent = node:parent()
	if not parent then
		return nil
	end

	local query = vim.treesitter.query.parse(
		"xml",
		[[
        ((Attribute
          (Name) @attr_name
          (AttValue) @attr_value)
          (#any-of? @attr_name "resultType" "parameterType" "type" "namespace"))
    ]]
	)

	for _, match in query:iter_matches(parent, bufnr, 0, -1) do
		local name_nodes = match[1] -- @attr_name
		local value_nodes = match[2] -- @attr_value

		if name_nodes and value_nodes and #value_nodes > 0 then
			for _, nodes in pairs(match) do
				for _, matched in ipairs(nodes) do
					if matched:id() == node:id() or matched:id() == parent:id() then
						return vim.treesitter.get_node_text(value_nodes[1], bufnr):gsub("['\"]", "")
					end
				end
			end
		end
	end
	return nil
end

function M.get_sql_id(node, bufnr)
	local parent = node:parent()
	if not parent then
		return nil
	end

	local query = vim.treesitter.query.parse(
		"xml",
		[[
        ((Attribute
          (Name) @attr_name
          (AttValue) @attr_value)
          (#eq? @attr_name "id"))
    ]]
	)

	for _, match_node, metadata in query:iter_matches(parent, bufnr, 0, -1) do
		if match_node == node or match_node == parent then
			local value_node = metadata[2]
			if value_node then
				return vim.treesitter.get_node_text(value_node, bufnr):gsub("['\"]", "")
			end
		end
	end
	return nil
end

function M.get_belongto_namespace(node, bufnr)
	local query = vim.treesitter.query.parse(
		"xml",
		[[
        ((element
          (STag
            (Name) @_tag
            (Attribute
              (Name) @attr_name
              (AttValue) @attr_value)))
          (#eq? @_tag "mapper")
          (#eq? @attr_name "namespace"))
    ]]
	)

	local parser = vim.treesitter.get_parser(bufnr, "xml")
	if not parser then
		return nil
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	for _, match_node, metadata in query:iter_matches(root, bufnr, 0, -1) do
		local value_node = metadata[2] -- @attr_value节点
		if value_node then
			return vim.treesitter.get_node_text(value_node, bufnr):gsub("['\"]", "")
		end
	end
	return nil
end

return M
