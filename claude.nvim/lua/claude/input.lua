--------------------------------------------------------------------------------
-- claude.input
--
-- This module owns behavior attached to the popup's input buffer.
--
-- Owns:
--   - Buffer-local keymaps for submit, close, clear, and model cycling
--   - Placeholder extmarks for the input buffer
--   - Entering insert mode once the popup is ready
--   - Reading the current prompt text from the input buffer
--
-- Does NOT own:
--   - Creating windows
--   - Closing popup resources
--   - Capturing visual selections
--
-- Mental model:
-- controller.lua decides which actions should happen.
-- input.lua binds those actions to keys inside the input buffer.
--------------------------------------------------------------------------------

local layout = require("claude.layout")
local render = require("claude.render")
local state = require("claude.state")

local M = {}

local function insert_newline(session)
  if not session or not session.handles then
    return
  end

  local win = session.handles.input_win
  local buf = session.handles.input_buf
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row = cursor[1] - 1
  local col = cursor[2]

  vim.api.nvim_buf_set_text(buf, row, col, row, col, { "", "" })
  vim.api.nvim_win_set_cursor(win, { cursor[1] + 1, 0 })
end

function M.get_text(session)
  if not session or not session.handles or not vim.api.nvim_buf_is_valid(session.handles.input_buf) then
    return ""
  end

  local lines = vim.api.nvim_buf_get_lines(session.handles.input_buf, 0, -1, false)
  return table.concat(lines, "\n")
end

local function render_placeholder(session, config)
  if not session or not session.handles or not vim.api.nvim_buf_is_valid(session.handles.input_buf) then
    return
  end

  session.namespaces.placeholder = session.namespaces.placeholder
    or vim.api.nvim_create_namespace("claude_placeholder")

  local buf = session.handles.input_buf
  local placeholder = layout.build_placeholder(
    config,
    session.context,
    session.context.file_label,
    session.submit_mode
  )
  local has_text = M.get_text(session) ~= ""

  vim.api.nvim_buf_clear_namespace(buf, session.namespaces.placeholder, 0, -1)

  if has_text then
    return
  end

  vim.api.nvim_buf_set_extmark(buf, session.namespaces.placeholder, 0, 0, {
    virt_text = { { placeholder, config.highlights.subtle } },
    virt_text_pos = "overlay",
  })
end

--------------------------------------------------------------------------------
-- clear(session, config)
--
-- Resets the editable prompt buffer to one empty line and redraws the
-- placeholder, because the placeholder is a view concern attached to emptiness.
--------------------------------------------------------------------------------
function M.clear(session, config)
  if not session or not session.handles or not vim.api.nvim_buf_is_valid(session.handles.input_buf) then
    return
  end

  vim.api.nvim_buf_set_lines(session.handles.input_buf, 0, -1, false, { "" })
  render_placeholder(session, config)
end

--------------------------------------------------------------------------------
-- refresh(session, config)
--
-- Re-renders input-only UI state, currently the placeholder overlay.
--
-- We call this after mode switches because the placeholder text changes between
-- answer mode and comment-now mode even when the actual buffer text does not.
--------------------------------------------------------------------------------
function M.refresh(session, config)
  render_placeholder(session, config)
end

--------------------------------------------------------------------------------
-- enter_insert_mode(session)
--
-- Schedules focus and insert-mode entry on the next event loop tick.
--
-- Why schedule this?
-- Opening floats and leaving visual mode can both enqueue editor state changes.
-- Scheduling the focus/insert step ensures it runs after those changes settle,
-- which makes "popup opens directly in insert mode" more reliable.
--------------------------------------------------------------------------------
function M.enter_insert_mode(session)
  vim.schedule(function()
    if not state.is_open(session) then
      return
    end

    render.focus_input(session)
    vim.cmd("startinsert")
  end)
end

local function cycle_model(session, config, redraw)
  if state.is_busy(session) then
    return
  end

  state.advance_model(session, config)

  if redraw then
    redraw()
  end
end

local function toggle_mode(session, config, actions)
  if state.is_busy(session) then
    return
  end

  if actions.toggle_mode then
    actions.toggle_mode()
  end

  M.refresh(session, config)
end

--------------------------------------------------------------------------------
-- attach(session, config, actions)
--
-- Installs all input-buffer behavior in one place.
--
-- actions is injected by controller.lua and contains the higher-level behavior:
--   - actions.submit()
--   - actions.close()
--   - actions.redraw()
--   - actions.toggle_mode()
--
-- This split is the main separation-of-concerns win in the refactor:
-- input.lua binds keys, but controller.lua decides what those keys mean.
--------------------------------------------------------------------------------
function M.attach(session, config, actions)
  local buf = session.handles.input_buf
  local opts = { buffer = buf, silent = true }

  render_placeholder(session, config)

  vim.keymap.set("i", "<CR>", actions.submit, opts)
  vim.keymap.set("n", "<CR>", actions.submit, opts)
  vim.keymap.set("i", "<C-j>", function()
    insert_newline(session)
  end, opts)

  vim.keymap.set("n", "q", actions.close, opts)
  vim.keymap.set("n", "<Esc>", actions.close, opts)
  vim.keymap.set("i", "<Esc>", actions.close, opts)
  vim.keymap.set("i", "<C-c>", actions.cancel, opts)

  vim.keymap.set("i", "<C-l>", function()
    M.clear(session, config)
  end, opts)

  vim.keymap.set("i", "<Tab>", function()
    cycle_model(session, config, actions.redraw)
  end, opts)

  vim.keymap.set("n", "<Tab>", function()
    cycle_model(session, config, actions.redraw)
  end, opts)

  vim.keymap.set("i", "<F2>", function()
    toggle_mode(session, config, actions)
  end, opts)

  vim.keymap.set("n", "<F2>", function()
    toggle_mode(session, config, actions)
  end, opts)

  vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = function()
      render_placeholder(session, config)
    end,
  })
end

return M
