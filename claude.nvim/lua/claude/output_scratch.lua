--------------------------------------------------------------------------------
-- claude.output_scratch
--
-- This module preserves the original plain answer buffer implementation.
--
-- Owns:
--   - Opening the simple split-based review buffer
--   - Formatting answer records into markdown-ish lines
--   - Installing buffer-local actions like comment insertion and close
--
-- Does NOT own:
--   - Choosing whether scratch is the preferred viewer
--   - Volt-based drawer rendering
--
-- Why keep this module:
-- The scratch viewer is still the safest fallback when Volt is unavailable or if
-- the user explicitly prefers a simple buffer. It also acts as an escape hatch
-- from the richer drawer UI via the "open full buffer" action.
--------------------------------------------------------------------------------

local M = {}

local function build_lines(record)
  local action_hint = record.submit_mode == "comment_now"
    and "Comment-now mode could not apply comments safely, so this review buffer was opened instead. Press `I` or run `:ClaudeComment` to retry after fixing the file state."
    or "Press `I` or run `:ClaudeComment` to insert this answer into the source file as comments."

  local lines = {
    "# Claude Answer",
    "",
    string.format("Model: `%s`", record.model),
    string.format("Mode: `%s`", record.submit_mode == "comment_now" and "comment now" or "answer"),
    string.format("Source: `%s`", record.context.relative_path or record.context.file_label or "[No Name]"),
    string.format("Asked: `%s`", record.timestamp),
    "",
    action_hint,
    "",
    "## Question",
    "",
  }

  vim.list_extend(lines, vim.split(record.question, "\n", { plain = true }))

  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Answer"
  lines[#lines + 1] = ""

  if record.answer ~= "" then
    vim.list_extend(lines, vim.split(record.answer, "\n", { plain = true }))
  else
    lines[#lines + 1] = "[No answer returned]"
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Consulted Files"
  lines[#lines + 1] = ""

  if #record.consulted_files == 0 then
    lines[#lines + 1] = "- [Not reported by backend]"
  else
    for _, file in ipairs(record.consulted_files) do
      lines[#lines + 1] = "- " .. file
    end
  end

  return lines
end

function M.open_record(record, config, actions)
  vim.cmd(config.answers.open_cmd)

  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local scratch_name = string.format("%s [%s]", config.answers.scratch_name, string.sub(record.id, -6))

  vim.api.nvim_buf_set_name(buf, scratch_name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].filetype = "markdown"
  vim.wo[win].wrap = true

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, build_lines(record))
  vim.bo[buf].modifiable = false

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, desc = "Close Claude answer" })
  vim.keymap.set("n", "I", function()
    actions.comment(record)
  end, { buffer = buf, silent = true, desc = "Insert answer as comments" })
  vim.keymap.set("n", "y", function()
    actions.copy_answer(record)
  end, { buffer = buf, silent = true, desc = "Copy Claude answer" })
  vim.keymap.set("n", "Y", function()
    actions.copy_comment(record)
  end, { buffer = buf, silent = true, desc = "Copy comment block" })
end

return M
