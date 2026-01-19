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
			if not utils.is_mybatis_file(bufnr) then
				return
			end
			map("n", "gd", function()
				if not gotos.goto_java(bufnr) then
					vim.lsp.buf.definition()
				end
			end, {
				buffer = bufnr,
				desc = "Mybatis: jump to Java class or method",
			})
			utils.log("XML file loaded successfully")
		end,
	})
	autocmd("FileType", {
		pattern = "java",
		callback = function(args)
			local bufnr = args.buf
			if not utils.is_mybatis_file(bufnr) then
				return
			end
			map("n", "gd", function()
				if not gotos.goto_xml(bufnr) then
					vim.lsp.buf.definition()
				end
			end, {
				buffer = bufnr,
				desc = "Mybatis: jump to XML tags",
			})
			utils.log("Java file loaded successfully")
		end,
	})
end

return M
