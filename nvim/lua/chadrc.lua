-- NvChad configuration filehttps://nvchad.com/docs/recipes
-- This file is required by the NvChad UI plugin

local M = {}

-- Base46 theme configuration
M.base46 = {
  theme = "ayu_dark", -- Default theme (you can change this)
  transparency = false,

  -- Highlight overrides - customize specific highlight groups
  hl_override = {
    Comment = { fg = "#5fafff", italic = true },
    ["@comment"] = { fg = "#5fafff", italic = true },
    -- Differentiate object properties and member access
    ["@property"] = { fg = "#74c5aa" },
    ["@variable.member"] = { fg = "#74c5aa" },
    ["@variable.member.key"] = { fg = "#74c5aa" },
    -- Type annotations stand out
    ["@type"] = { fg = "#95E6CB" },
    ["@type.builtin"] = { fg = "#95E6CB", bold = true },
    -- Module/namespace names
    ["@module"] = { fg = "#A37ACC" },
    -- Operators (=, ===, =>, etc.)
    ["@operator"] = { fg = "#F29668" },
    -- Exception keywords (try, catch, finally, throw)
    ["@keyword.exception"] = { fg = "#D2A6FF" },
    -- Punctuation slightly dimmer
    ["@punctuation.bracket"] = { fg = "#6C7380" },
    ["@punctuation.delimiter"] = { fg = "#6C7380" },
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
    modules = {
      file = function()
        local stl_utils = require "nvchad.stl.utils"
        local x = stl_utils.file()
        local icon = x[1]
        local path = vim.api.nvim_buf_get_name(stl_utils.stbufnr())
        local name = (path == "" and "Empty") or vim.fn.fnamemodify(path, ":~:.")
        return "%#St_file# " .. icon .. " " .. name .. " "
      end,
    },
  },
}

return M
