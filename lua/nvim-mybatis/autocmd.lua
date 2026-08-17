local M = {}

local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set
local utils = require("nvim-mybatis.utils")
local navigator = require("nvim-mybatis.navigator")
local logger = require("nvim-mybatis.logger")

local function jump(bufnr)
	if not navigator.jump(bufnr) then
		vim.lsp.buf.definition()
	end
end

--- Register MyBatis filetype autocmds and buffer-local `gd` mappings.
function M.setup()
	local group = vim.api.nvim_create_augroup("MyBatis", {})
	autocmd("FileType", {
		pattern = "xml",
		group = group,
		callback = function(args)
			local bufnr = args.buf
			if not utils.is_mybatis_file(bufnr) then
				return
			end
			map("n", "gd", function()
				jump(bufnr)
			end, {
				buffer = bufnr,
				desc = "Mybatis: navigate from XML",
			})
			-- native completion (<C-x><C-o>); only when nothing else claimed omnifunc
			if vim.bo[bufnr].omnifunc == "" then
				vim.bo[bufnr].omnifunc = "v:lua.require'nvim-mybatis.completion.omnifunc'.omnifunc"
			end
			logger.info("XML file loaded successfully")
		end,
	})
	autocmd("FileType", {
		pattern = "java",
		group = group,
		callback = function(args)
			local bufnr = args.buf
			if not utils.is_mybatis_file(bufnr) then
				return
			end
			map("n", "gd", function()
				jump(bufnr)
			end, {
				buffer = bufnr,
				desc = "Mybatis: navigate from java",
			})
			logger.info("Java file loaded successfully")
		end,
	})
	-- invalidate the class index when java sources change (new/renamed classes)
	autocmd("BufWritePost", {
		pattern = "*.java",
		group = group,
		callback = function()
			require("nvim-mybatis.completion.backend.index").refresh()
		end,
	})
end

return M
