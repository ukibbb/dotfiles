--------------------------------------------------------------------------------
-- Claude.nvim GUI Module
-- Clean popup interface inspired by Cursor
--------------------------------------------------------------------------------
local M = {}

-- Module state
M.current_model = 1

--------------------------------------------------------------------------------
-- VISUAL DEFINITIONS
-- All visual constants: dimensions, spacing, text, icons
--------------------------------------------------------------------------------
local visual = {
  -- Layout dimensions
  header_height = 1,
  footer_height = 1,
  input_padding = 2,      -- horizontal padding inside input area
  margin = 2,             -- margin from buffer edge when positioned with selection

  -- Border style
  border_style = "rounded",

  -- Text content
  placeholder = "Type your question...",
  close_icon = "✕",
  send_icon = "󰒊",
  model_arrow = "▾",
  tab_hint = "⇥",
  enter_hint = "↵",

  -- Models
  models = { "opus 4.5", "sonnet", "haiku" },

  -- Highlight groups (linked in setup_highlights)
  highlights = {
    subtle = "ClaudeSubtle",
    icon = "ClaudeIcon",
    border = "ClaudeBorder",
  },

  -- Highlight group links (theme-aware)
  highlight_links = {
    ClaudeSubtle = "Comment",
    ClaudeIcon = "Special",
    ClaudeBorder = "FloatBorder",
  },
}

--------------------------------------------------------------------------------
-- SETUP
-- Initialize highlight groups
--------------------------------------------------------------------------------
function M.setup_highlights()
  for group, link in pairs(visual.highlight_links) do
    vim.api.nvim_set_hl(0, group, { link = link })
  end
end

--------------------------------------------------------------------------------
-- MODEL CYCLING
-- Cycle through available models
--------------------------------------------------------------------------------
function M.get_current_model()
  return visual.models[M.current_model]
end

function M.cycle_model(buf)
  M.current_model = M.current_model % #visual.models + 1
  if buf and vim.api.nvim_buf_is_valid(buf) then
    -- Redraw footer by rebuilding content
    local state = require("volt.state")
    if state[buf] then
      require("volt").redraw(buf, "footer")
    end
  end
end

--------------------------------------------------------------------------------
-- POSITIONING
-- Calculate popup position based on context
--------------------------------------------------------------------------------
local function calculate_position(config, context)
  local w = config.width
  local total_h = visual.header_height + config.input_height + visual.footer_height

  local col, row

  if context and context.start_line then
    -- With selection: left side of buffer, bottom border one line above selection
    local win_pos = vim.api.nvim_win_get_position(0)
    local first_visible_line = vim.fn.line('w0')

    -- Horizontally: left of buffer + margin
    col = win_pos[2] + visual.margin

    -- Convert buffer line to screen position
    local screen_line = context.start_line - first_visible_line

    -- Vertically: bottom border two lines above first highlighted line
    row = win_pos[1] + screen_line - total_h - 2

    -- If not enough space above, position below the selection
    if row < 0 then
      local end_screen_line = context.end_line - first_visible_line
      row = win_pos[1] + end_screen_line + 2
    end
  else
    -- No selection: center of buffer
    local win_height = vim.api.nvim_win_get_height(0)
    local win_width = vim.api.nvim_win_get_width(0)
    local win_pos = vim.api.nvim_win_get_position(0)

    col = win_pos[2] + math.floor((win_width - w) / 2)
    row = win_pos[1] + math.floor((win_height - total_h) / 2)

    -- Keep on screen
    if col < 0 then col = 0 end
    if row < 0 then row = 0 end
  end

  return col, row, total_h
end

--------------------------------------------------------------------------------
-- CONTENT BUILDING
-- Build text content for the popup
--------------------------------------------------------------------------------
local function build_content(config, context)
  local w = config.width
  local lines = {}

  -- Header line: just close button on right
  local header_right = visual.close_icon .. " "
  local header_padding = w - vim.fn.strdisplaywidth(header_right)
  local header_text = string.rep(" ", header_padding) .. header_right
  table.insert(lines, header_text)

  -- Input area (empty lines, input happens in overlay window)
  for _ = 1, config.input_height do
    table.insert(lines, "")
  end

  -- Footer: model + tab hint ... enter hint + send icon
  local model_name = M.get_current_model()
  local footer_left = " " .. model_name .. " " .. visual.model_arrow .. "  " .. visual.tab_hint
  local footer_right = visual.enter_hint .. "  " .. visual.send_icon .. " "
  local footer_padding = w - vim.fn.strdisplaywidth(footer_left) - vim.fn.strdisplaywidth(footer_right)
  if footer_padding < 1 then footer_padding = 1 end
  local footer_text = footer_left .. string.rep(" ", footer_padding) .. footer_right
  table.insert(lines, footer_text)

  return lines, model_name
end

local function build_placeholder(context)
  local file = vim.fn.expand("%:t")
  if context and context.lines then
    -- Selection context
    return visual.placeholder .. " (" .. context.lines .. " lines selected)"
  elseif file ~= "" then
    -- File context
    return visual.placeholder .. " (" .. file .. ")"
  else
    return visual.placeholder
  end
end

