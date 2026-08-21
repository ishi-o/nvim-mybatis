--- @module 'nvim-mybatis.completion.backend.index'
--- Filesystem class index: scans the configured java classpaths and caches the
--- result (mpack) next to a signature of the scanned directory tree so edits
--- and additions invalidate the cache.
--- @type mybatis.completion.IndexBackend
local M = {}

local uv = vim.uv or vim.loop
local utils = require("nvim-mybatis.utils")
local logger = require("nvim-mybatis.logger")
local config = require("nvim-mybatis.config"):get()

local cache_dir = nil
local class_index_cache = nil
local cache_signature = nil
local force_rebuild = false

--- Override the directory the cache file lives in (used by tests)
--- @param dir string
function M.set_cache_dir(dir)
	cache_dir = dir
	class_index_cache = nil
	cache_signature = nil
	force_rebuild = true
end

--- @return string
local function cache_file()
	local dir = cache_dir or (vim.fn.stdpath("cache") .. "/nvim-mybatis")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
	local root = utils.get_project_root() or utils.get_module_root() or "no-root"
	return dir .. "/class-index-" .. vim.fn.sha256(root):sub(1, 16) .. ".mpack"
end

--- recursively collect `name:mtime` of every scanned package directory.
--- cheap (scandir + stat per directory, no file reads) but catches files
--- added/removed anywhere in the tree.
--- @param dir string
--- @param parts string[]
local function signature_walk(dir, parts)
	local handle = uv.fs_scandir(dir)
	if not handle then
		return
	end
	while true do
		local name, type = uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if type == "directory" then
			local excluded = false
			for _, pattern in ipairs(utils.EXCLUDED_DIRS) do
				if name:match(pattern) then
					excluded = true
					break
				end
			end
			if not excluded then
				local stat = uv.fs_stat(dir .. "/" .. name)
				parts[#parts + 1] = name .. ":" .. (stat and stat.mtime.sec or 0)
				signature_walk(dir .. "/" .. name, parts)
			end
		end
	end
end

--- @return string? signature nil when the project root cannot be resolved
local function current_signature()
	local root = utils.get_project_root()
	if not root then
		return nil
	end
	local parts = {}
	utils.foreach_classpath(function(classpath)
		local full = classpath:gsub("/$", "")
		local stat = uv.fs_stat(full)
		parts[#parts + 1] = full .. "=" .. (stat and stat.mtime.sec or "-")
		if stat then
			signature_walk(full, parts)
		end
		return false
	end, config.classpaths.java)
	return table.concat(parts, "|")
end

--- @return boolean
local function load_cache()
	local file = io.open(cache_file(), "rb")
	if not file then
		return false
	end
	local content = file:read("*all")
	file:close()
	local ok, data = pcall(vim.mpack.decode, content)
	if not ok or type(data) ~= "table" or type(data.index) ~= "table" then
		return false
	end
	if data.signature ~= cache_signature then
		return false
	end
	class_index_cache = data.index
	return true
end

local function save_cache(index)
	local ok, packed = pcall(vim.mpack.encode, { signature = cache_signature, index = index })
	if not ok then
		logger.warn("Failed to encode class index cache")
		return
	end
	local file = io.open(cache_file(), "wb")
	if not file then
		return
	end
	file:write(packed)
	file:close()
end

local function rebuild()
	local index = {}
	utils.foreach_classpath(function(classpath)
		if vim.fn.isdirectory(classpath) == 1 then
			for _, full_name in ipairs(utils.scan_java_classes(classpath, "")) do
				local simple_name = full_name:match("%.([^%.]+)$") or full_name
				index[simple_name] = index[simple_name] or {}
				table.insert(index[simple_name], full_name)
			end
		end
	end, config.classpaths.java)
	class_index_cache = index
	save_cache(index)
end

--- load or rebuild the class index for the current module root
--- @return table<string, string[]> index simple name -> list of full names
local function ensure_index()
	local signature = current_signature()
	if class_index_cache and not force_rebuild and signature == cache_signature then
		return class_index_cache
	end
	class_index_cache = nil
	cache_signature = signature
	force_rebuild = false
	if signature and load_cache() then
		return class_index_cache
	end
	rebuild()
	return class_index_cache
end

function M.get_completion_items(partial, ctx, callback)
	local index = ensure_index()
	local items = {}
	for simple_name, full_names in pairs(index) do
		if #full_names == 1 then
			local full_name = full_names[1]
			table.insert(items, {
				label = simple_name,
				--- @type lsp.CompletionItemKind
				kind = 7,
				insertText = full_name,
				filterText = simple_name,
				detail = full_name,
				data = { class = full_name },
			})
		else
			-- ambiguous simple name: label with the full name so entries stay distinguishable
			for _, full_name in ipairs(full_names) do
				table.insert(items, {
					label = full_name,
					--- @type lsp.CompletionItemKind
					kind = 7,
					insertText = full_name,
					filterText = simple_name,
					detail = full_name,
					data = { class = full_name },
				})
			end
		end
	end
	callback(items)
end

--- resolve an unambiguous fully-qualified name for a simple class name
--- @param simple_name string
--- @return string? full_name nil when unknown or ambiguous
function M.resolve(simple_name)
	local index = ensure_index()
	local full_names = index[simple_name]
	if not full_names or #full_names ~= 1 then
		return nil
	end
	return full_names[1]
end

function M.refresh()
	class_index_cache = nil
	cache_signature = nil
	force_rebuild = true
end

function M.is_available()
	return true
end

return M
