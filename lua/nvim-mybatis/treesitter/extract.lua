--- `extract` starts from the given TSNode and searches upward, returning the corresponding string if conditions are met
local M = {}

local ts = vim.treesitter
local logger = require("nvim-mybatis.logger")

local TYPE_ATTRS = {
	["namespace"] = true,
	["resultType"] = true,
	["parameterType"] = true,
	["type"] = true,
	["javaType"] = true,
	["ofType"] = true,
}

local CRUD_TAGS = {
	["select"] = true,
	["update"] = true,
	["delete"] = true,
	["insert"] = true,
	["sql"] = true,
}

--- extract class name
--- @param node TSNode
--- @param bufnr integer
--- @return string? namespace
function M.classname(node, bufnr)
	local current = node
	while current do
		if current:type() == "Attribute" then
			local name_node = current:named_child(0)
			if name_node then
				local name_text = ts.get_node_text(name_node, bufnr)
				if TYPE_ATTRS[name_text] then
					local value_node = current:named_child(1)
					if value_node then
						local text = ts.get_node_text(value_node, bufnr):gsub("['\"]", "")
						return text
					end
				end
			end
		end
		current = current:parent()
	end
	return nil
end

--- get sql id name
--- @param node TSNode
--- @param bufnr integer
--- @return string? method
function M.sqlid(node, bufnr)
	local current = node
	while current and current:type() ~= "Attribute" do
		current = current:parent()
	end
	if not current then
		return nil
	end
	local name = current:named_child(0)
	if not name or vim.treesitter.get_node_text(name, bufnr) ~= "id" then
		return nil
	end
	local value = current:named_child(1)
	if not value then
		return nil
	end
	local id_value = vim.treesitter.get_node_text(value, bufnr):gsub("['\"]", "")
	local stag = current
	while stag and stag:type() ~= "STag" do
		stag = stag:parent()
	end
	if not stag then
		return nil
	end
	local tag_name = stag:named_child(0)
	if not tag_name then
		return nil
	end
	local tag = vim.treesitter.get_node_text(tag_name, bufnr)
	if CRUD_TAGS[tag] then
		return id_value
	end
	return nil
end

--- get the ancestor namespace name of node
--- @param node TSNode
--- @param bufnr integer
--- @return string?
function M.belong_namespace(node, bufnr)
	local current = node
	while current do
		if current:type() == "element" then
			local start_tag = current:named_child(0)
			if start_tag then
				local name_node = start_tag:named_child(0)
				if name_node and vim.treesitter.get_node_text(name_node, bufnr) == "mapper" then
					--- @type TSNode[]
					local attrs = {}
					for i = 0, start_tag:named_child_count() - 1 do
						local child = start_tag:named_child(i)
						if child:type() == "Attribute" then
							table.insert(attrs, child)
						end
					end
					for _, attr in ipairs(attrs or {}) do
						local attr_name_node = attr:named_child(0)
						if attr_name_node and vim.treesitter.get_node_text(attr_name_node, bufnr) == "namespace" then
							local value_node = attr:named_child(1)
							if value_node then
								local text = vim.treesitter.get_node_text(value_node, bufnr):gsub("['\"]", "")
								return text
							end
						end
					end
					return nil
				end
			end
		end
		current = current:parent()
	end

	return nil
end

return M