--------------------------------------------------------------------------------
-- HIGHLIGHTING
-- Apply extmark highlights to content
--------------------------------------------------------------------------------
local function apply_highlights(buf, content_lines, config, model_name)
  local ns = vim.api.nvim_create_namespace("claude_main")

  -- Clear existing highlights before applying new ones
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  -- Close button (header line, right side)
  local close_start = #content_lines[1] - vim.fn.strdisplaywidth(visual.close_icon .. " ")
  vim.api.nvim_buf_set_extmark(buf, ns, 0, close_start, {
    end_col = #content_lines[1],
    hl_group = visual.highlights.subtle,
  })

  -- Footer line (last line)
  local footer_line = visual.header_height + config.input_height

  -- Model name + arrow (subtle)
  local model_section_end = vim.fn.strdisplaywidth(" " .. model_name .. " " .. visual.model_arrow)
  vim.api.nvim_buf_set_extmark(buf, ns, footer_line, 0, {
    end_col = model_section_end,
    hl_group = visual.highlights.subtle,
  })

  -- Tab hint (subtle)
  local tab_start = model_section_end + 2  -- after two spaces
  local tab_end = tab_start + vim.fn.strdisplaywidth(visual.tab_hint)
  vim.api.nvim_buf_set_extmark(buf, ns, footer_line, tab_start, {
    end_col = tab_end,
    hl_group = visual.highlights.subtle,
  })

  -- Enter hint (subtle)
  local footer_right = visual.enter_hint .. "  " .. visual.send_icon .. " "
  local enter_start = #content_lines[#content_lines] - vim.fn.strdisplaywidth(footer_right)
  local enter_end = enter_start + vim.fn.strdisplaywidth(visual.enter_hint)
  vim.api.nvim_buf_set_extmark(buf, ns, footer_line, enter_start, {
    end_col = enter_end,
    hl_group = visual.highlights.subtle,
  })

  -- Send icon (Special highlight)
  local send_start = #content_lines[#content_lines] - vim.fn.strdisplaywidth(visual.send_icon .. " ")
  vim.api.nvim_buf_set_extmark(buf, ns, footer_line, send_start, {
    end_col = #content_lines[#content_lines],
    hl_group = visual.highlights.icon,
  })
end

--------------------------------------------------------------------------------
-- BEHAVIOR
-- Setup autocmds and interactivity
--------------------------------------------------------------------------------
local function setup_placeholder_behavior(input_buf, context)
  local placeholder_ns = vim.api.nvim_create_namespace("claude_placeholder")
  local placeholder_text = build_placeholder(context)

  -- Initial placeholder
  vim.api.nvim_buf_set_extmark(input_buf, placeholder_ns, 0, 0, {
    virt_text = { { placeholder_text, visual.highlights.subtle } },
    virt_text_pos = "overlay",
  })

  -- Toggle placeholder visibility based on content
  vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged", "TextChangedI" }, {
    buffer = input_buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
      local content = table.concat(lines, "")

      if content ~= "" then
        vim.api.nvim_buf_clear_namespace(input_buf, placeholder_ns, 0, -1)
      else
        vim.api.nvim_buf_set_extmark(input_buf, placeholder_ns, 0, 0, {
          virt_text = { { placeholder_text, visual.highlights.subtle } },
          virt_text_pos = "overlay",
        })
      end
    end,
  })
end

--------------------------------------------------------------------------------
-- RENDERING
-- Create and configure windows
--------------------------------------------------------------------------------
function M.create_windows(config, context, ns)
  local w = config.width
  local input_h = config.input_height
  local col, row, total_h = calculate_position(config, context)

  local handles = {}

  -- Main window (contains header and footer)
  handles.main_buf = vim.api.nvim_create_buf(false, true)
  handles.main_win = vim.api.nvim_open_win(handles.main_buf, false, {
    relative = "editor",
    width = w,
    height = total_h,
    col = col,
    row = row,
    style = "minimal",
    border = visual.border_style,
  })
  vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat,FloatBorder:" .. visual.highlights.border, { win = handles.main_win })

  -- Build and set content
  local content_lines, model_name = build_content(config, context)
  vim.api.nvim_buf_set_lines(handles.main_buf, 0, -1, false, content_lines)

  -- Apply highlights
  apply_highlights(handles.main_buf, content_lines, config, model_name)

  -- Input window (overlays the input area)
  handles.input_buf = vim.api.nvim_create_buf(false, true)
  handles.input_win = vim.api.nvim_open_win(handles.input_buf, true, {
    relative = "editor",
    width = w - visual.input_padding,
    height = input_h,
    col = col + visual.input_padding,
    row = row + visual.header_height + 1,  -- +1 for border
    style = "minimal",
    border = "none",
  })
  vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat", { win = handles.input_win })
  vim.api.nvim_buf_set_lines(handles.input_buf, 0, -1, false, { "" })

  -- Setup behavior
  setup_placeholder_behavior(handles.input_buf, context)

  -- Setup buffer-local keymaps for model cycling
  local function cycle_and_redraw()
    M.current_model = M.current_model % #visual.models + 1
    -- Rebuild content and redraw
    local new_content, new_model = build_content(config, context)
    vim.api.nvim_buf_set_lines(handles.main_buf, 0, -1, false, new_content)
    apply_highlights(handles.main_buf, new_content, config, new_model)
  end

  vim.keymap.set("i", "<Tab>", cycle_and_redraw, { buffer = handles.input_buf, silent = true })
  vim.keymap.set("n", "<Tab>", cycle_and_redraw, { buffer = handles.input_buf, silent = true })

  -- Store references for compatibility
  handles.header_buf = handles.main_buf
  handles.header_win = handles.main_win
  handles.footer_buf = handles.main_buf
  handles.footer_win = handles.main_win

  return handles
end

--------------------------------------------------------------------------------
-- CLEANUP
-- Close windows and delete buffers
--------------------------------------------------------------------------------
function M.close_windows(handles)
  local windows = { handles.main_win, handles.input_win }
  for _, window in ipairs(windows) do
    if window and vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
  end

  local buffers = { handles.main_buf, handles.input_buf }
  for _, buf in ipairs(buffers) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

return M
