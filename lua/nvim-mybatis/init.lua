local M = {}

--- @param config NvimMybatisConfig
function M.setup(config)
	if require("nvim-mybatis.config").setup(config):get().enabled then
		require("nvim-mybatis.autocmd").setup()
	end
end

return M
