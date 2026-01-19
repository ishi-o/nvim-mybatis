--- @module 'nvim-mybatis.completion'
--- @class MyBatisSource: blink.cmp.Source
--- @field config table
--- @field opts table
--- @field cache table

--- @type MyBatisSource
local source = {}

local utils = require("nvim-mybatis.utils")
local config = require("nvim-mybatis.config"):get()

function source.new(opts, src_config)
	local self = setmetatable({}, { __index = source })
	self.config = src_config or {}
	self.opts = opts or {}
	self.cache = {
		packages = nil,
		timestamp = 0,
	}
	return self
end

function source:get_completions(ctx, callback)
	local project_root = utils.get_module_root()
	local current_time = os.time()

	if not self.cache.packages or current_time - self.cache.timestamp > 5 then
		self.cache.packages = {}

		for _, classpath in ipairs(config.classpath or {}) do
			local full_path = project_root .. "/" .. classpath
			if vim.fn.isdirectory(full_path) == 1 then
				for _, class in ipairs(utils.scan_java_classes(full_path, "")) do
					table.insert(self.cache.packages, class)
				end
			end
		end

		local java_builtin_types = utils.get_java_builtin_types()

		for _, type_name in ipairs(java_builtin_types) do
			table.insert(self.cache.packages, "java.lang." .. type_name)
			table.insert(self.cache.packages, type_name)
		end

		self.cache.timestamp = current_time
	end

	local col = vim.api.nvim_win_get_cursor(0)[2]
	local line = vim.api.nvim_get_current_line()
	local partial = ""

	for i = col, 1, -1 do
		if line:sub(i, i) == '"' and (i == 1 or line:sub(i - 1, i - 1) ~= "\\") then
			partial = line:sub(i + 1, col)
			break
		end
	end

	local items = {}
	local types = require("blink.cmp.types")
	for _, class_name in ipairs(self.cache.packages) do
		if partial == "" or class_name:find(partial, 1, true) then
			table.insert(items, {
				label = class_name,
				kind = types.CompletionItemKind.Class,
				insertText = class_name,
				filterText = class_name,
				data = { class = class_name },
			})
		end
	end

	callback({ items = items })
	return function() end
end

function source:enabled()
	if vim.bo.filetype ~= "xml" or not utils.is_mybatis_file() then
		return false
	end
	local node = vim.treesitter.get_node()
	if not node or node:type() ~= "AttValue" then
		return false
	end
	local attr = node:parent()
	if not attr or attr:type() ~= "Attribute" then
		return false
	end
	local name_node = attr:named_child(0)
	if not name_node then
		return false
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local attr_name = vim.treesitter.get_node_text(name_node, bufnr)
	return attr_name == "resultType" or attr_name == "parameterType" or attr_name == "namespace"
end

function source:get_trigger_characters()
	return { '"', "." }
end

return source
