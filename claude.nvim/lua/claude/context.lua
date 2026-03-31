--------------------------------------------------------------------------------
-- claude.context
--
-- This module reads editor context before the popup opens.
--
-- Owns:
--   - Detecting whether the user is in visual mode
--   - Capturing the selected text before Neovim leaves visual mode
--   - Returning lightweight metadata about the selection
--   - Reporting the current file label for placeholder text
--
-- Does NOT own:
--   - Popup rendering
--   - Popup lifecycle
--   - What happens after submit
--
-- Why this module matters:
-- Selection data is easy to lose in Neovim because opening a window or leaving
-- visual mode changes editor state. By isolating capture logic here, the rest of
-- the plugin can treat context as plain data.
--------------------------------------------------------------------------------

local M = {}

local CTRL_V = "\22"

local function current_buffer_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)

  if path == "" then
    return nil
  end

  return path
end

function M.find_loaded_buffer(file_path)
  if not file_path then
    return -1
  end

  local target = vim.uv.fs_realpath(file_path) or file_path

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
      local name = vim.api.nvim_buf_get_name(bufnr)
      local resolved = name ~= "" and (vim.uv.fs_realpath(name) or name) or nil

      if resolved == target or name == file_path then
        return bufnr
      end
    end
  end

  return -1
end

function M.is_visual_mode(mode)
  mode = mode or vim.fn.mode()
  return mode == "v" or mode == "V" or mode == CTRL_V
end

local function normalize_range(start_pos, end_pos)
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]

  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  return {
    start_line = start_line,
    start_col = start_col,
    end_line = end_line,
    end_col = end_col,
  }
end

local function slice_charwise(lines, range)
  if #lines == 0 then
    return lines
  end

  if #lines == 1 then
    lines[1] = string.sub(lines[1], range.start_col, range.end_col)
    return lines
  end

  lines[1] = string.sub(lines[1], range.start_col)
  lines[#lines] = string.sub(lines[#lines], 1, range.end_col)

  return lines
end

local function slice_blockwise(lines, range)
  local sliced = {}

  for _, line in ipairs(lines) do
    sliced[#sliced + 1] = string.sub(line, range.start_col, range.end_col)
  end

  return sliced
end

--------------------------------------------------------------------------------
-- capture_visual_selection()
--
-- Returns nil outside of visual mode. Otherwise returns a plain Lua table with
-- the captured text and selection coordinates.
--
-- Notes about the implementation:
--   - We read marks "v" and "." while the selection is still active.
--   - For charwise and blockwise selections we trim the lines to the selected
--     columns so the stored text matches what the user highlighted.
--   - Columns from getpos() are byte-based, and string.sub() also works with
--     byte indices, so they line up for this purpose.
--------------------------------------------------------------------------------
function M.capture_visual_selection()
  local mode = vim.fn.mode()

  if not M.is_visual_mode(mode) then
    return nil
  end

  local range = normalize_range(vim.fn.getpos("v"), vim.fn.getpos("."))
  local lines = vim.api.nvim_buf_get_lines(0, range.start_line - 1, range.end_line, false)
  local selected_lines = vim.deepcopy(lines)

  if mode == "v" then
    selected_lines = slice_charwise(selected_lines, range)
  elseif mode == CTRL_V then
    selected_lines = slice_blockwise(selected_lines, range)
  end

  return {
    kind = "selection",
    mode = mode,
    text = table.concat(selected_lines, "\n"),
    lines = #selected_lines,
    start_line = range.start_line,
    end_line = range.end_line,
    start_col = range.start_col,
    end_col = range.end_col,
  }
end

--------------------------------------------------------------------------------
-- current_file_label()
--
-- Returns a friendly file name for placeholder text.
--
-- Keeping this tiny helper here means layout.lua can stay focused on text
-- formatting while context.lua remains the place that knows about editor state.
--------------------------------------------------------------------------------
function M.current_file_label(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local path = current_buffer_path(bufnr)
  local file = path and vim.fs.basename(path) or ""

  if file == "" then
    return "[No Name]"
  end

  return file
end

--------------------------------------------------------------------------------
-- capture()
--
-- Captures the source context that an answer should be anchored to.
--
-- This is richer than capture_visual_selection() because later features need to
-- know not only what was selected, but also which buffer/file/cursor location the
-- answer belongs to if the user later chooses "add this answer as comments".
--------------------------------------------------------------------------------
function M.capture()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = current_buffer_path(bufnr)
  local repo_root = file_path and vim.fs.root(file_path, { ".git" }) or nil
  local cursor = vim.api.nvim_win_get_cursor(0)
  local selection = M.capture_visual_selection()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  return {
    kind = selection and "selection" or "file",
    selection = selection,
    source_buf = bufnr,
    source_win = vim.api.nvim_get_current_win(),
    file_path = file_path,
    file_label = M.current_file_label(bufnr),
    repo_root = repo_root or (file_path and vim.fs.dirname(file_path)) or vim.uv.cwd(),
    relative_path = repo_root and file_path and vim.fs.relpath(repo_root, file_path) or file_path,
    cursor_line = cursor[1],
    cursor_col = cursor[2] + 1,
    filetype = vim.bo[bufnr].filetype,
    commentstring = vim.bo[bufnr].commentstring,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
    disk_hash = vim.fn.sha256(table.concat(lines, "\n")),
    comment_after_line = selection and selection.end_line or cursor[1],
  }
end

return M
