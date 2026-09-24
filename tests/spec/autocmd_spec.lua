local helpers = require("spec.helpers")
local autocmd = require("nvim-mybatis.autocmd")

describe("autocmd", function()
	after_each(function()
		vim.cmd("%bdelete!")
	end)

	it("sets mapper XML buffers to the mybatis.xml filetype", function()
		autocmd.setup()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(
			bufnr,
			helpers.fixture("project/src/main/resources/mapper/UserMapper.xml")
		)
		vim.api.nvim_set_current_buf(bufnr)
		assert.equals("mybatis.xml", vim.filetype.match({ buf = bufnr }))
		vim.bo[bufnr].filetype = "xml"
		vim.api.nvim_exec_autocmds("BufEnter", { buffer = bufnr })

		assert.equals("mybatis.xml", vim.bo[bufnr].filetype)
		assert.equals("mybatis", vim.treesitter.get_parser(bufnr):lang())
	end)

	it("leaves ordinary XML buffers as XML", function()
		autocmd.setup()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, helpers.fixture("project/pom.xml"))
		vim.api.nvim_set_current_buf(bufnr)
		assert.equals("xml", vim.filetype.match({ buf = bufnr }))
		vim.bo[bufnr].filetype = "xml"
		vim.api.nvim_exec_autocmds("BufEnter", { buffer = bufnr })

		assert.equals("xml", vim.bo[bufnr].filetype)
	end)

	it("registers the custom parser and maps the hybrid filetype", function()
		require("nvim-mybatis.treesitter.install").setup()
		local parser = require("nvim-treesitter.parsers").mybatis
		assert.truthy(parser)
		assert.equals("https://github.com/ishi-o/tree-sitter-mybatis", parser.install_info.url)
		assert.equals("queries/mybatis", parser.install_info.queries)
		assert.equals("mybatis", vim.treesitter.language.get_lang("mybatis.xml"))
		vim.api.nvim_exec_autocmds("User", { pattern = "TSUpdate" })
		assert.truthy(require("nvim-treesitter.parsers").mybatis)
		assert.equals(1, #vim.api.nvim_get_autocmds({ group = "NvimMybatisTreeSitter" }))
	end)
end)
