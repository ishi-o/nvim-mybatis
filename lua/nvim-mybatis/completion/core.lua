--- Completion core: context-aware dispatch to the matching source, plus shared
--- fuzzy filtering/ranking so every adapter (blink, omnifunc) behaves the same.
--- @module 'nvim-mybatis.completion.core'
local M = {}

local ts = vim.treesitter
local config = require("nvim-mybatis.config"):get()
local utils = require("nvim-mybatis.utils")
local query = require("nvim-mybatis.treesitter.query")
local scan = require("nvim-mybatis.treesitter.scan")
local logger = require("nvim-mybatis.logger")

--- @type table<mybatis.completion.Provider, mybatis.completion.Backend>
local backend = {
	index = require("nvim-mybatis.completion.backend.index"),
	jdtls = require("nvim-mybatis.completion.backend.jdtls"),
}

--- @type table<mybatis.completion.ContextKind, lsp.CompletionItemKind>
local LSP_KIND = {
	class = 7, -- Class
	method = 2, -- Method
	field = 5, -- Field
	refid = 3, -- Function
}

--- @return mybatis.completion.Backend?
local function provider()
	if config.completion_provider ~= "default" then
		return backend[config.completion_provider]
	end
	for _, name in ipairs({ "index", "jdtls" }) do
		if backend[name].is_available() then
			return backend[name]
		end
	end
	return nil
end

--- rank keys by fuzzy match against `partial`
--- @param keys string[]
--- @param partial string
--- @return table<string, integer> rank key -> best position (lower is better)
local function build_rank(keys, partial)
	local rank = {}
	local ordered = partial == "" and keys or vim.fn.matchfuzzy(keys, partial)
	for i, key in ipairs(ordered) do
		rank[key] = math.min(rank[key] or math.huge, i)
	end
	return rank
end

--- fuzzy-filter and rank items by filterText (simple name) and insertText (full name)
--- @param items lsp.CompletionItem[]
--- @param partial string
--- @return lsp.CompletionItem[]
local function postprocess(items, partial)
	local filter_keys, insert_keys = {}, {}
	for _, item in ipairs(items) do
		table.insert(filter_keys, item.filterText or item.label)
		if item.insertText and item.insertText ~= "" then
			table.insert(insert_keys, item.insertText)
		end
	end
	local filter_rank = build_rank(filter_keys, partial)
	local insert_rank = build_rank(insert_keys, partial)

	local out = {}
	for _, item in ipairs(items) do
		local fr = filter_rank[item.filterText or item.label]
		local ir = item.insertText and insert_rank[item.insertText] or nil
		local best = fr and ir and math.min(fr, ir) or fr or ir
		if best then
			item.sortText = string.format("%06d", best)
			table.insert(out, item)
		end
	end
	table.sort(out, function(a, b)
		return a.sortText < b.sortText
	end)
	return out
end

--- find the java source file for a fully-qualified class name
--- @param classname string
--- @return string? file
local function find_java_file(classname)
	local root = utils.get_module_root()
	if not root then
		return nil
	end
	local filepath = classname:gsub("%.", "/") .. ".java"
	for _, classpath in ipairs(config.classpaths.java) do
		local full = root .. "/" .. classpath .. "/" .. filepath
		if vim.fn.filereadable(full) == 1 then
			return full
		end
	end
	return nil
end

--- load a java file into a hidden buffer for treesitter parsing
--- @param classname string
--- @return integer? bufnr
local function load_java_buffer(classname)
	local file = find_java_file(classname)
	if not file then
		return nil
	end
	local bufnr = vim.fn.bufadd(file)
	vim.fn.bufload(bufnr)
	return bufnr
end

--- @param ctx mybatis.completion.Context
--- @param partial string
--- @param callback fun(items: lsp.CompletionItem[])
local function complete_class(ctx, partial, callback)
	local p = provider()
	if not p or not p.is_available() then
		callback({})
		return
	end
	p.get_completion_items(partial, ctx, function(items)
		callback(postprocess(items, partial))
	end)
end

--- @param ctx mybatis.completion.Context
--- @param partial string
--- @param callback fun(items: lsp.CompletionItem[])
local function complete_method(ctx, partial, callback)
	if not ctx.namespace then
		callback({})
		return
	end
	local bufnr = load_java_buffer(ctx.namespace)
	if not bufnr then
		callback({})
		return
	end
	local items = {}
	for _, name in ipairs(scan.methods(bufnr)) do
		table.insert(items, {
			label = name,
			kind = LSP_KIND.method,
			insertText = name,
			filterText = name,
			data = { method = name },
		})
	end
	callback(postprocess(items, partial))
end

--- @param ctx mybatis.completion.Context
--- @param partial string
--- @param callback fun(items: lsp.CompletionItem[])
local function complete_field(ctx, partial, callback)
	local classname = ctx.type
	if not classname then
		callback({})
		return
	end
	if not classname:find(".", 1, true) then
		-- simple name: resolve through the class index
		classname = backend.index.resolve(classname)
		if not classname then
			callback({})
			return
		end
	end
	local bufnr = load_java_buffer(classname)
	if not bufnr then
		callback({})
		return
	end
	local items = {}
	for _, name in ipairs(scan.fields(bufnr)) do
		table.insert(items, {
			label = name,
			kind = LSP_KIND.field,
			insertText = name,
			filterText = name,
			data = { field = name },
		})
	end
	callback(postprocess(items, partial))
end

--- @param ctx mybatis.completion.Context
--- @param partial string
--- @param callback fun(items: lsp.CompletionItem[])
local function complete_refid(_, partial, callback)
	local bufnr = vim.api.nvim_get_current_buf()
	local items = {}
	local qry = query.sqlids()
	for _, node in query.iter_query(bufnr, qry.lang, query.parse(qry)) do
		local text = ts.get_node_text(node, bufnr):gsub('^"(.*)"$', "%1")
		table.insert(items, {
			label = text,
			kind = LSP_KIND.refid,
			insertText = text,
			filterText = text,
			data = { refid = text },
		})
	end
	callback(postprocess(items, partial))
end

--- @type table<mybatis.completion.ContextKind, fun(ctx: mybatis.completion.Context, partial: string, callback: fun(items: lsp.CompletionItem[]))>
local DISPATCH = {
	class = complete_class,
	method = complete_method,
	field = complete_field,
	refid = complete_refid,
}

--- complete `partial` according to the detected context
--- @param ctx mybatis.completion.Context
--- @param partial string
--- @param callback fun(items: lsp.CompletionItem[])
function M.complete(ctx, partial, callback)
	local handler = DISPATCH[ctx.kind]
	if not handler then
		logger.warn("Unknown completion context kind: " .. tostring(ctx.kind))
		callback({})
		return
	end
	handler(ctx, partial, callback)
end

--- synchronous variant for contexts that cannot wait for a callback (omnifunc).
--- class completion prefers the backend's sync API (jdtls `request_sync`).
--- @param ctx mybatis.completion.Context
--- @param partial string
--- @return lsp.CompletionItem[]
function M.complete_sync(ctx, partial)
	if ctx.kind == "class" then
		local p = provider()
		if not p or not p.is_available() then
			return {}
		end
		local items
		if p.get_completion_items_sync then
			items = p.get_completion_items_sync(partial, ctx)
		else
			p.get_completion_items(partial, ctx, function(result)
				items = result
			end)
		end
		return postprocess(items or {}, partial)
	end
	local items
	M.complete(ctx, partial, function(result)
		items = result
	end)
	return items or {}
end

return M
