local M = {}

M.extract = require("nvim-mybatis.treesitter.extract")
M.find = require("nvim-mybatis.treesitter.find")
M.query = require("nvim-mybatis.treesitter.query")
M.scan = require("nvim-mybatis.treesitter.scan")

--- @param qry mybatis.treesitter.Query
--- @param bufnr? integer
--- @return boolean success
function M.locate(qry, bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if vim.api.nvim_get_current_buf() ~= bufnr then
		vim.api.nvim_set_current_buf(bufnr)
	end
	for _, node in M.query.iter_query(bufnr, qry.lang, M.query.parse(qry)) do
		local row, col = node:range()
		vim.api.nvim_win_set_cursor(0, { row + 1, col })
		return true
	end
	return false
end

return M
