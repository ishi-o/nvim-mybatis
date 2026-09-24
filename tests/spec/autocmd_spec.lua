local helpers = require("spec.helpers")
local autocmd = require("nvim-mybatis.autocmd")

describe("autocmd", function()
	after_each(function()
		vim.cmd("%bdelete!")
	end)

	it("sets mapper XML buffers to the mybatis filetype", function()
		autocmd.setup()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(
			bufnr,
			helpers.fixture("project/src/main/resources/mapper/UserMapper.xml")
		)
		vim.api.nvim_set_current_buf(bufnr)
		vim.bo[bufnr].filetype = "xml"
		vim.api.nvim_exec_autocmds("BufEnter", { buffer = bufnr })

		assert.equals("mybatis", vim.bo[bufnr].filetype)
	end)

	it("leaves ordinary XML buffers as XML", function()
		autocmd.setup()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, helpers.fixture("project/pom.xml"))
		vim.api.nvim_set_current_buf(bufnr)
		vim.bo[bufnr].filetype = "xml"
		vim.api.nvim_exec_autocmds("BufEnter", { buffer = bufnr })

		assert.equals("xml", vim.bo[bufnr].filetype)
	end)

	it("registers the custom parser with nvim-treesitter", function()
		require("nvim-mybatis.treesitter.install").setup()
		local parser = require("nvim-treesitter.parsers").mybatis

		assert.truthy(parser)
		assert.equals("https://github.com/ishi-o/tree-sitter-mybatis", parser.install_info.url)
		assert.equals("queries/mybatis", parser.install_info.queries)
	end)
end)
