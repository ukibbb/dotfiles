--------------------------------------------------------------------------------
-- claude.layout
--
-- This module builds the popup's shape and visible text.
--
-- Owns:
--   - Popup geometry calculations
--   - Header/footer text assembly
--   - Placeholder text formatting
--   - Highlight span metadata for the chrome buffer
--
-- Does NOT own:
--   - Creating windows
--   - Installing keymaps
--   - Runtime session storage
--
-- Mental model:
-- controller.lua decides when to open the popup.
-- render.lua decides how to draw buffers and windows.
-- layout.lua answers: "What should the popup look like right now?"
--------------------------------------------------------------------------------

local M = {}

local HEADER_HEIGHT = 1
local FOOTER_HEIGHT = 1

local function clamp(value, min_value, max_value)
  if value < min_value then
    return min_value
  end

  if value > max_value then
    return max_value
  end

  return value
end

function M.header_height()
  return HEADER_HEIGHT
end

function M.total_height(config)
  return HEADER_HEIGHT + config.input_height + FOOTER_HEIGHT
end

--------------------------------------------------------------------------------
-- main_window_spec(config, context)
--
-- Returns the floating-window geometry for the popup shell.
--
-- With a selection we try to place the popup near the selected text so the UI
-- feels contextual. Without a selection we center it in the current window.
--
-- The function reads editor geometry but does not mutate Neovim state, which is
-- why it belongs in layout.lua instead of render.lua.
--------------------------------------------------------------------------------
function M.main_window_spec(config, context)
  local total_height = M.total_height(config)
  local win_pos = vim.api.nvim_win_get_position(0)
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local selection = context and context.selection or nil

  local col
  local row

  if selection and selection.start_line then
    local first_visible_line = vim.fn.line("w0")
    local selection_top = win_pos[1] + (selection.start_line - first_visible_line)
    local selection_bottom = win_pos[1] + (selection.end_line - first_visible_line)

    col = win_pos[2] + config.selection_margin
    row = selection_top - total_height - 2

    if row < win_pos[1] then
      row = selection_bottom + 2
    end
  else
    col = win_pos[2] + math.floor((win_width - config.width) / 2)
    row = win_pos[1] + math.floor((win_height - total_height) / 2)
  end

  local max_col = math.max(0, vim.o.columns - config.width)
  local max_row = math.max(0, vim.o.lines - total_height - 2)

  return {
    col = clamp(col, 0, max_col),
    row = clamp(row, 0, max_row),
    width = config.width,
    height = total_height,
  }
end

--------------------------------------------------------------------------------
-- input_window_spec(config, main_spec)
--
-- The popup uses two windows:
--   1. a shell window for header/footer chrome
--   2. a focused input window layered on top of the blank middle area
--
-- This helper translates the outer shell position into the inner input position.
--------------------------------------------------------------------------------
function M.input_window_spec(config, main_spec)
  return {
    col = main_spec.col + config.input_padding,
    row = main_spec.row + HEADER_HEIGHT + 1,
    width = math.max(1, config.width - config.input_padding),
    height = config.input_height,
  }
end

local function footer_status(phase)
  if phase == "requesting" then
    return "Thinking..."
  end

  if phase == "error" then
    return "Error"
  end

  return nil
end

local function mode_label(submit_mode)
  if submit_mode == "comment_now" then
    return {
      badge = " [comment now]",
      submit = "comment",
      highlight = "mode_comment",
      placeholder = "comment_placeholder",
    }
  end

  return {
    badge = " [answer]",
    submit = "answer",
    highlight = "mode_answer",
    placeholder = "placeholder",
  }
end

