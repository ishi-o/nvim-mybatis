local M = {}

--- @param config mybatis.NvimMybatisConfig
function M.setup(config)
	if require("nvim-mybatis.config").setup(config):get().autocmd then
		require("nvim-mybatis.autocmd").setup()
	end
	require("nvim-mybatis.actions").setup()
end

return M
