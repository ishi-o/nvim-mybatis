local helpers = require("spec.helpers")
local context = require("nvim-mybatis.completion.context")
local core = require("nvim-mybatis.completion.core")
local index = require("nvim-mybatis.completion.backend.index")

local XML = "project/src/main/resources/mapper/UserMapper.xml"

--- run core.complete synchronously (all fixture sources invoke the callback
--- synchronously) and collect the labels
--- @param ctx mybatis.completion.Context
--- @param partial string
--- @return string[] labels
local function complete_labels(ctx, partial)
	local items
	core.complete(ctx, partial, function(result)
		items = result
	end)
	local labels = {}
	for _, item in ipairs(items or {}) do
		table.insert(labels, item.label)
	end
	return labels
end

local function contains(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

describe("completion.core", function()
	before_each(function()
		helpers.cd_project()
		local dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")
		index.set_cache_dir(dir)
		helpers.load_buf(XML, "xml")
	end)

	after_each(function()
		vim.cmd("%bdelete!")
		vim.cmd("cd -")
	end)

	it("completes interface methods for crud id attributes", function()
		assert.truthy(helpers.goto_mark('id="selectUser"'))
		local labels = complete_labels(context.detect(), "")
		assert.truthy(contains(labels, "selectUser"))
		assert.truthy(contains(labels, "findUsersByUsername"))
		assert.truthy(contains(labels, "insertUser"))
		assert.truthy(contains(labels, "updateEmail"))
		assert.truthy(contains(labels, "deleteUser"))
	end)

	it("fuzzy-filters and ranks method completion", function()
		assert.truthy(helpers.goto_mark('id="selectUser"'))
		local labels = complete_labels(context.detect(), "user")
		assert.truthy(contains(labels, "selectUser"))
		assert.truthy(contains(labels, "insertUser"))
		assert.falsy(contains(labels, "updateEmail"))
	end)

	it("completes entity fields for property attributes", function()
		assert.truthy(helpers.goto_mark('property="username"'))
		local labels = complete_labels(context.detect(), "")
		assert.truthy(contains(labels, "username"))
		assert.truthy(contains(labels, "email"))
		assert.truthy(contains(labels, "id"))
		assert.falsy(contains(labels, "getUsername"))
	end)

	it("completes sql fragment ids for refid attributes", function()
		assert.truthy(helpers.goto_mark('refid="baseColumns"'))
		local labels = complete_labels(context.detect(), "")
		assert.truthy(contains(labels, "baseColumns"))
	end)

	it("completes classes and disambiguates duplicate simple names", function()
		assert.truthy(helpers.goto_mark('resultType="com.example.entity.User"'))
		local ctx = context.detect()
		local items
		core.complete(ctx, "User", function(result)
			items = result
		end)
		local labels = {}
		for _, item in ipairs(items) do
			table.insert(labels, item.label)
		end
		-- `User` exists in two packages: entries are labeled with the full name
		assert.truthy(contains(labels, "com.example.entity.User"))
		assert.truthy(contains(labels, "com.example.legacy.User"))
		for _, item in ipairs(items) do
			if item.label == "com.example.entity.User" then
				assert.equals("com.example.entity.User", item.insertText)
				assert.equals("User", item.filterText)
			end
		end
	end)

	it("index backend round-trips through the cache file", function()
		local dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")
		index.set_cache_dir(dir)
		assert.is_not_nil(index.resolve("UserMapper"))
		assert.is_nil(index.resolve("User")) -- ambiguous
		assert.is_nil(index.resolve("NoSuchClass"))
		local cache_files = vim.fn.glob(dir .. "/*.mpack", false, true)
		assert.equals(1, #cache_files)
		-- refresh drops the in-memory cache and the file cache is rewritten
		index.refresh()
		assert.is_not_nil(index.resolve("UserMapper"))
	end)

	it("complete_sync mirrors complete for sync sources", function()
		assert.truthy(helpers.goto_mark('id="selectUser"'))
		local items = core.complete_sync(context.detect(), "select")
		local labels = {}
		for _, item in ipairs(items) do
			table.insert(labels, item.label)
		end
		assert.truthy(contains(labels, "selectUser"))
	end)
end)

describe("completion.omnifunc", function()
	local omnifunc = require("nvim-mybatis.completion.omnifunc")

	before_each(function()
		helpers.cd_project()
		local dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")
		index.set_cache_dir(dir)
		helpers.load_buf(XML, "xml")
	end)

	after_each(function()
		vim.cmd("%bdelete!")
		vim.cmd("cd -")
	end)

	it("returns -3 when not on a completion site", function()
		assert.truthy(helpers.goto_mark("from users"))
		assert.equals(-3, omnifunc.omnifunc(1, ""))
	end)

	it("starts completion right after the opening quote", function()
		assert.truthy(helpers.goto_mark('resultType="com.example.entity.User"'))
		-- move the cursor inside the value, just before `User`
		assert.truthy(helpers.goto_mark('resultType="com', #'resultType="'))
		assert.is_not_nil(omnifunc.omnifunc(1, ""))
		local start = omnifunc.omnifunc(1, "")
		local line = vim.api.nvim_get_current_line()
		assert.equals('"', line:sub(start, start))
	end)

	it("completes class words through the omnifunc contract", function()
		assert.truthy(helpers.goto_mark('resultType="com'))
		local results = omnifunc.omnifunc(0, "com")
		assert.truthy(#results > 0)
		for _, item in ipairs(results) do
			assert.truthy(item.word)
			assert.equals("[Mybatis]", item.menu)
		end
	end)
end)
