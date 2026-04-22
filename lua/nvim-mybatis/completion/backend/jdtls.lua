--- @type mybatis.completion.Backend
local M = {}

M.name = "jdtls"

function M.get_completion_items(partial, ctx)
	--- @type lsp.CompletionItem[]
	local items = {}

	local client = vim.lsp.get_clients({ name = "jdtls" })[1]
	local params = { query = partial }
	client:request("workspace/symbol", params, function(err, result)
		if err or not result then
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
					local full_name = symbol.containerName and symbol.containerName .. "." .. simple_name or simple_name
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
	end)
	return items
end

function M.refresh() end

function M.is_available()
	local clients = vim.lsp.get_clients({ name = "jdtls" })
	if #clients == 0 then
		return false
	end
	return true
end

function M.on_change() end

return M
