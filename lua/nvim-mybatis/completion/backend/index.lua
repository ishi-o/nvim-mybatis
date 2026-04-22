--- @type mybatis.completion.Backend
local M = {}

local class_index_cache = nil
local utils = require("nvim-mybatis.utils")
local config = require("nvim-mybatis.config"):get()

M.name = "index"

function M.get_completion_items(partial, ctx)
	--- @type blink.cmp.CompletionItem[]
	local items = {}

	local data_dir = vim.fn.stdpath("cache") .. "/nvim-mybatis"
	if vim.fn.isdirectory(data_dir) == 0 then
		vim.fn.mkdir(data_dir, "p")
	end
	local cache_path = data_dir .. "/class-index-" .. vim.fn.sha256(utils.get_module_root()):sub(1, 16) .. ".mpack"

	if not class_index_cache then
		local file = io.open(cache_path, "rb")
		if file then
			local content = file:read("*all")
			file:close()
			class_index_cache = vim.mpack.decode(content)
		end
	end

	if not class_index_cache then
		class_index_cache = {}
		utils.foreach_classpath(function(classpath)
			if vim.fn.isdirectory(classpath) == 1 then
				for _, full_name in ipairs(utils.scan_java_classes(classpath, "")) do
					local simple_name = full_name:match("%.([^%.]+)$") or full_name
					if not class_index_cache[simple_name] then
						class_index_cache[simple_name] = {}
					end
					table.insert(class_index_cache[simple_name], full_name)
				end
			end
		end, config.classpaths.java)
		local packed = vim.mpack.encode(class_index_cache)
		local file = io.open(cache_path, "wb")
		if file then
			file:write(packed)
			file:close()
		end
	end

	for simple_name, full_names in pairs(class_index_cache) do
		if simple_name:find(partial, 1, true) then
			for _, full_name in ipairs(full_names) do
				table.insert(items, {
					label = simple_name,
					--- @type lsp.CompletionItemKind
					kind = 7,
					insertText = full_name,
					filterText = simple_name,
					data = { class = full_name },
				})
			end
		end
	end
	return items
end

function M.refresh() end

function M.is_available()
	return true
end

function M.on_change() end

return M
