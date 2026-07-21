-- Treesitter Configuration
-- nvim-treesitter installs parsers and queries; Neovim starts the parsers.

pcall(function()
  dofile(vim.g.base46_cache .. "syntax")
  dofile(vim.g.base46_cache .. "treesitter")
end)

local parsers = {
  "lua",
  "luadoc",
  "printf",
  "vim",
  "vimdoc",
  "python",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "typescript",
  "tsx",
  "javascript",
  "markdown",
  "markdown_inline",
}

local filetypes = {
  "lua",
  "vim",
  "vimdoc",
  "python",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "typescript",
  "typescriptreact",
  "javascript",
  "javascriptreact",
  "markdown",
}

return {
  setup = {
    install_dir = vim.fn.stdpath "data" .. "/site",
  },
  ensure_installed = parsers,
  highlight_filetypes = filetypes,
  indent_filetypes = filetypes,
  parsers_by_filetype = {
    javascriptreact = "javascript",
    typescriptreact = "tsx",
  },
}
