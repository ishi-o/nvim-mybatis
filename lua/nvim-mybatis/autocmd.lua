local M = {}

local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set
local utils = require("nvim-mybatis.utils")
local navigator = require("nvim-mybatis.navigator")
local logger = require("nvim-mybatis.logger")
local treesitter_install = require("nvim-mybatis.treesitter.install")

local function jump(bufnr)
	if not navigator.jump(bufnr) then
		vim.lsp.buf.definition()
	end
end

--- Register MyBatis filetype autocmds and buffer-local `gd` mappings.
function M.setup()
	local group = vim.api.nvim_create_augroup("NvimMybatis", { clear = true })
	local function set_mapper_filetype(args)
		local bufnr = args.buf
		if vim.bo[bufnr].filetype ~= "mybatis" and utils.is_mybatis_file(bufnr) then
			vim.bo[bufnr].filetype = "mybatis"
		end
	end

	-- Mapper files are XML on disk, but use the MyBatis parser instead of the
	-- generic XML parser. The filename check keeps ordinary XML files untouched.
	autocmd({ "BufRead", "BufNewFile", "BufEnter" }, {
		pattern = "*.xml",
		group = group,
		callback = set_mapper_filetype,
	})
	autocmd("FileType", {
		pattern = "mybatis",
		group = group,
		callback = function(args)
			local bufnr = args.buf
			treesitter_install.ensure(bufnr)
			map("n", "gd", function()
				jump(bufnr)
			end, {
				buffer = bufnr,
				desc = "Mybatis: navigate from mapper",
			})
			-- native completion (<C-x><C-o>); only when nothing else claimed omnifunc
			if vim.bo[bufnr].omnifunc == "" then
				vim.bo[bufnr].omnifunc = "v:lua.require'nvim-mybatis.completion.omnifunc'.omnifunc"
			end
			logger.info("MyBatis mapper loaded successfully")
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
