local M = {}

local uv = vim.uv or vim.loop
local config = require("nvim-mybatis.config"):get()

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

--- scan dir_path recursively
--- @param dir_path string
--- @param current_pkg string
--- @param exclude_dirs? string[]
--- @return string[] classes All fully qualified class name in `dir_path`
function M.scan_java_classes(dir_path, current_pkg, exclude_dirs)
	local classes = {}
	exclude_dirs = exclude_dirs or { "^%.", "target", "build" }

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
--- @return boolean
function M.foreach_classpath(func)
	local project_root = M.get_module_root()
	for _, classpath in ipairs(config.classpath) do
		if func(project_root .. "/" .. classpath .. "/") then
			return true
		end
	end
	return false
end

return M
