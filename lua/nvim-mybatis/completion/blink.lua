--- @module 'nvim-mybatis.completion.blink'
--- blink.cmp adapter around the shared completion core.

--- @type blink.cmp.Source
local source = {}

local utils = require("nvim-mybatis.utils")
local context = require("nvim-mybatis.completion.context")
local core = require("nvim-mybatis.completion.core")

function source.new(_, _)
	return setmetatable({}, { __index = source })
end

--- replace the whole attribute value on accept so a fully-qualified class name
--- overwrites whatever partial text was typed
--- @param item lsp.CompletionItem
--- @param ctx mybatis.completion.Context
local function apply_text_edit(item, ctx)
	if ctx.kind ~= "class" or not ctx.value_node or not ctx.bufnr or not item.insertText then
		return
	end
	local start_row, start_col, end_row, end_col = ctx.value_node:range()
	item.textEdit = {
		range = {
			start = { line = start_row, character = start_col },
			["end"] = { line = end_row, character = end_col },
		},
		newText = '"' .. item.insertText .. '"',
	}
end

function source:get_completions(ctx, callback)
	local response = {
		items = {},
		is_incomplete_backward = false,
		is_incomplete_forward = false,
	}
	local comp_ctx = context.detect()
	if not comp_ctx then
		callback(response)
		return function() end
	end

	core.complete(comp_ctx, ctx:get_keyword(), function(items)
		for _, item in ipairs(items) do
			apply_text_edit(item, comp_ctx)
		end
		response.items = items
		callback(response)
	end)
	return function() end
end

function source:enabled()
	if not utils.is_mybatis_xml() then
		return false
	end
	return context.detect() ~= nil
end

function source:get_trigger_characters()
	return { '"', "." }
end

return source
