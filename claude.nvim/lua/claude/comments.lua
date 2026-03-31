--------------------------------------------------------------------------------
-- claude.comments
--
-- This module turns an answer record into safe inline comments.
--
-- Owns:
--   - Deciding whether a stored answer can be inserted safely
--   - Deriving short comment-ready lines
--   - Formatting those lines via commentstring
--   - Delegating the final disk write to writer.lua
--
-- Does NOT own:
--   - Running Claude
--   - Scratch answer rendering
--
-- Why keep this separate?
-- Converting natural-language answers into source comments has its own rules and
-- safety checks. Keeping it isolated prevents controller.lua from becoming a mix
-- of orchestration and text-manipulation logic.
--------------------------------------------------------------------------------

local context = require("claude.context")
local writer = require("claude.writer")

local M = {}

local fallback_commentstrings = {
  lua = "-- %s",
  python = "# %s",
  sh = "# %s",
  bash = "# %s",
  zsh = "# %s",
  ruby = "# %s",
  rust = "// %s",
  go = "// %s",
  c = "// %s",
  cpp = "// %s",
  java = "// %s",
  javascript = "// %s",
  javascriptreact = "// %s",
  typescript = "// %s",
  typescriptreact = "// %s",
  markdown = "<!-- %s -->",
  vim = '" %s',
}

local function trim_blank_edges(lines)
  while #lines > 0 and lines[1] == "" do
    table.remove(lines, 1)
  end

  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines, #lines)
  end

  return lines
end

local function sanitize_line(line)
  line = vim.trim(line)
  line = line:gsub("^#+%s*", "")
  line = line:gsub("^[-*+]%s+", "")
  line = line:gsub("^%d+%.%s+", "")

  if line:match("^```") then
    return nil
  end

  return line ~= "" and line or nil
end

local function wrap_line(text, max_width)
  local wrapped = {}
  local current = ""

  for word in text:gmatch("%S+") do
    if current == "" then
      current = word
    elseif #current + 1 + #word <= max_width then
      current = current .. " " .. word
    else
      wrapped[#wrapped + 1] = current
      current = word
    end
  end

  if current ~= "" then
    wrapped[#wrapped + 1] = current
  end

  return wrapped
end

local function derive_plain_lines(record, config)
  local source_lines = #record.comment_candidate > 0 and record.comment_candidate
    or vim.split(record.answer or "", "\n", { plain = true })

  local plain_lines = {}

  for _, raw in ipairs(source_lines) do
    local sanitized = sanitize_line(raw)
    if sanitized then
      local wrapped = wrap_line(sanitized, config.comments.max_chars_per_line)
      for _, wrapped_line in ipairs(wrapped) do
        plain_lines[#plain_lines + 1] = wrapped_line
        if #plain_lines >= config.comments.max_lines then
          return trim_blank_edges(plain_lines)
        end
      end
    end
  end

  return trim_blank_edges(plain_lines)
end

local function get_indent(line)
  return line:match("^%s*") or ""
end

local function loaded_source_buf(record)
  if record.context.source_buf
    and vim.api.nvim_buf_is_valid(record.context.source_buf)
    and vim.api.nvim_buf_get_name(record.context.source_buf) == (record.context.file_path or "")
  then
    return record.context.source_buf
  end

  return context.find_loaded_buffer(record.context.file_path)
end

local function commentstring_for(bufnr, record)
  local commentstring

  if bufnr ~= -1 then
    commentstring = vim.bo[bufnr].commentstring
  else
    commentstring = record.context.commentstring
  end

  if commentstring and commentstring ~= "" then
    return commentstring
  end

  local filetype = record.context.filetype
  if (not filetype or filetype == "") and record.context.file_path then
    filetype = vim.filetype.match({ filename = record.context.file_path })
  end

  return fallback_commentstrings[filetype]
end

local function format_comment_lines(record, config, disk_lines, commentstring)
  local plain_lines = derive_plain_lines(record, config)

  if #plain_lines == 0 then
    return nil, "Answer is not suitable for inline comments"
  end

  if commentstring == nil or commentstring == "" or not commentstring:find("%%s") then
    return nil, "Current file does not expose a usable commentstring"
  end

  local anchor_line = math.max(1, math.min(record.context.comment_after_line, math.max(#disk_lines, 1)))
  local indent = get_indent(disk_lines[anchor_line] or "")
  local formatted = {}

  if config.comments.insert_blank_line then
    formatted[#formatted + 1] = ""
  end

  for _, line in ipairs(plain_lines) do
    formatted[#formatted + 1] = indent .. commentstring:gsub("%%s", config.comments.prefix .. line, 1)
  end

  return formatted, plain_lines
end

--------------------------------------------------------------------------------
-- preview(record, config)
--
-- Returns the comment lines that would be inserted for a record without writing
-- them to disk.
--
-- This is used by the answer viewer for copy/preview actions. It intentionally
-- skips the stricter file-change safety checks from insert(), because copying a
-- comment preview should still work even when insertion itself would be blocked.
--------------------------------------------------------------------------------
function M.preview(record, config)
  if not record or not record.context then
    return nil, "No Claude answer is available to format as comments"
  end

  local bufnr = record.context.file_path and loaded_source_buf(record) or -1
  local disk_lines = { "" }

  if record.context.file_path and vim.fn.filereadable(record.context.file_path) == 1 then
    disk_lines = vim.fn.readfile(record.context.file_path)
  end

  local commentstring = commentstring_for(bufnr, record)
  local lines, plain_lines_or_err = format_comment_lines(record, config, disk_lines, commentstring)

  if not lines then
    return nil, plain_lines_or_err
  end

  return {
    lines = lines,
    text = table.concat(lines, "\n"),
    plain_lines = plain_lines_or_err,
  }
end

--------------------------------------------------------------------------------
-- insert(record, config)
--
-- Converts the stored answer record into comments and writes them to disk.
--
-- Safety rules enforced here:
--   - the answer must still be anchored to a real file
--   - the source buffer must be clean and unmodified
--   - the file must not have changed since the answer was generated
--   - comment syntax must be known
--------------------------------------------------------------------------------
function M.insert(record, config)
  if not record or not record.context or not record.context.file_path then
    return nil, "No source file is associated with the last Claude answer"
  end

  local bufnr = loaded_source_buf(record)

  if bufnr ~= -1 then
    if vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable then
      return nil, "Source buffer is not writable"
    end

    if vim.bo[bufnr].modified then
      return nil, "Source buffer has unsaved edits; save or discard them before inserting comments"
    end

    if vim.api.nvim_buf_get_changedtick(bufnr) ~= record.context.changedtick then
      return nil, "Source file changed since this answer was generated; ask again to avoid misplaced comments"
    end
  end

  local disk_lines = vim.fn.readfile(record.context.file_path)

  if record.context.disk_hash and vim.fn.sha256(table.concat(disk_lines, "\n")) ~= record.context.disk_hash then
    return nil, "Source file changed on disk since this answer was generated; ask again before inserting comments"
  end

  local commentstring = commentstring_for(bufnr, record)
  local lines, plain_lines_or_err = format_comment_lines(record, config, disk_lines, commentstring)

  if not lines then
    return nil, plain_lines_or_err
  end

  return writer.apply({
    path = record.context.file_path,
    source_buf = bufnr ~= -1 and bufnr or nil,
    after_line = record.context.comment_after_line,
    lines = lines,
    summary = plain_lines_or_err and plain_lines_or_err[1] or nil,
    meta = {
      question = record.question,
      model = record.model,
      file = record.context.relative_path or record.context.file_path,
    },
  })
end

return M
