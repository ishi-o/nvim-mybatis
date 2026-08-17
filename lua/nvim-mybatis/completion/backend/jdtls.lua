--- @module 'nvim-mybatis.completion.backend.jdtls'
--- jdtls class completion backed by `workspace/symbol`.
--- @type mybatis.completion.Backend
local M = {}

M.name = "jdtls"

local SYNC_TIMEOUT_MS = 300

--- @return lsp.Client? client
local function client()
	return vim.lsp.get_clients({ name = "jdtls" })[1]
end

--- @param result lsp.SymbolInformation[]|lsp.DocumentSymbol[]|nil
--- @return lsp.CompletionItem[]
local function build_items(result)
	local items = {}
	if not result then
		return items
	end
	local seen = {}
	for _, symbol in ipairs(result) do
		if
			symbol.kind == vim.lsp.protocol.SymbolKind.Class
			or symbol.kind == vim.lsp.protocol.SymbolKind.Interface
		then
			local simple_name = symbol.name
			if not seen[simple_name] then
				seen[simple_name] = true
				local full_name = symbol.containerName
						and symbol.containerName .. "." .. simple_name
					or simple_name
				table.insert(items, {
					label = simple_name,
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
	return items
end

function M.get_completion_items(partial, ctx, callback)
	local c = client()
	if not c then
		callback({})
		return
	end
	c:request("workspace/symbol", { query = partial }, function(err, result)
		if err then
			callback({})
			return
		end
		callback(build_items(result))
	end, ctx.bufnr)
end

function M.get_completion_items_sync(partial, ctx)
	local c = client()
	if not c then
		return {}
	end
	local response =
		c:request_sync("workspace/symbol", { query = partial }, SYNC_TIMEOUT_MS, ctx.bufnr)
	if not response or response.err then
		return {}
	end
	return build_items(response.result)
end

function M.refresh() end

function M.is_available()
	return client() ~= nil
end

function M.on_change() end

return M
