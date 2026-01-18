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

function M.get_belongto_namespace(node, bufnr)
	local current = node
	while current do
		if current:type() == "element" then
			local start_tag = current:child(0)
			if start_tag then
				for i = 0, start_tag:child_count() - 1 do
					local child = start_tag:child(i)
					if child and child:type() == "Name" then
						local tag_name = vim.treesitter.get_node_text(child, bufnr)
						if tag_name == "mapper" then
							for j = 0, start_tag:child_count() - 1 do
								local attr_child = start_tag:child(j)
								if attr_child and attr_child:type() == "Attribute" then
									local name_node, value_node
									for k = 0, attr_child:child_count() - 1 do
										local sub_child = attr_child:child(k)
										if sub_child then
											local sub_type = sub_child:type()
											if sub_type == "Name" then
												name_node = sub_child
											elseif sub_type == "AttValue" then
												value_node = sub_child
											end
										end
									end

									if name_node and value_node then
										local attr_name = vim.treesitter.get_node_text(name_node, bufnr)
										if attr_name == "namespace" then
											return vim.treesitter.get_node_text(value_node, bufnr):gsub("['\"]", "")
										end
									end
								end
							end
							return nil
						end
					end
				end
			end
		end
		current = current:parent()
	end
	return nil
end

return M
