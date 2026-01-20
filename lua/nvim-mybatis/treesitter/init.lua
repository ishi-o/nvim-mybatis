local M = {}

M.extract = require("nvim-mybatis.treesitter.extract")
M.find = require("nvim-mybatis.treesitter.find")
M.locate = require("nvim-mybatis.treesitter.locate")
M.query = require("nvim-mybatis.treesitter.query")
M.scan = require("nvim-mybatis.treesitter.scan")

M.parse = M.query.parse

return M
