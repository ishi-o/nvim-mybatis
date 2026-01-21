local M = {}

local ts = vim.treesitter
local utils = require("nvim-mybatis.utils")
local treesitter = require("nvim-mybatis.treesitter")
local logger = require("nvim-mybatis.logger")

--- from xml to java
--- @param bufnr integer
--- @return boolean
function M.navigate_from_xml(bufnr)
	local node = ts.get_node()
	if not node then
		return false
	end
	-- if the cursor on `namespace` attribute
	local clsname = treesitter.extract.classname(node, bufnr)
	if clsname then
		return treesitter.navigate(clsname:gsub("%.", "/") .. ".java", treesitter.query.interface())
	end
	-- if the cursor on sql tag and `id` attribute
	local crud_id = treesitter.extract.crud_id(node, bufnr)
	if crud_id then
		local current_namespace = treesitter.extract.belong_namespace(node, bufnr)
		if current_namespace then
			return treesitter.navigate(current_namespace:gsub("%.", "/") .. ".java", treesitter.query.method(crud_id))
		end
	end
	-- if the cursor on `refid` attribute
	local refid = treesitter.extract.refid(node, bufnr)
	if refid then
		if refid:find("%.") == nil then
			return treesitter.locate(treesitter.query.sqlid(refid))
		else
			local namespace, sql_id = refid:match("^(.*)%.([^%.]+)$")
			return treesitter.navigate_mapper(namespace, treesitter.query.sqlid(sql_id))
		end
	end
	-- if the cursor on `extends` attribute
	local resultMap = treesitter.extract.resultMap(node, bufnr)
	if resultMap then
		if resultMap:find("%.") == nil then
			return treesitter.locate(treesitter.query.resultMap(resultMap))
		else
			local namespace, resMap = resultMap:match("^(.*)%.([^%.]+)$")
			return treesitter.navigate_mapper(namespace, treesitter.query.resultMap(resMap))
		end
	end
	-- if the cursor on `property` attribute
	local clsname, property = treesitter.extract.property(node, bufnr)
	if clsname and property then
		return treesitter.navigate(clsname:gsub("%.", "/") .. ".java", treesitter.query.field(property))
	end
	return false
end

return M
