--------------------------------------------------------------------------------
-- claude.output
--
-- This module chooses the answer viewer implementation.
--
-- Owns:
--   - Selecting the rich drawer UI when available
--   - Falling back to the plain scratch viewer when needed
--
-- Does NOT own:
--   - The actual rendering details of either viewer
--
-- Mental model:
-- output.lua is a façade. output_drawer.lua is the preferred rich UI, while
-- output_scratch.lua stays available as a simpler and more universal fallback.
--------------------------------------------------------------------------------

local drawer = require("claude.output_drawer")
local comments = require("claude.comments")
local scratch = require("claude.output_scratch")

local M = {}

local function copy_to_clipboard(text, label)
  if not text or text == "" then
    vim.notify("Nothing to copy", vim.log.levels.INFO, { title = "claude.nvim" })
    return false
  end

  vim.fn.setreg('"', text)

  local clipboard = false
  clipboard = pcall(vim.fn.setreg, "+", text) or clipboard
  clipboard = pcall(vim.fn.setreg, "*", text) or clipboard

  vim.notify(
    clipboard
        and string.format("Copied %s to clipboard", label)
      or string.format("Copied %s to unnamed register", label),
    vim.log.levels.INFO,
    { title = "claude.nvim" }
  )

  return true
end

local function view_actions(config, actions)
  return {
    comment = actions.comment,
    copy_answer = function(record)
      return copy_to_clipboard(record.answer or "", "Claude answer")
    end,
    copy_comment = function(record)
      local preview, err = comments.preview(record, config)
      if not preview then
        vim.notify(err, vim.log.levels.WARN, { title = "claude.nvim" })
        return false
      end

      return copy_to_clipboard(preview.text, "comment block")
    end,
  }
end

function M.open_record(record, config, actions)
  local view = view_actions(config, actions)

  if config.answers.ui == "volt" and config.answers.layout == "drawer" and drawer.is_supported() then
    local opened = drawer.open_record(record, config, {
      comment = view.comment,
      copy_answer = view.copy_answer,
      copy_comment = view.copy_comment,
      open_full = function(selected_record)
        scratch.open_record(selected_record, config, view)
      end,
    })

    if opened then
      return
    end
  end

  scratch.open_record(record, config, view)
end

return M
