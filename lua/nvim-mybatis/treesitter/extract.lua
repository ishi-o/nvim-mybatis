--- `extract` starts from the given TSNode and searches upward, returning the corresponding string if conditions are met
local M = {}

local ts = vim.treesitter
local constants = require("nvim-mybatis.constants")
local logger = require("nvim-mybatis.logger")
local TYPE_ATTRIBUTES = constants.TYPE_ATTRIBUTES
local CRUD_TAGS = constants.CRUD_TAGS

local function attribute_value(attribute, bufnr, name)
	if not attribute then
		return nil
	end
	local name_node = attribute:named_child(0)
	if not name_node or ts.get_node_text(name_node, bufnr) ~= name then
		return nil
	end
	local value_node = attribute:named_child(1)
	return value_node and ts.get_node_text(value_node, bufnr):gsub("['\"]", "") or nil
end

local function find_attribute(tag, bufnr, name)
	if not tag then
		return nil
	end
	for i = 0, tag:named_child_count() - 1 do
		local child = tag:named_child(i)
		if child and child:type() == "Attribute" and attribute_value(child, bufnr, name) then
			return child
		end
	end
	return nil
end

local function find_tag(node, bufnr)
	local current = node
	while current do
		if current:type() ~= "Attribute" then
			local name_node = current:named_child(0)
			if name_node and name_node:type() == "Name" then
				return current, ts.get_node_text(name_node, bufnr)
			end
		end
		current = current:parent()
	end
	return nil, nil
end

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
				if vim.tbl_contains(TYPE_ATTRIBUTES, name_text) then
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
function M.crud_id(node, bufnr)
	local current = node
	while current and current:type() ~= "Attribute" do
		current = current:parent()
	end
	if not current then
		return nil
	end
	local id_value = attribute_value(current, bufnr, "id")
	if not id_value then
		return nil
	end
	local _, tag = find_tag(current, bufnr)
	if not tag then
		return nil
	end
	if vim.tbl_contains(CRUD_TAGS, tag) then
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
		if current:type() == "Mapper" or current:type() == "SqlMap" then
			local start_tag = current:named_child(0)
			local namespace = start_tag and find_attribute(start_tag, bufnr, "namespace")
			if namespace then
				return attribute_value(namespace, bufnr, "namespace")
			end
			return nil
		end

		local tag_node, tag_name = find_tag(current, bufnr)
		if tag_name == "mapper" or tag_name == "sqlMap" then
			return attribute_value(find_attribute(tag_node, bufnr, "namespace"), bufnr, "namespace")
		end
		current = current:parent()
	end

	return nil
end

--- @param node TSNode
--- @param bufnr integer
--- @return string?
function M.refid(node, bufnr)
	local current = node

	while current do
		if current:type() == "Attribute" then
			local name_node = current:named_child(0)
			if name_node then
				local name_text = ts.get_node_text(name_node, bufnr)
				if name_text == "refid" then
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

--- @param node TSNode
--- @param bufnr integer
--- @return string?
function M.resultType(node, bufnr)
	local method_node = node
	while method_node and method_node:type() ~= "method_declaration" do
		method_node = method_node:parent()
	end
	if not method_node then
		return nil
	end
	local type_node = method_node:field("type")[1]
	if not type_node then
		return nil
	end

	local function parse_type(type_node)
		local node_type = type_node:type()
		if node_type == "type_identifier" then
			return ts.get_node_text(type_node, bufnr)
		elseif node_type == "generic_type" then
			-- type_identifier
			local container_node = type_node:named_child(0)
			if not container_node then
				return nil
			end
			local container_name = ts.get_node_text(container_node, bufnr)
			-- type_arguments
			local type_args_node = type_node:named_child(1)
			if not type_args_node then
				return container_name
			end
			-- List or Set
			if container_name == "List" or container_name == "Set" then
				local first_arg = type_args_node:named_child(0)
				return first_arg and parse_type(first_arg) or nil
			-- Map
			elseif container_name == "Map" then
				local value_arg = type_args_node:named_child(1)
				return value_arg and parse_type(value_arg) or nil
			-- other customize generic type
			else
				return container_name
			end
		end

		return nil
	end
	return parse_type(type_node)
end

--- @param node TSNode
--- @param bufnr integer
--- @return string? namespace
--- @return string? property
function M.property(node, bufnr)
	local current = node
	local property_value = nil

	while current do
		if current:type() == "Attribute" then
			local name_node = current:named_child(0)
			if name_node then
				local name_text = ts.get_node_text(name_node, bufnr)
				if name_text == "property" then
					local value_node = current:named_child(1)
					if value_node then
						property_value = ts.get_node_text(value_node, bufnr):gsub("['\"]", "")
						break
					end
				end
			end
		end
		current = current:parent()
	end

	if not property_value then
		return nil, nil
	end

	current = current or node

	while current do
		if current:type() == "element" then
			for child in current:iter_children() do
				if child:type() == "STag" then
					local tag_name_node = child:named_child(0)
					if tag_name_node then
						local tag_name = ts.get_node_text(tag_name_node, bufnr)
						if tag_name == "resultMap" then
							for attr in child:iter_children() do
								if attr:type() == "Attribute" then
									local attr_name_node = attr:named_child(0)
									if attr_name_node then
										local attr_name = ts.get_node_text(attr_name_node, bufnr)
										if attr_name == "type" then
											local attr_value_node = attr:named_child(1)
											if attr_value_node then
												local type_value =
													ts.get_node_text(attr_value_node, bufnr)
														:gsub("['\"]", "")
												return type_value, property_value
											end
										end
									end
								end
							end
							return nil, nil
						end
					end
				end
			end
		end
		current = current:parent()
	end

	return nil, nil
end

--- @param node TSNode
--- @param bufnr integer
--- @return string? interface
--- @return string? method
function M.interface_method(node, bufnr)
	local interface, method
	local current = node

	while current do
		local node_type = current:type()
		if not interface and node_type == "interface_declaration" then
			interface = ts.get_node_text(current:field("name")[1], bufnr)
		end
		if not method and node_type == "method_declaration" then
			method = ts.get_node_text(current:field("name")[1], bufnr)
		end
		if interface and method then
			return interface, method
		end
		current = current:parent()
	end

	return interface, method
end

return M
