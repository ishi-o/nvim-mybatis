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

return M
