--- @module 'mybatis.completion'
--- @class MyBatisSource: blink.cmp.Source
--- @field config table
--- @field opts table
--- @field cache table
--- @field watchers table

--- @type MyBatisSource
local source = {}

local uv = vim.uv or vim.loop
local utils = require("nvim-mybatis.utils")
local config = require("nvim-mybatis.config"):get()

function source.new(opts, src_config)
	local self = setmetatable({}, { __index = source })
	self.config = src_config or {}
	self.opts = opts or {}
	self.cache = {
		values = nil,
		timestamp = 0,
	}
	self.watchers = nil
	return self
end

function source:get_completions(ctx, callback)
	local project_root = utils.get_module_root()

	if not self.watchers then
		self.watchers = {}

		for _, classpath in ipairs(config.classpath or {}) do
			local full_path = project_root .. "/" .. classpath
			if vim.fn.isdirectory(full_path) == 1 then
				if config.refresh_strategy == "os_watch" then
					local function callback_wrapper(err, filename, events)
						if err or not events then
							return
						end
						if events.rename then
							self.cache.values = nil
						end
					end

					local watcher = uv.new_fs_event()
					if watcher then
						local success, err = pcall(function()
							watcher:start(full_path, { recursive = true, watch_entry = true }, callback_wrapper)
						end)

						if success then
							self.watchers[full_path] = watcher
						else
							watcher:close()
						end
					end
				elseif config.refresh_strategy == "manual_watch" then
					local function setup_watcher(dir_path)
						if self.watchers[dir_path] then
							return
						end

						local stat = uv.fs_stat(dir_path)
						if not stat or stat.type ~= "directory" then
							return
						end

						local dir_name = dir_path:match("([^/]+)$")
						if dir_name and (dir_name:match("^%.") or dir_name == "target" or dir_name == "build") then
							return
						end

						local watcher = uv.new_fs_event()
						if not watcher then
							return
						end

						local function callback_wrapper(err, filename, events)
							if err or not events then
								return
							end

							if events.rename then
								self.cache.values = nil
								if filename then
									local changed_path = dir_path .. "/" .. filename
									local stat = uv.fs_stat(changed_path)

									if stat and stat.type == "directory" then
										if not self.watchers[changed_path] then
											setup_watcher(changed_path)
										end
									end
								end
							elseif events.change and not events.rename then
								if filename then
									local changed_path = dir_path .. "/" .. filename
									local stat = uv.fs_stat(changed_path)
									if stat and stat.type == "file" and filename:match("%.java$") then
										return
									end
								end
								self.cache.values = nil
							end
						end

						local success, err = pcall(function()
							watcher:start(dir_path, {}, callback_wrapper)
						end)

						if success then
							self.watchers[dir_path] = watcher
						else
							watcher:close()
						end
					end

					local function setup_watchers_recursive(dir_path)
						setup_watcher(dir_path)

						local handle = uv.fs_scandir(dir_path)
						if handle then
							while true do
								local name, type = uv.fs_scandir_next(handle)
								if not name then
									break
								end

								if type == "directory" then
									local sub_path = dir_path .. "/" .. name
									setup_watchers_recursive(sub_path)
								end
							end
						end
					end

					setup_watchers_recursive(full_path)
				end
			end
		end
	end

	if config.refresh_strategy == "polling" then
		local now = uv.now()

		if
			not self.cache.values
			or not self.cache.timestamp
			or (now - self.cache.timestamp) > config.polling_interval
		then
			self.cache.values = nil
		end
	end

	if not self.cache.values then
		self.cache.values = {}
		for _, classpath in ipairs(config.classpath or {}) do
			local full_path = project_root .. "/" .. classpath
			if vim.fn.isdirectory(full_path) == 1 then
				for _, class in ipairs(utils.scan_java_classes(full_path, "")) do
					table.insert(self.cache.values, class)
				end
			end
		end

		local java_builtin_types = utils.get_java_builtin_types()
		for _, type_name in ipairs(java_builtin_types) do
			table.insert(self.cache.values, "java.lang." .. type_name)
			table.insert(self.cache.values, type_name)
		end

		self.cache.timestamp = uv.now()
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
	for _, class_name in ipairs(self.cache.values) do
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
	if not utils.is_xml_mybatis_file() then
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
