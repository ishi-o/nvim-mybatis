--- @module 'nvim-mybatis.actions.generator'
--- Code actions and direct commands for generating MyBatis CRUD tags.

local M = {}

local ts = vim.treesitter
local treesitter = require("nvim-mybatis.treesitter")
local handler = require("nvim-mybatis.actions.handler")

--- All support commands
--- @type table<string, function>
M.SUPPORT_CMDS = {
	["mybatis.generate_crud"] = handler.generate_crud,
}

--- Get the arguments used to generate a CRUD tag at the current cursor.
--- @param bufnr integer Java source file buffer number
--- @return mybatis.action.CrudTagArgs?
function M.get_crud_args(bufnr)
	local node = ts.get_node()
	if not node then
		return nil
	end
	local interface, method = treesitter.extract.interface_method(node, bufnr)
	if not interface or not method then
		return nil
	end
	return {
		interface = interface,
		method = method,
		resultType = treesitter.extract.resultType(node, bufnr) or "resultType",
		bufnr = bufnr,
	}
end

--- CodeAction: Generate MyBatis Tag
--- @param range lsp.Range
--- @param context lsp.CodeActionContext
--- @param bufnr integer
--- @return lsp.CodeAction?
function M.generate_tag(range, context, bufnr)
	local CA_TITLE = "Generate MyBatis Tag"
	local CMD = "mybatis.generate_crud"
	local args = M.get_crud_args(bufnr)
	if not args then
		return nil
	end
	return {
		title = CA_TITLE,
		--- @type lsp.CodeActionKind
		kind = "refactor",
		--- @type lsp.Command
		command = {
			title = CA_TITLE,
			command = CMD,
			arguments = {
				args,
			},
		},
	}
end

--- Generate a CRUD tag directly from the current mapper method.
--- @param bufnr? integer Java source file buffer number
--- @return boolean generated whether the cursor is on a mapper method
function M.generate_tag_command(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local args = M.get_crud_args(bufnr)
	if not args then
		return false
	end
	handler.generate_crud(args)
	return true
end

--- Get All CodeAction
--- @param range lsp.Range
--- @param context lsp.CodeActionContext
--- @param bufnr integer
--- @return lsp.CodeAction[]
function M.get_code_actions(range, context, bufnr)
	local raw_actions = {
		M.generate_tag(range, context, bufnr),
	}
	local actions = {}
	for _, action in ipairs(raw_actions) do
		if action ~= nil then
			table.insert(actions, action)
		end
	end
	return actions
end

return M
