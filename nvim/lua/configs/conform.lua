-- JS, TS and JSON format only with the project's own tool: Biome where a biome.json(c) exists, else Prettier
-- where a prettier config exists. A project with neither is left alone, and never falls back to the LSP.
local web = { "biome", "prettier", stop_after_first = true, lsp_format = "never" }

return {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_fix", "ruff_format" },
    javascript = web,
    javascriptreact = web,
    typescript = web,
    typescriptreact = web,
    json = web,
    jsonc = web,
  },
  formatters = {
    -- require_cwd: run only when the formatter's config file is found above the file.
    biome = { require_cwd = true },
    prettier = { require_cwd = true },
  },
  format_on_save = {
    timeout_ms = 3000,
    lsp_format = "fallback",
  },
}
