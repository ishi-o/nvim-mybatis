--- `query` defines some commonly used queries
local M = {}

local ts = vim.treesitter

--- @return mybatis.treesitter.Query query
function M.package()
	return {
		lang = "java",
		query = [[
		(package_declaration
			(scoped_identifier) @pkg)
	]],
	}
end

--- @return mybatis.treesitter.Query query
function M.interface()
	return {
		lang = "java",
		query = [[
        (interface_declaration name: (identifier) @name)
        (class_declaration name: (identifier) @name)
	]],
	}
end

--- @param method string
--- @return mybatis.treesitter.Query query
function M.method(method)
	return {
		lang = "java",
		query = string.format(
			[[
            (method_declaration
                name: (identifier) @method_name
                (#eq? @method_name "%s")
            )
        ]],
			method
		),
	}
end

--- @return mybatis.treesitter.Query query
function M.attr_types()
	return {
		lang = "xml",
		query = [[
        ((Attribute
          (Name) @attr_name
          (AttValue) @attr_value)
          (#any-of? @attr_name ]] .. table.concat(
			vim.tbl_map(function(t)
				return '"' .. t .. '"'
			end, M.xmltypes()),
			" "
		) .. [[))
    ]],
	}
end

--- @return string[] xmltypes
function M.xmltypes()
	return {
		"resultType",
		"parameterType",
		"type",
		"namespace",
	}
end

--- @param sqlid string value without double quotes
--- @return mybatis.treesitter.Query
function M.sqlid(sqlid)
	return {
		lang = "xml",
		query = string.format(
			[[
		(STag
          (Name) @tag_name
          (Attribute
            (Name) @attr_name
            (AttValue) @attr_value
			(#eq? @tag_name "sql")
			(#eq? @attr_value "\"%s\"")))
		]],
			sqlid
		),
	}
end

--- @param query mybatis.treesitter.Query
--- @return vim.treesitter.Query
function M.parse(query)
	return vim.treesitter.query.parse(query.lang, query.query)
end

--- @param bufnr integer
--- @param lang string
--- @param query vim.treesitter.Query
--- @return (fun(end_line: integer|nil, end_col: integer|nil):integer, TSNode, vim.treesitter.query.TSMetadata, TSQueryMatch, TSTree)|nil iter
function M.iter_query(bufnr, lang, query)
	local parser = ts.get_parser(bufnr, lang)
	if not parser then
		return nil
	end
	return query:iter_captures(parser:parse()[1]:root(), bufnr, 0, -1)
end

return M
