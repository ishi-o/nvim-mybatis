--- @module 'mybatis.completion.blink'

--- @type blink.cmp.Source
local source = {}

local logger = require("nvim-mybatis.logger")
local config = require("nvim-mybatis.config"):get()
local utils = require("nvim-mybatis.utils")
local helpers = require("nvim-mybatis.completion.helpers")
--- @type table<mybatis.completion.Provider, mybatis.completion.Backend>
local backend = {
	index = require("nvim-mybatis.completion.backend.index"),
	jdtls = require("nvim-mybatis.completion.backend.jdtls"),
}

function source.new(_, _)
	return setmetatable({}, { __index = source })
end

function source:get_completions(ctx, callback)
	local response = {
		items = {},
		is_incomplete_backward = false,
		is_incomplete_forward = false,
	}
	--- @type mybatis.completion.Backend
	local provider
	if config.completion_provider == "default" then
		--- @type mybatis.completion.Provider[]
		local provider_order = { "index", "jdtls" }
		for _, p in ipairs(provider_order) do
			if backend[p] ~= nil then
				provider = backend[p]
				break
			end
		end
	else
		provider = backend[config.completion_provider]
	end
	local partial = ctx:get_keyword()
	if partial == "" then
		callback(response)
		return function() end
	end

	if not provider.is_available() then
		callback(response)
		return function() end
	end

	response.items = provider.get_completion_items(partial, helpers.extract_context())
	callback(response)
	return function() end
end

function source:enabled()
	if not utils.is_mybatis_xml() then
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
	return vim.tbl_contains(config.type_attributes, attr_name) or false
end

function source:get_trigger_characters()
	return { '"', "." }
end

return source
