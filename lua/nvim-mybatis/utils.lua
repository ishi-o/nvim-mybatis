local M = {}

local uv = vim.uv or vim.loop
local config = require("nvim-mybatis.config"):get()
local logger = require("nvim-mybatis.logger")

--- check if the filename matches config.mapper_name_pattern
--- @param bufnr? integer
--- @return boolean
function M.is_mybatis_file(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t:r")
	for _, pattern in ipairs(config.mapper_name_pattern) do
		if filename:match(pattern) then
			return true
		end
	end
	return false
end

--- check if the file is java and mybatis file
--- @param bufnr? integer
--- @return boolean
function M.is_mybatis_java(bufnr)
	return vim.bo.filetype == "java" and M.is_mybatis_file(bufnr)
end

--- check if the file is xml and mybatis file
--- @param bufnr? integer
--- @return boolean
function M.is_mybatis_xml(bufnr)
	return vim.bo.filetype == "xml" and M.is_mybatis_file(bufnr)
end

--- get project / module root dir
--- @return string?
function M.get_module_root()
	for _, filename in ipairs(config.root_file) do
		local found_file = vim.fn.findfile(filename, ".;")
		if found_file ~= "" then
			return vim.fn.fnamemodify(found_file, ":p:h")
		end
	end
	return nil
end

--- get java builtin types
---@return string[]
function M.get_java_builtin_types()
	return {
		"String",
		"Integer",
		"Long",
		"Double",
		"Float",
		"Boolean",
		"Short",
		"Byte",
		"Character",
		"Object",
		"Void",
		"Class",
		"List",
		"Map",
		"Set",
		"Collection",
		"ArrayList",
		"HashMap",
		"HashSet",
	}
end

--- default directory name patterns excluded when scanning java sources
M.EXCLUDED_DIRS = { "^%.", "target", "build" }

--- scan dir_path recursively
--- @param dir_path string
--- @param current_pkg string
--- @param exclude_dirs? string[]
--- @return string[] classes All fully qualified class name in `dir_path`
function M.scan_java_classes(dir_path, current_pkg, exclude_dirs)
	local classes = {}
	exclude_dirs = exclude_dirs or M.EXCLUDED_DIRS

	local function should_exclude(dir_name)
		for _, pattern in ipairs(exclude_dirs) do
			if dir_name:match(pattern) then
				return true
			end
		end
		return false
	end

	local handle = uv.fs_scandir(dir_path)
	if not handle then
		return classes
	end

	while true do
		local name, type = uv.fs_scandir_next(handle)
		if not name then
			break
		end

		if type == "file" and name:match("%.java$") then
			local class_name = name:gsub("%.java$", "")
			local full_class = current_pkg == "" and class_name or current_pkg .. "." .. class_name
			table.insert(classes, full_class)
		elseif type == "directory" and not should_exclude(name) then
			local new_pkg = current_pkg == "" and name or current_pkg .. "." .. name
			local sub_classes = M.scan_java_classes(dir_path .. "/" .. name, new_pkg, exclude_dirs)
			for _, class in ipairs(sub_classes) do
				table.insert(classes, class)
			end
		end
	end

	return classes
end

--- @param func fun(classpath: string): boolean?
--- @param classpaths string[]
--- @return boolean
function M.foreach_classpath(func, classpaths)
	local project_root = M.get_module_root()
	if not project_root then
		logger.warn("Module root not found (missing root file: " .. table.concat(config.root_file, ", ") .. ")")
		return false
	end
	for _, classpath in ipairs(classpaths) do
		if func(project_root .. "/" .. classpath .. "/") then
			return true
		end
	end
	return false
end

--- @type mybatis.utils.SearchToolHandler
local function search_mapper_fallback_rg(namespace_pattern, mapper_dir)
	local glob_args = {}
	for _, glob_pattern in ipairs(config.xml_search_pattern) do
		table.insert(glob_args, string.format('--glob="%s"', glob_pattern))
	end
	if #glob_args == 0 then
		table.insert(glob_args, '--glob="*.xml"')
	end

	local glob_str = table.concat(glob_args, " ")

	local cmd =
		string.format("rg -l --color=never --fixed-strings %s '%s' '%s'", glob_str, namespace_pattern, mapper_dir)
	local result = vim.fn.system(cmd)
	if vim.v.shell_error == 0 then
		return result:match("[^\r\n]+")
	end
	return nil
end

--- @type mybatis.utils.SearchToolHandler
local function search_mapper_fallback_ag(namespace_pattern, mapper_dir)
	local glob_args = {}
	for _, glob_pattern in ipairs(config.xml_search_pattern) do
		table.insert(glob_args, string.format("-G '%s'", glob_pattern))
	end
	if #glob_args == 0 then
		table.insert(glob_args, "-G '*.xml'")
	end
	local glob_str = table.concat(glob_args, " ")

	local cmd = string.format("ag -l %s '%s' '%s'", glob_str, namespace_pattern, mapper_dir)
	local result = vim.fn.system(cmd)
	if vim.v.shell_error == 0 then
		return result:match("[^\r\n]+")
	end
	return nil
end

--- @type mybatis.utils.SearchToolHandler
local function search_mapper_fallback_grep(namespace_pattern, mapper_dir)
	vim.fn.grep({
		args = { "-r", "-l", "--include=*.xml", vim.pesc(namespace_pattern), mapper_dir },
	})

	local qf = vim.fn.getqflist()
	if qf and #qf > 0 then
		return qf[1].filename
	end

	return nil
end

--- search mappers.xml by namespace
--- @param namespace string
--- @return string? file
function M.search_mapper(namespace)
	local namespace_pattern = string.format('namespace="%s"', namespace)
	local result = nil
	--- @type table<mybatis.utils.SearchTool, mybatis.utils.SearchToolHandler>
	local tools = {
		rg = search_mapper_fallback_rg,
		ag = search_mapper_fallback_ag,
		grep = search_mapper_fallback_grep,
	}
	--- @type mybatis.utils.SearchTool[]
	local tool_order = { "rg", "ag", "grep" }
	M.foreach_classpath(function(classpath)
		if config.xml_search_tool ~= "default" then
			return tools[config.xml_search_tool](namespace_pattern, classpath)
		end
		for _, name in ipairs(tool_order) do
			if name == "grep" or vim.fn.executable(name) ~= 0 then
				result = tools[name](namespace_pattern, classpath)
				if result then
					return true
				end
			end
		end
		return false
	end, config.classpaths.xml)
	if result == nil then
		logger.warn("No XML file found for mapper: " .. namespace)
		return nil
	end
	return result
end

return M
