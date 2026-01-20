local M = {}

--- @param config mybatis.NvimMybatisConfig
function M.setup(config)
	if require("nvim-mybatis.config").setup(config):get().autocmd then
		require("nvim-mybatis.autocmd").setup()
	end
end

return M
