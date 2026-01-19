--- @module 'nvim-mybatis.completion'
--- @class MyBatisSource: blink.cmp.Source
--- @field config table
--- @field opts table
--- @field cache table

--- @type MyBatisSource
local source = {}
local uv = vim.loop or vim.uv

local utils = require("nvim-mybatis.utils")
local config = require("nvim-mybatis.config"):get()

function source.new(opts, config)
	local self = setmetatable({}, { __index = source })
	self.config = config or {}
	self.opts = opts or {}
	self.cache = {
		packages = nil,
		timestamp = 0,
	}
	return self
end

function source:get_completions(ctx, callback)
	local root_file = vim.fn.findfile("pom.xml", ".;")
	local project_root = vim.fn.fnamemodify(root_file, ":p:h")
	local current_time = os.time()

	if not self.cache.packages or current_time - self.cache.timestamp > 5 then
		self.cache.packages = {}

		local function scan_dir(dir_path, current_pkg)
			local handle = uv.fs_scandir(dir_path)
			if not handle then
				return
			end

			while true do
				local name, type = uv.fs_scandir_next(handle)
				if not name then
					break
				end

				if type == "file" and name:match("%.java$") then
					local class_name = name:gsub("%.java$", "")
					local full_class = current_pkg == "" and class_name or current_pkg .. "." .. class_name
					table.insert(self.cache.packages, full_class)
				elseif type == "directory" and not name:match("^%.") and name ~= "target" and name ~= "build" then
					local new_pkg = current_pkg == "" and name or current_pkg .. "." .. name
					scan_dir(dir_path .. "/" .. name, new_pkg)
				end
			end
		end

		for _, classpath in ipairs(config.classpath or {}) do
			local full_path = project_root .. "/" .. classpath
			if vim.fn.isdirectory(full_path) == 1 then
				scan_dir(full_path, "")
			end
		end

		local java_builtin_types = {
			"String",
			"Integer",
			"Long",
			"Double",
			"Float",
			"Boolean",
			"Short",
			"Byte",
			"Character",
			"Object",
			"Void",
			"Class",
			"List",
			"Map",
			"Set",
			"Collection",
			"ArrayList",
			"HashMap",
			"HashSet",
		}

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
	for _, class_name in ipairs(self.cache.packages) do
		if partial == "" or class_name:find(partial, 1, true) then
			table.insert(items, {
				label = class_name,
				kind = require("blink.cmp.types").CompletionItemKind.Class,
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
	if vim.bo.filetype ~= "xml" then
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
