return {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_fix", "ruff_format" },
  },
  format_on_save = {
    timeout_ms = 3000,
    lsp_fallback = true,
  },
}
