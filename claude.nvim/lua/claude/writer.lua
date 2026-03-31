--------------------------------------------------------------------------------
-- claude.writer
--
-- This module performs on-disk file writes for Claude-generated comment blocks.
--
-- Owns:
--   - Reading the current on-disk file contents
--   - Inserting prepared lines after a target line
--   - Writing the updated file back to disk
--
-- Does NOT own:
--   - Deciding if a comment is safe
--   - Formatting raw answer text into comments
--
-- Why write to disk instead of mutating the buffer directly?
-- Doing the write at the filesystem layer allows watchdiff.nvim to detect and
-- highlight the change as an external edit, which is exactly the review workflow
-- the user wants to validate before relying on it.
--------------------------------------------------------------------------------

local M = {}

local function maybe_annotate_watchdiff(plan)
  local ok, watchdiff = pcall(require, "watchdiff")
  if not ok or type(watchdiff.annotate_next_change) ~= "function" then
    return nil
  end

  watchdiff.annotate_next_change({
    path = plan.path,
    source = plan.source or "claude.nvim",
    action = plan.action or "insert_comment",
    summary = plan.summary,
    meta = plan.meta,
  })

  return watchdiff
end

function M.apply(plan)
  local disk_lines = vim.fn.readfile(plan.path)
  local insert_after = math.max(0, math.min(plan.after_line, #disk_lines))
  local new_lines = {}
  local watchdiff = maybe_annotate_watchdiff(plan)

  for i = 1, insert_after do
    new_lines[#new_lines + 1] = disk_lines[i]
  end

  for _, line in ipairs(plan.lines) do
    new_lines[#new_lines + 1] = line
  end

  for i = insert_after + 1, #disk_lines do
    new_lines[#new_lines + 1] = disk_lines[i]
  end

  local ok, err = pcall(vim.fn.writefile, new_lines, plan.path)
  if not ok then
    if watchdiff and type(watchdiff.discard_next_change) == "function" then
      watchdiff.discard_next_change(plan.path)
    end
    return nil, tostring(err)
  end

  if not package.loaded.watchdiff and plan.source_buf and vim.api.nvim_buf_is_valid(plan.source_buf) then
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(plan.source_buf) then
        vim.cmd("checktime " .. plan.source_buf)
      end
    end)
  end

  return true
end

return M
