local M = {}

local parsers = {
  "lua",
  "luadoc",
  "printf",
  "vim",
  "vimdoc",
  "go",
  "html",
  "markdown",
  "markdown_inline",
  "python",
  "typescript",
  "tsx",
  "javascript",
  "json",
  "sql",
}

local filetypes = {
  "lua",
  "vim",
  "help",
  "go",
  "html",
  "markdown",
  "python",
  "typescript",
  "typescriptreact",
  "javascript",
  "javascriptreact",
  "json",
  "sql",
}

function M.setup()
  pcall(function()
    dofile(vim.g.base46_cache .. "syntax")
    dofile(vim.g.base46_cache .. "treesitter")
  end)

  local treesitter = require "nvim-treesitter"
  treesitter.setup()
  treesitter.install(parsers)

  vim.treesitter.language.register("tsx", "typescriptreact")

  local group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = filetypes,
    callback = function(args)
      if not pcall(vim.treesitter.start, args.buf) then
        return
      end

      local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
      local ok, indent_query = pcall(vim.treesitter.query.get, lang, "indents")
      if ok and indent_query then
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end,
  })
end

return M
