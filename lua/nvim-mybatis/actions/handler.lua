local M = {}

local treesitter = require("nvim-mybatis.treesitter")
local utils = require("nvim-mybatis.utils")
local logger = require("nvim-mybatis.logger")

--- Core generation function: generate MyBatis tag
--- @param interface string interface name
--- @param method string method name
--- @param bufnr integer Java source file buffer number
function M.generate_tag(interface, method, bufnr)
	interface = treesitter.scan.package(bufnr) .. "." .. interface
	local xml_files = utils.search_mapper(interface)
	if not xml_files or #xml_files == 0 then
		logger.error("No mapper XML file found for interface: " .. interface)
		return
	end

	local xml_file = xml_files[1]
	local target_bufnr = vim.fn.bufadd(xml_file)
	vim.fn.bufload(target_bufnr)

	if not vim.api.nvim_buf_is_loaded(target_bufnr) then
		logger.error("Failed to load buffer: " .. xml_file)
		return
	end

	local parser = vim.treesitter.get_parser(target_bufnr, "xml")
	if not parser then
		logger.error("Failed to parse XML with treesitter")
		return
	end
	local tree = parser:parse()[1]
	local root = tree:root()
	local query = vim.treesitter.query.parse(
		"xml",
		[[
            (ETag (Name) @tag_name (#eq? @tag_name "mapper"))
        ]]
	)
	local mapper_end_node = nil
	for _, node in query:iter_captures(root, target_bufnr) do
		mapper_end_node = node
		break
	end
	if not mapper_end_node then
		logger.error("No </mapper> tag found in XML file")
		return
	end

	local row, col, end_row, end_col = mapper_end_node:range()
	local insert_line = row
	vim.api.nvim_set_current_buf(target_bufnr)
	vim.api.nvim_win_set_cursor(0, { insert_line + 1, 0 })

	local indent = string.rep(" ", vim.bo.shiftwidth)
	local double_indent = string.rep(indent, 2)
	local snippet_text = string.format(
		'\n%s<select id="%s" resultType="${1:resultType}">\n%s${2:<!-- TODO: Add SQL for %s -->}\n%s</select>${3}\n',
		indent,
		method,
		double_indent,
		method,
		indent
	)

	vim.snippet.expand(snippet_text)

	local filename = vim.fn.fnamemodify(xml_file, ":t")
	logger.log(string.format("Generated select statement for %s.%s in %s", interface, method, filename))
end

return M
