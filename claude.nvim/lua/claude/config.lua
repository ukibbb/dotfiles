--------------------------------------------------------------------------------
-- claude.config
--
-- This module owns the plugin's configuration shape.
--
-- Owns:
--   - Default values for the popup UI
--   - Highlight group names and theme links
--   - Merging user options with defaults
--
-- Does NOT own:
--   - Runtime popup state
--   - Window creation
--   - Keymaps or commands
--
-- Why this file exists:
-- The public entry point should stay small. By moving defaults here, the rest of
-- the plugin can depend on one well-defined config table instead of hardcoding
-- values in multiple places.
--------------------------------------------------------------------------------

local M = {}

M.defaults = {
  width = 70,
  input_height = 3,
  border_style = "rounded",
  input_padding = 2,
  selection_margin = 2,
  placeholder = "Ask Claude about this code...",
  comment_placeholder = "Ask Claude to add explanation comments here...",

  backend = {
    command = "claude",
    extra_args = { "-p", "--output-format", "json", "--permission-mode", "plan" },
    env = {},
    model_aliases = {
      ["opus 4.5"] = "opus",
      sonnet = "sonnet",
      haiku = "haiku",
    },
  },

  answers = {
    ui = "volt",
    layout = "drawer",
    open_cmd = "botright 16new",
    scratch_name = "Claude Answer",
    min_width = 58,
    max_width = 92,
    width_ratio = 0.42,
    min_height = 16,
    margin = 2,
    wrap = true,
    highlights = {
      border = "ClaudeOutputBorder",
      title = "ClaudeOutputTitle",
      meta = "ClaudeOutputMeta",
      tab_active = "ClaudeOutputTabActive",
      tab_inactive = "ClaudeOutputTabInactive",
      footer = "ClaudeOutputFooter",
      action = "ClaudeOutputAction",
      warning = "ClaudeOutputWarning",
      file = "ClaudeOutputFile",
    },
  },

  comments = {
    prefix = "Claude: ",
    max_lines = 6,
    max_chars_per_line = 92,
    insert_blank_line = false,
  },

  models = { "opus 4.5", "sonnet", "haiku" },

  icons = {
    close = "✕",
    send = "󰒊",
    model_arrow = "▾",
    tab_hint = "⇥",
    enter_hint = "↵",
  },

  highlights = {
    subtle = "ClaudeSubtle",
    icon = "ClaudeIcon",
    title = "ClaudeTitle",
    border = "ClaudeBorder",
    mode_answer = "ClaudeModeAnswer",
    mode_comment = "ClaudeModeComment",
  },

  highlight_links = {
    ClaudeSubtle = "Comment",
    ClaudeIcon = "Special",
    ClaudeTitle = "Title",
    ClaudeBorder = "FloatBorder",
    ClaudeModeAnswer = "Identifier",
    ClaudeModeComment = "String",
    ClaudeOutputBorder = "FloatBorder",
    ClaudeOutputTitle = "Title",
    ClaudeOutputMeta = "Comment",
    ClaudeOutputTabActive = "String",
    ClaudeOutputTabInactive = "Comment",
    ClaudeOutputFooter = "Comment",
    ClaudeOutputAction = "Special",
    ClaudeOutputWarning = "WarningMsg",
    ClaudeOutputFile = "Identifier",
  },
}

--------------------------------------------------------------------------------
-- merge(user_opts)
--
-- Returns a fresh config table every time.
--
-- Why return a deep copy instead of mutating defaults?
-- If we mutated M.defaults directly, later setup() calls could inherit accidental
-- state from earlier runs. Returning a new table keeps configuration predictable.
--------------------------------------------------------------------------------
function M.merge(user_opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_opts or {})
end

return M
