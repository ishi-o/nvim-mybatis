local helpers = require("spec.helpers")
local utils = require("nvim-mybatis.utils")

describe("utils", function()
	after_each(function()
		vim.cmd("%bdelete!")
	end)

	it("is_mybatis_file matches mapper name patterns", function()
		local bufnr = helpers.load_buf("project/src/main/resources/mapper/UserMapper.xml", "xml")
		assert.is_true(utils.is_mybatis_file(bufnr))
	end)

	it("get_module_root finds the fixture maven root", function()
		helpers.cd_project()
		assert.equals(helpers.fixture("project"), vim.fs.normalize(utils.get_module_root()))
		vim.cmd("cd -")
	end)

	it("scan_java_classes lists fully-qualified class names", function()
		local classes = utils.scan_java_classes(helpers.fixture("project/src/main/java"), "")
		table.sort(classes)
		assert.equals({
			"com.example.entity.User",
			"com.example.legacy.User",
			"com.example.mapper.UserMapper",
		}, classes)
	end)

	it("scan_java_classes excludes target and build directories", function()
		local classes = utils.scan_java_classes(
			vim.fs.normalize(debug.getinfo(1, "S").source:sub(2):gsub("/[^/]+$", ""))
				.. "/excluded",
			""
		)
		assert.equals({}, classes)
	end)
end)
