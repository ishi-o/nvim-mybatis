local M = {}

local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set
local utils = require("nvim-mybatis.utils")
local navigator = require("nvim-mybatis.navigator")
local logger = require("nvim-mybatis.logger")

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
				if not navigator.xml.navigate_from_xml(bufnr) then
					vim.lsp.buf.definition()
				end
			end, {
				buffer = bufnr,
				desc = "Mybatis: navigate from XML",
			})
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
				if not navigator.java.navigate_from_java(bufnr) then
					vim.lsp.buf.definition()
				end
			end, {
				buffer = bufnr,
				desc = "Mybatis: navigate from java",
			})
			logger.info("Java file loaded successfully")
		end,
	})
end

return M
