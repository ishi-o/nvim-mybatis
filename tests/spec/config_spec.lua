local config = require("nvim-mybatis.config")
local constants = require("nvim-mybatis.constants")

describe("config", function()
	after_each(function()
		config.setup()
	end)

	it("applies overrides while retaining unrelated defaults", function()
		config.setup({
			xml_search_pattern = { "**/*.xml" },
			classpaths = {
				java = { "custom/java" },
			},
		})

		assert.same({ "**/*.xml" }, config.get().xml_search_pattern)
		assert.same({ "custom/java" }, config.get().classpaths.java)
		assert.same({ "src/main/resources", "src/test/resources" }, config.get().classpaths.xml)
	end)

	it("resets overrides when setup is called again", function()
		config.setup({ xml_search_pattern = { "**/*.xml" } })
		config.setup()

		assert.same({ "**/*Mapper*.xml" }, config.get().xml_search_pattern)
	end)
end)
