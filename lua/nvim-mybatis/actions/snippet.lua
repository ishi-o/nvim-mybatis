local M = {}

--- @return string, string indents indent and double indent
local function indent()
	local idt = string.rep(" ", vim.bo.shiftwidth)
	return idt, string.rep(idt, 2)
end

function M.select(method, resultType)
	local idt, didt = indent()
	return string.format(
		'\n%s<select id="%s" resultType="${1:%s}">\n%s${2:<!-- TODO: Add SQL for %s -->}\n%s</select>${3}\n',
		idt,
		method,
		resultType,
		didt,
		method,
		idt
	)
end

function M.update(method)
	local idt, didt = indent()
	return string.format(
		'\n%s<update id="%s">\n%s${1:<!-- TODO: Add SQL for %s -->}\n%s</update>${2}\n',
		idt,
		method,
		didt,
		method,
		idt
	)
end

function M.delete(method)
	local idt, didt = indent()
	return string.format(
		'\n%s<delete id="%s">\n%s${1:<!-- TODO: Add SQL for %s -->}\n%s</delete>${2}\n',
		idt,
		method,
		didt,
		method,
		idt
	)
end

function M.insert(method)
	local idt, didt = indent()
	return string.format(
		'\n%s<insert id="%s" useGeneratedKeys="${1:true}" keyProperty="${2}">\n%s${3:<!-- TODO: Add SQL for %s -->}\n%s</insert>${4}\n',
		idt,
		method,
		didt,
		method,
		idt
	)
end

--- Get CRUD snippet, intelligently analyze the tag type.
--- @param method string method name
--- @param resultType string resultType
--- @return string snippet
function M.crud(method, resultType)
	local lowerMethod = method:lower()

	if
		lowerMethod:find("^select")
		or lowerMethod:find("^find")
		or lowerMethod:find("^get")
		or lowerMethod:find("^query")
	then
		return M.select(method, resultType)
	elseif lowerMethod:find("^update") or lowerMethod:find("^modify") or lowerMethod:find("^edit") then
		return M.update(method)
	elseif lowerMethod:find("^delete") or lowerMethod:find("^remove") or lowerMethod:find("^del") then
		return M.delete(method)
	elseif
		lowerMethod:find("^insert")
		or lowerMethod:find("^add")
		or lowerMethod:find("^create")
		or lowerMethod:find("^save")
	then
		return M.insert(method)
	else
		return M.select(method, resultType)
	end
end

return M
