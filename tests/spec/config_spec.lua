local config = require("nvim-mybatis.config")
local constants = require("nvim-mybatis.constants")

describe("config", function()
	after_each(function()
		config.setup()
	end)

	it("applies overrides while retaining unrelated defaults", function()
		config.setup({
			xml_search_tool = "grep",
			classpaths = {
				java = { "custom/java" },
			},
		})

		assert.equals("grep", config.get().xml_search_tool)
		assert.same({ "custom/java" }, config.get().classpaths.java)
		assert.same({ "src/main/resources" }, config.get().classpaths.xml)
	end)

	it("resets overrides when setup is called again", function()
		config.setup({ xml_search_tool = "grep" })
		config.setup()

		assert.equals("default", config.get().xml_search_tool)
	end)
end)
