local commands = require("nvim-mybatis.commands")

describe("commands", function()
	after_each(function()
		vim.api.nvim_del_user_command("MybatisJump")
		vim.api.nvim_del_user_command("MybatisGenerateTag")
	end)

	it("registers the public navigation and generation commands", function()
		commands.setup()

		assert.equals(2, vim.fn.exists(":MybatisJump"))
		assert.equals(2, vim.fn.exists(":MybatisGenerateTag"))
	end)
end)