--------------------------------------------------------------------------------
-- build_chrome(config, model_name)
--
-- Returns the visible text for the chrome buffer plus highlight spans.
--
-- Why include spans here?
-- The same module that builds the text already knows where each semantic segment
-- begins and ends. That makes layout.lua the best place to describe highlight
-- ranges, while render.lua stays focused on applying them.
--------------------------------------------------------------------------------
function M.build_chrome(config, model_name, phase, submit_mode)
  local mode = mode_label(submit_mode)
  local header = {
    title = " Claude",
    badge = mode.badge,
    close = config.icons.close .. " ",
  }

  local header_used_width = vim.fn.strdisplaywidth(header.title .. header.badge .. header.close)
  header.padding = string.rep(" ", math.max(1, config.width - header_used_width))
  header.text = header.title .. header.badge .. header.padding .. header.close

  local status = footer_status(phase)

  local footer = {
    model = " " .. model_name .. " " .. config.icons.model_arrow,
    tab = "  " .. config.icons.tab_hint,
    toggle = "  F2",
    right = status and (status .. " ") or (config.icons.enter_hint .. "  " .. mode.submit .. " "),
  }

  local left_footer = footer.model .. footer.tab .. footer.toggle
  local used_width = vim.fn.strdisplaywidth(left_footer) + vim.fn.strdisplaywidth(footer.right)
  footer.padding = string.rep(" ", math.max(1, config.width - used_width))
  footer.text = left_footer .. footer.padding .. footer.right

  local lines = { header.text }
  for _ = 1, config.input_height do
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = footer.text

  local footer_line = HEADER_HEIGHT + config.input_height
  local footer_prefix = left_footer .. footer.padding
  local right_start = #footer_prefix
  local right_end = #footer.text
  local enter_start = right_start
  local enter_end = math.min(right_end, enter_start + #config.icons.enter_hint)
  local send_start = math.min(right_end, enter_end + #"  ")
  local send_end = right_end
  local title_end = #header.title
  local badge_end = #(header.title .. header.badge)
  local close_start = #(header.title .. header.badge .. header.padding)
  local toggle_end = #(footer.model .. footer.tab .. footer.toggle)

  local result = {
    lines = lines,
    spans = {
      {
        line = 0,
        start_col = 0,
        end_col = title_end,
        hl_group = config.highlights.title,
      },
      {
        line = 0,
        start_col = title_end,
        end_col = badge_end,
        hl_group = config.highlights[mode.highlight],
      },
      {
        line = 0,
        start_col = close_start,
        end_col = #header.text,
        hl_group = config.highlights.subtle,
      },
      {
        line = footer_line,
        start_col = 0,
        end_col = #footer.model,
        hl_group = config.highlights.subtle,
      },
      {
        line = footer_line,
        start_col = #footer.model,
        end_col = toggle_end,
        hl_group = config.highlights.subtle,
      },
    },
  }

  if status then
    result.spans[#result.spans + 1] = {
      line = footer_line,
      start_col = right_start,
      end_col = right_end,
      hl_group = config.highlights.subtle,
    }
  else
    result.spans[#result.spans + 1] = {
      line = footer_line,
      start_col = enter_start,
      end_col = enter_end,
      hl_group = config.highlights.subtle,
    }

    result.spans[#result.spans + 1] = {
      line = footer_line,
      start_col = send_start,
      end_col = send_end,
      hl_group = config.highlights[mode.highlight],
    }
  end

  return result
end

--------------------------------------------------------------------------------
-- build_placeholder(config, context, file_label)
--
-- Returns the overlay text shown in the input buffer when it is empty.
--
-- This function is pure string formatting. input.lua decides when to show or
-- hide the placeholder, but layout.lua owns the wording.
--------------------------------------------------------------------------------
function M.build_placeholder(config, context, file_label, submit_mode)
  local base = config[mode_label(submit_mode).placeholder]

  if context and context.selection and context.selection.lines then
    local noun = context.selection.lines == 1 and "line" or "lines"
    return string.format("%s (%d %s selected)", base, context.selection.lines, noun)
  end

  if file_label and file_label ~= "" then
    return string.format("%s (%s)", base, file_label)
  end

  return base
end

return M
