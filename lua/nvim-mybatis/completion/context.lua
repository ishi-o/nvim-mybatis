--- Cursor context detection: figures out what is being completed at the cursor.
--- @module 'nvim-mybatis.completion.context'
local M = {}

local ts = vim.treesitter
local config = require("nvim-mybatis.config"):get()
local extract = require("nvim-mybatis.treesitter.extract")

--- walk up from `node` to the enclosing Attribute node
--- @param node TSNode
--- @return TSNode? attribute
local function attribute_at(node)
	local current = node
	while current do
		if current:type() == "Attribute" then
			return current
		end
		current = current:parent()
	end
	return nil
end

--- detect what the cursor is completing
--- @param bufnr? integer
--- @return mybatis.completion.Context? ctx nil when the cursor is not on a completion site
function M.detect(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local node = ts.get_node({ bufnr = bufnr })
	if not node then
		return nil
	end
	local attr = attribute_at(node)
	if not attr then
		return nil
	end
	local name_node = attr:named_child(0)
	if not name_node then
		return nil
	end
	local attr_name = ts.get_node_text(name_node, bufnr)

	--- @type mybatis.completion.Context
	local ctx = {
		kind = "class",
		bufnr = bufnr,
		value_node = attr:named_child(1),
	}

	if vim.tbl_contains(config.type_attributes, attr_name) then
		return ctx
	end

	if attr_name == "id" then
		-- only the `id` attribute of a crud tag completes method names
		if extract.crud_id(node, bufnr) then
			ctx.kind = "method"
			ctx.namespace = extract.belong_namespace(node, bufnr)
			return ctx.namespace and ctx or nil
		end
		return nil
	end

	if attr_name == "property" then
		local type_value = extract.property(node, bufnr)
		if type_value then
			ctx.kind = "field"
			ctx.type = type_value
			return ctx
		end
		return nil
	end

	if attr_name == "refid" then
		ctx.kind = "refid"
		return ctx
	end

	return nil
end

return M
