local M = {}

local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set
local utils = require("nvim-mybatis.utils")
local navigator = require("nvim-mybatis.navigator")
local logger = require("nvim-mybatis.logger")

function M.setup()
	autocmd("FileType", {
		pattern = "xml",
		callback = function(args)
			local bufnr = args.buf
			if not utils.is_mybatis_file(bufnr) then
				return
			end
			map("n", "gd", function()
				if not navigator.xml2java.navigate_java(bufnr) then
					vim.lsp.buf.definition()
				end
			end, {
				buffer = bufnr,
				desc = "Mybatis: jump to Java class or method",
			})
			logger.info("XML file loaded successfully")
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
				if not navigator.java2xml.navigate_xml(bufnr) then
					vim.lsp.buf.definition()
				end
			end, {
				buffer = bufnr,
				desc = "Mybatis: jump to XML tags",
			})
			logger.info("Java file loaded successfully")
		end,
	})
end

return M
