--- @module 'nvim-mybatis.completion.omnifunc'
--- Native Neovim completion (`completefunc`) adapter around the shared
--- completion core. Set up automatically on MyBatis XML buffers; invoke with
--- `<C-x><C-o>` inside an attribute value.
local M = {}

local context = require("nvim-mybatis.completion.context")
local core = require("nvim-mybatis.completion.core")

--- @type table<integer, string> lsp.CompletionItemKind -> complete-item kind char
local KIND_CHAR = {
	[7] = "C", -- Class
	[2] = "f", -- Method
	[5] = "m", -- Field
	[3] = "f", -- Function
}

--- find where the typed value starts: right after the opening quote of the
--- attribute value, so accepting an item replaces the whole partial text
--- @return integer col 0-based column, or -3 to cancel completion silently
local function findstart()
	if not context.detect() then
		return -3
	end
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local start = col
	while start > 0 do
		local c = line:sub(start, start)
		if c == '"' or c == "'" or c == "<" or c:match("%s") then
			break
		end
		start = start - 1
	end
	return start
end

--- completefunc/omnifunc entry point
--- @param findstart integer
--- @param base string
--- @return integer|table
function M.omnifunc(findstart, base)
	if findstart == 1 then
		return findstart()
	end

	local ctx = context.detect()
	if not ctx then
		return {}
	end

	local items = core.complete_sync(ctx, base)
	local out = {}
	for _, item in ipairs(items) do
		table.insert(out, {
			word = item.insertText or item.label,
			abbr = item.label,
			menu = "[Mybatis]",
			kind = KIND_CHAR[item.kind] or "v",
			info = item.detail,
			icase = 1,
		})
	end
	return out
end

return M
