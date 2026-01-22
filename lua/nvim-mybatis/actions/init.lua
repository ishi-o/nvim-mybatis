local M = {}

local utils = require("nvim-mybatis.utils")
local generator = require("nvim-mybatis.actions.generator")
local handlers = require("nvim-mybatis.actions.handler")

local original_buf_request_all

local function inject(results, ctx)
	local bufnr = ctx.bufnr
	if not utils.is_mybatis_java(bufnr) then
		return
	end

	for _, response in pairs(results) do
		if not response.err then
			local actions = generator.get_code_actions(ctx.params.range, ctx.params.context, bufnr)

			response.result = response.result or {}
			for _, action in ipairs(actions) do
				table.insert(response.result, action)
			end
		end
	end
end

function M.setup()
	if original_buf_request_all then
		return
	end

	vim.lsp.commands["mybatis.generate_tag"] = function(command)
		local args = command.arguments[1]
		handlers.generate_tag(args.interface, args.method, args.bufnr)
	end

	original_buf_request_all = vim.lsp.buf_request_all
	vim.lsp.buf_request_all = function(bufnr, method, make_params, handler)
		if method == "textDocument/codeAction" then
			-- switch handler
			return original_buf_request_all(bufnr, method, make_params, function(results, ctx, config)
				inject(results, ctx)
				return handler(results, ctx, config)
			end)
		end
		return original_buf_request_all(bufnr, method, make_params, handler)
	end
end

function M.restore()
	if original_buf_request_all then
		vim.lsp.buf_request_all = original_buf_request_all
	end
end

return M
