local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("/$", "")

vim.opt.swapfile = false
vim.opt.shadafile = "NONE"
vim.opt.shada = ""

vim.opt.runtimepath:prepend(root .. "/lua")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
-- spec helpers live in tests/lua/spec/helpers.lua (require("spec.helpers"))
vim.opt.runtimepath:prepend(root .. "/tests")
package.path = root .. "/tests/lua/?.lua;" .. root .. "/tests/lua/?/init.lua;" .. package.path
-- tree-sitter parsers installed by nvim-treesitter
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/site")

--- prepend a test dependency to the runtimepath: tests/deps first, then a
--- locally installed lazy.nvim clone, so the suite also runs outside CI
--- @param name string
--- @return boolean found
local function prepend_dep(name)
	local candidates = {
		root .. "/tests/deps/" .. name,
		vim.fn.stdpath("data") .. "/lazy/" .. name,
	}
	for _, path in ipairs(candidates) do
		if vim.fn.isdirectory(path) == 1 then
			vim.opt.runtimepath:prepend(path)
			return true
		end
	end
	return false
end

assert(prepend_dep("plenary.nvim"), "plenary.nvim not found; clone it into tests/deps/")
prepend_dep("nvim-treesitter")
require("nvim-mybatis.treesitter.install").setup()
