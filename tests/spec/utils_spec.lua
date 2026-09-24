local helpers = require("spec.helpers")
local utils = require("nvim-mybatis.utils")

describe("utils", function()
	after_each(function()
		vim.cmd("%bdelete!")
	end)

	it("is_mybatis_file matches mapper name patterns", function()
		local bufnr =
			helpers.load_buf("project/src/main/resources/mapper/UserMapper.xml", "mybatis")
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
		assert.same({
			"com.example.entity.User",
			"com.example.legacy.User",
			"com.example.mapper.UserMapper",
		}, classes)
	end)

	it("scan_java_classes excludes target and build directories", function()
		local classes = utils.scan_java_classes(
			vim.fs.normalize((debug.getinfo(1, "S").source:sub(2):gsub("/[^/]+$", "")))
				.. "/excluded",
			""
		)
		assert.same({}, classes)
	end)

	it("search_mapper uses Neovim's grep backend", function()
		helpers.cd_project()
		local grepprg = vim.o.grepprg
		vim.o.grepprg = "internal"
		local ok, file = pcall(utils.search_mapper, "com.example.mapper.UserMapper")
		vim.o.grepprg = grepprg
		vim.cmd("cd -")

		assert.is_true(ok)
		assert.equals(helpers.fixture("project/src/main/resources/mapper/UserMapper.xml"), file)
	end)
end)
