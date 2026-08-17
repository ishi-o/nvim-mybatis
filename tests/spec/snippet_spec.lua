local snippet = require("nvim-mybatis.actions.snippet")

describe("actions.snippet", function()
	before_each(function()
		vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, true))
		vim.bo.shiftwidth = 2
	end)

	it("picks select for select-like method names", function()
		for _, name in ipairs({ "selectUser", "findUsers", "getUser", "queryUsers" }) do
			local result = snippet.crud(name, "User")
			assert.truthy(result:find('<select id="' .. name .. '"', 1, true), name)
			assert.truthy(result:find('resultType="${1:User}"', 1, true), name)
		end
	end)

	it("picks update for update-like method names", function()
		assert.truthy(snippet.crud("updateEmail", "User"):find('<update id="updateEmail"', 1, true))
		assert.truthy(snippet.crud("modifyUser", "User"):find("<update ", 1, true))
	end)

	it("picks delete for delete-like method names", function()
		assert.truthy(snippet.crud("deleteUser", "User"):find('<delete id="deleteUser"', 1, true))
		assert.truthy(snippet.crud("removeUser", "User"):find("<delete ", 1, true))
	end)

	it("picks insert for insert-like method names", function()
		assert.truthy(snippet.crud("insertUser", "User"):find('<insert id="insertUser"', 1, true))
		assert.truthy(snippet.crud("saveUser", "User"):find("<insert ", 1, true))
	end)

	it("falls back to select for unknown prefixes", function()
		assert.truthy(snippet.crud("fooBar", "User"):find("<select ", 1, true))
	end)
end)
