local M = {}

local ts = vim.treesitter
local treesitter = require("nvim-mybatis.treesitter")
local handler = require("nvim-mybatis.actions.handler")

--- All support commands
--- @type table<string, function>
M.SUPPORT_CMDS = {
	["mybatis.generate_tag"] = handler.generate_tag,
}

--- CodeAction: Generate MyBatis Tag
--- @param range lsp.Range
--- @param context lsp.CodeActionContext
--- @param bufnr integer
--- @return lsp.CodeAction?
function M.generate_tag(range, context, bufnr)
	local CA_TITLE = "Generate MyBatis Tag"
	local CMD = "mybatis.generate_tag"
	local node = ts.get_node()
	if not node then
		return nil
	end
	local interface, method = treesitter.extract.interface_method(node, bufnr)
	if not interface or not method then
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
				--- @type mybatis.action.CrudTagArgs
				{
					interface = interface,
					method = method,
					bufnr = bufnr,
				},
			},
		},
	}
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
