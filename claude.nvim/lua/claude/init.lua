--------------------------------------------------------------------------------
-- claude
--
-- This is the public entry point for the plugin.
--
-- Owns:
--   - setup()
--   - public open/close functions
--   - global keymaps and the :Claude command
--   - storing the merged config currently in use
--
-- Does NOT own:
--   - Popup lifecycle details
--   - Rendering
--   - Input buffer behavior
--   - Selection capture
--
-- How this file relates to the rest of the plugin:
--   init.lua      -> public API and setup
--   controller.lua -> runtime orchestration
--   render.lua    -> windows and buffers
--   input.lua     -> buffer-local behavior
--   backend.lua   -> async backend command execution
--   request.lua   -> prompt/schema construction
--   output.lua    -> answer-viewer facade
--   output_drawer.lua -> Volt review drawer
--   output_scratch.lua -> plain scratch answer buffer
--   comments.lua  -> safe answer-to-comment conversion
--   writer.lua    -> on-disk writes for watchdiff-friendly edits
--   layout.lua    -> geometry and visible strings
--   context.lua   -> visual selection capture
--   state.lua     -> current popup session
--
-- Read this file first when learning the plugin. If you want deeper mechanics,
-- follow the calls from setup() to open() and then into controller.lua.
--------------------------------------------------------------------------------

local config = require("claude.config")
local controller = require("claude.controller")

local M = {}

M.config = config.merge()

local function stored_user_opts()
  local opts = rawget(_G, "__claude_nvim_user_opts")

  if type(opts) == "table" then
    return opts
  end

  return {}
end

local function resolved_user_opts(user_opts)
  if user_opts == nil then
    return stored_user_opts()
  end

  local merged = vim.tbl_deep_extend("force", stored_user_opts(), user_opts)
  _G.__claude_nvim_user_opts = merged

  return merged
end

--------------------------------------------------------------------------------
-- open()
--
-- Public helper that delegates to the controller using the currently active
-- merged config.
--------------------------------------------------------------------------------
function M.open()
  controller.open(M.config)
end

function M.open_comment_now()
  controller.open_comment_now(M.config)
end

M.open_popup = M.open

function M.close()
  controller.close()
end

function M.comment_last_answer()
  return controller.comment_last_answer(M.config)
end

--------------------------------------------------------------------------------
-- setup(user_opts)
--
-- This is the standard Neovim plugin entry point.
--
-- Important detail for development reloads:
-- dev.lua re-runs require("claude").setup() after clearing package.loaded.
-- To preserve any custom options across that reload, we save the user opts in a
-- Lua global and reuse them when setup() is called again with no arguments.
--------------------------------------------------------------------------------
function M.setup(user_opts)
  M.config = config.merge(resolved_user_opts(user_opts))

  vim.keymap.set("n", "<leader>ac", M.open, { desc = "Ask Claude" })
  vim.keymap.set("v", "<leader>ac", M.open, { desc = "Ask Claude with selection" })
  vim.keymap.set("n", "<leader>aC", M.open_comment_now, { desc = "Ask Claude and comment" })
  vim.keymap.set("v", "<leader>aC", M.open_comment_now, { desc = "Ask Claude and comment selection" })

  pcall(vim.api.nvim_del_user_command, "Claude")
  vim.api.nvim_create_user_command("Claude", M.open, { desc = "Open Claude popup" })

  pcall(vim.api.nvim_del_user_command, "ClaudeCommentNow")
  vim.api.nvim_create_user_command("ClaudeCommentNow", M.open_comment_now, {
    desc = "Open Claude popup in comment-now mode",
  })

  pcall(vim.api.nvim_del_user_command, "ClaudeComment")
  vim.api.nvim_create_user_command("ClaudeComment", M.comment_last_answer, {
    desc = "Insert last Claude answer as comments",
  })
end

return M
