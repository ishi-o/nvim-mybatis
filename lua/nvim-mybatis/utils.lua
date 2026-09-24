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
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	return vim.bo[bufnr].filetype == "java" and M.is_mybatis_file(bufnr)
end

--- check if the buffer uses the MyBatis filetype
--- @param bufnr? integer
--- @return boolean
function M.is_mybatis_mapper(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	return vim.bo[bufnr].filetype == "mybatis"
end

--- Backwards-compatible alias for callers that used the old XML name.
--- @param bufnr? integer
--- @return boolean
function M.is_mybatis_xml(bufnr)
	return M.is_mybatis_mapper(bufnr)
end

local function parent_dir(dir)
	local parent = vim.fn.fnamemodify(dir, ":h")
	if parent == "" or parent == dir then
		return nil
	end
	return parent
end

local function has_root_file(dir)
	for _, filename in ipairs(config.root_file) do
		if vim.fn.filereadable(dir .. "/" .. filename) == 1 then
			return true
		end
	end
	return false
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

--- get the outermost project root containing the current module
--- @return string?
function M.get_project_root()
	local module_root = M.get_module_root()
	if not module_root then
		return nil
	end
	local project_root = module_root
	local dir = parent_dir(module_root)
	while dir do
		if has_root_file(dir) then
			project_root = dir
		end
		dir = parent_dir(dir)
	end
	return project_root
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
	local project_root = M.get_project_root()
	if not project_root then
		logger.warn(
			"Module root not found (missing root file: "
				.. table.concat(config.root_file, ", ")
				.. ")"
		)
		return false
	end
	for _, classpath in ipairs(classpaths) do
		local relative_classpath = classpath:gsub("/$", "")
		local paths = vim.fn.glob(project_root .. "/**/" .. relative_classpath, false, true)
		local direct_path = project_root .. "/" .. relative_classpath
		if #paths == 0 then
			paths = { direct_path }
		end
		for _, path in ipairs(paths) do
			if func(path .. "/") then
				return true
			end
		end
	end
	return false
end

local function search_mapper_with_grep(namespace_pattern, mapper_dir)
	local files = {}
	local seen = {}
	local patterns = #config.xml_search_pattern > 0 and config.xml_search_pattern or { "**/*.xml" }
	for _, pattern in ipairs(patterns) do
		for _, file in ipairs(vim.fn.globpath(mapper_dir, pattern, false, true)) do
			file = vim.fs.normalize(file)
			if not seen[file] then
				seen[file] = true
				table.insert(files, file)
			end
		end
	end
	if #files == 0 then
		return nil
	end

	local args = { namespace_pattern }
	vim.list_extend(args, files)
	if vim.o.grepprg ~= "internal" then
		for index, arg in ipairs(args) do
			args[index] = vim.fn.shellescape(arg)
		end
	end
	local ok = pcall(vim.cmd, {
		cmd = "grep",
		bang = true,
		mods = { silent = true },
		args = args,
	})
	if not ok then
		return nil
	end

	for _, item in ipairs(vim.fn.getqflist()) do
		local filename = item.filename
		if
			(not filename or filename == "")
			and item.bufnr
			and item.bufnr > 0
			and vim.api.nvim_buf_is_valid(item.bufnr)
		then
			filename = vim.api.nvim_buf_get_name(item.bufnr)
		end
		if filename and filename ~= "" then
			return vim.fs.normalize(filename)
		end
	end
	return nil
end

--- search mappers.xml by namespace
--- @param namespace string
--- @return string? file
function M.search_mapper(namespace)
	local namespace_pattern = string.format('namespace="%s"', namespace)
	local result = nil
	M.foreach_classpath(function(classpath)
		result = search_mapper_with_grep(namespace_pattern, classpath)
		return result ~= nil
	end, config.classpaths.xml)
	if result == nil then
		logger.warn("No XML file found for mapper: " .. namespace)
		return nil
	end
	return result
end

return M
