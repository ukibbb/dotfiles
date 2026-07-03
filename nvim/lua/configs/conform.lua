return {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_fix", "ruff_format" },
    go = { "goimports", "gofmt" },
  },
  format_on_save = {
    timeout_ms = 3000,
    lsp_fallback = true,
  },
}
