local null_ls = require "null-ls"

local b = null_ls.builtins

local sources = {

  -- webdev stuff
  b.formatting.deno_fmt, -- choosed deno for ts/js files cuz its very fast!
  b.formatting.prettier.with { filetypes = { "html", "markdown", "css" } }, -- so prettier works only on these filetypes

  b.code_actions.eslint,
  b.diagnostics.eslint,

  -- Lua
  b.formatting.stylua,

  -- cpp
  b.formatting.clang_format,

  -- python
  b.diagnostics.mypy,
  b.diagnostics.ruff,
  b.formatting.isort,
  b.formatting.black,

  b.code_actions.refactoring,
}

null_ls.setup {
  debug = true,
  sources = sources,
}
