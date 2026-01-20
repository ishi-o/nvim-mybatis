local M = {}

local query = require("nvim-mybatis.treesitter.query")

--- @param bufnr integer
function M.locate_buf(bufnr)
	if vim.api.nvim_get_current_buf() ~= bufnr then
		vim.api.nvim_set_current_buf(bufnr)
	end
end

--- locate to method name in java file
--- @param method string
--- @param bufnr? integer
--- @return boolean success
function M.locate_method(method, bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	M.locate_buf(bufnr)
	local qry = query.parse(query.method(method))
	for _, node in query.iter_query(bufnr, "java", qry) do
		local row, col = node:range()
		vim.api.nvim_win_set_cursor(0, { row + 1, col })
		return true
	end
	return false
end

--- locate interface
--- @param bufnr? integer
--- @return boolean success
function M.locate_interface(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	M.locate_buf(bufnr)
	local qry = query.parse(query.interface())
	for _, node in query.iter_query(bufnr, "java", qry) do
		local row, col, _, _ = node:range()
		vim.api.nvim_win_set_cursor(0, { row + 1, col })
		return true
	end
	return false
end

return M
