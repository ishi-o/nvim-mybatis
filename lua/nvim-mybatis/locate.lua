local M = {}

function M.locate_interface()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr, "java")
	if not parser then
		return
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"java",
		[[
        (interface_declaration name: (identifier) @name)
        (class_declaration name: (identifier) @name)
    ]]
	)

	for _, node in query:iter_captures(root, bufnr, 0, -1) do
		local row, col, _, _ = node:range()
		vim.api.nvim_win_set_cursor(0, { row + 1, col })
		return
	end
end

return M
