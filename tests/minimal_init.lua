local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")

vim.opt.swapfile = false
vim.opt.shadafile = "NONE"
vim.opt.shada = ""

vim.opt.runtimepath:prepend(root .. "/lua")
vim.opt.runtimepath:append(vim.fn.stdpath("config") .. "/share/nvim/runtime")

local has_treesitter, _ = pcall(require, "nvim-treesitter")
if not has_treesitter then
	package.preload["nvim-treesitter"] = function()
		return {
			setup = function() end,
		}
	end
end

pcall(require, "mybatis")
