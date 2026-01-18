local M = {}

local utils = require("nvim-mybatis.utils")
local gotos = require("nvim-mybatis.gotos")
local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set

function M.setup()
	autocmd("FileType", {
		pattern = "xml",
		callback = function(args)
			local bufnr = args.buf
			if not utils.is_mybatis_xml(bufnr) then
				return
			end
			map("n", "gd", function()
				gotos.goto_java(bufnr)
			end, {
				buffer = bufnr,
				desc = "Nvim-MyBatis: jump to Java class or method",
			})
			vim.notify("[Nvim-Mybatis] XML file loaded successfully", vim.log.levels.INFO)
		end,
	})
	autocmd("FileType", {
		pattern = "java",
		callback = function(args)
			local bufnr = args.buf
			if not utils.is_mapper(bufnr) then
				return
			end
			map("n", "gd", function()
				gotos.goto_xml(bufnr)
			end, {
				buffer = bufnr,
				desc = "Nvim-Mybatis: jump to XML tags",
			})
		end,
	})
end

return M
