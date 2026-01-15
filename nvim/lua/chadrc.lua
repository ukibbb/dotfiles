-- NvChad configuration filehttps://nvchad.com/docs/recipes
-- This file is required by the NvChad UI plugin

local M = {}

-- Base46 theme configuration
M.base46 = {
  theme = "ayu_dark", -- Default theme (you can change this)
  transparency = false,

  -- Highlight overrides - customize specific highlight groups
  hl_override = {
    Comment = { fg = "#606060" }, -- Darker gray for comments
    ["@comment"] = { fg = "#606060" }, -- Treesitter comment highlight
  },
}

-- UI Configuration
M.ui = {
  -- Tabufline (buffer tabs at the top)
  tabufline = {
    enabled = true,
    lazyload = true,
  },

  -- Statusline configuration
  statusline = {
    enabled = true,
  },
}

return M
