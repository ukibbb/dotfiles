-- ============================================================================
-- LuaSnip Configuration
-- LuaSnip is a snippet engine - it expands short triggers into code templates
-- Example: typing "fn" then Tab could expand into a full function definition
-- ============================================================================

-- ============================================================================
-- LOADING SNIPPETS
-- LuaSnip can load snippets from multiple formats. Each format has its own
-- loader. We load snippets from all three major formats for maximum compatibility.
-- ============================================================================

-- ========================================
-- VS CODE FORMAT SNIPPETS
-- These are JSON-based snippets in VS Code's format
-- Many snippet collections (like friendly-snippets) use this format
-- ========================================

-- lazy_load() loads snippets on-demand (when you open a file of that type)
-- This is faster than loading everything at startup
-- exclude = vim.g.vscode_snippets_exclude allows users to skip certain snippets
require("luasnip.loaders.from_vscode").lazy_load { exclude = vim.g.vscode_snippets_exclude or {} }

-- Also load any custom VS Code snippets from user-defined paths
-- vim.g.vscode_snippets_path can be set in your config to add custom snippet dirs
require("luasnip.loaders.from_vscode").lazy_load { paths = vim.g.vscode_snippets_path or "" }

-- ========================================
-- SNIPMATE FORMAT SNIPPETS
-- These are simpler text-based snippets (Vim's traditional format)
-- Easier to write by hand than VS Code JSON
-- ========================================

-- load() loads all snipmate snippets immediately (not lazy)
-- This loads from the default snippet directories
require("luasnip.loaders.from_snipmate").load()

-- lazy_load user's custom snipmate snippets from specified paths
require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.g.snipmate_snippets_path or "" }

-- ========================================
-- LUA FORMAT SNIPPETS
-- Most powerful format - snippets are actual Lua code
-- Allows dynamic content, conditions, transformations
-- ========================================

-- Load Lua snippets immediately
require("luasnip.loaders.from_lua").load()

-- Also load custom Lua snippets from user-defined paths
require("luasnip.loaders.from_lua").lazy_load { paths = vim.g.lua_snippets_path or "" }

-- ============================================================================
-- BUG FIX: LUASNIP #258
-- Fixes an issue where LuaSnip gets stuck when leaving insert mode mid-snippet
-- https://github.com/L3MON4D3/LuaSnip/issues/258
-- ============================================================================

-- Create an autocommand that triggers when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    -- Check two conditions:
    -- 1. Is there an active snippet node in the current buffer?
    --    (session.current_nodes tracks which snippets are active in which buffers)
    -- 2. Is NOT actively jumping between snippet placeholders?
    --    (jump_active is true when tabbing through a snippet)
    if
      require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
      and not require("luasnip").session.jump_active
    then
      -- If you left insert mode while in a snippet (but not jumping),
      -- unlink the snippet to clean up the state
      -- This prevents LuaSnip from thinking you're still in a snippet
      -- when you re-enter insert mode later
      require("luasnip").unlink_current()
    end
  end,
})
