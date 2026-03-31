--------------------------------------------------------------------------------
-- claude.render
--
-- This module translates layout data into real Neovim windows and buffers.
--
-- Owns:
--   - Creating popup buffers and floating windows
--   - Writing chrome text into the shell buffer
--   - Applying highlight spans
--   - Closing popup windows and deleting their buffers
--
-- Does NOT own:
--   - Input keymaps or placeholder behavior
--   - Selection capture
--   - Deciding when the popup should open or close
--
-- Mental model:
-- layout.lua returns a description of the UI.
-- render.lua performs the side effects needed to show that UI in Neovim.
--------------------------------------------------------------------------------

local layout = require("claude.layout")
local state = require("claude.state")

local M = {}

local function border_highlight(session, config)
  if session and session.submit_mode == "comment_now" then
    return config.highlights.mode_comment
  end

  return config.highlights.border
end

--------------------------------------------------------------------------------
-- setup_highlights(config)
--
-- Creates the plugin's highlight groups by linking them to existing groups from
-- the active colorscheme.
--
-- Because highlight creation is idempotent, the controller can safely call this
-- every time the popup opens.
--------------------------------------------------------------------------------
function M.setup_highlights(config)
  for group, link in pairs(config.highlight_links) do
    vim.api.nvim_set_hl(0, group, { link = link })
  end
end

local function apply_spans(buf, ns, spans)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for _, span in ipairs(spans) do
    vim.api.nvim_buf_set_extmark(buf, ns, span.line, span.start_col, {
      end_col = span.end_col,
      hl_group = span.hl_group,
    })
  end
end

--------------------------------------------------------------------------------
-- redraw(session, config)
--
-- Rebuilds the chrome buffer from the current session state.
--
-- The most common redraw trigger is model cycling. Instead of mutating only the
-- footer, we rebuild the whole shell text from one source of truth so the UI is
-- always derived from state, not patched in place.
--------------------------------------------------------------------------------
function M.redraw(session, config)
  if not session or not session.handles or not vim.api.nvim_buf_is_valid(session.handles.main_buf) then
    return
  end

  local chrome = layout.build_chrome(
    config,
    state.current_model_name(session, config),
    session.phase,
    session.submit_mode
  )
  session.namespaces.chrome = session.namespaces.chrome or vim.api.nvim_create_namespace("claude_chrome")

  vim.api.nvim_set_option_value("modifiable", true, { buf = session.handles.main_buf })
  vim.api.nvim_buf_set_lines(session.handles.main_buf, 0, -1, false, chrome.lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = session.handles.main_buf })
  apply_spans(session.handles.main_buf, session.namespaces.chrome, chrome.spans)
end

--------------------------------------------------------------------------------
-- create(session, config)
--
-- Creates the shell window and the focused input window.
--
-- The shell buffer is responsible for the decorative chrome (header/footer).
-- The input buffer is the real editable buffer layered on top of the empty
-- middle section.
--------------------------------------------------------------------------------
function M.create(session, config)
  local main_spec = layout.main_window_spec(config, session.context)
  local input_spec = layout.input_window_spec(config, main_spec)

  local handles = {
    main_buf = vim.api.nvim_create_buf(false, true),
    input_buf = vim.api.nvim_create_buf(false, true),
  }

  handles.main_win = vim.api.nvim_open_win(handles.main_buf, false, {
    relative = "editor",
    width = main_spec.width,
    height = main_spec.height,
    col = main_spec.col,
    row = main_spec.row,
    style = "minimal",
    border = config.border_style,
    focusable = false,
  })

  vim.api.nvim_set_option_value(
    "winhl",
    "Normal:NormalFloat,FloatBorder:" .. border_highlight(session, config),
    { win = handles.main_win }
  )

  handles.input_win = vim.api.nvim_open_win(handles.input_buf, true, {
    relative = "editor",
    width = input_spec.width,
    height = input_spec.height,
    col = input_spec.col,
    row = input_spec.row,
    style = "minimal",
    border = "none",
  })

  vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat", { win = handles.input_win })
  vim.api.nvim_buf_set_lines(handles.input_buf, 0, -1, false, { "" })

  session.handles = handles
  M.redraw(session, config)

  return handles
end

--------------------------------------------------------------------------------
-- focus_input(session)
--
-- Makes the popup's input window the current window again.
--
-- This is kept separate from create() because controller.lua and input.lua both
-- need a clear, named way to say "focus the editable part of the popup".
--------------------------------------------------------------------------------
function M.focus_input(session)
  if session and session.handles and session.handles.input_win and vim.api.nvim_win_is_valid(session.handles.input_win) then
    vim.api.nvim_set_current_win(session.handles.input_win)
  end
end

local function close_handles(handles)
  if not handles then
    return
  end

  for _, window in ipairs({ handles.main_win, handles.input_win }) do
    if window and vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
  end

  for _, buf in ipairs({ handles.main_buf, handles.input_buf }) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

--------------------------------------------------------------------------------
-- close(session)
--
-- Tears down the popup's Neovim resources.
--
-- controller.lua owns the overall lifecycle, but render.lua owns the concrete
-- resources that must be cleaned up.
--------------------------------------------------------------------------------
function M.close(session)
  if not session then
    return
  end

  close_handles(session.handles)
  session.handles = nil
end

return M
