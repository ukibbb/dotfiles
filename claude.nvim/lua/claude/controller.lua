--------------------------------------------------------------------------------
-- claude.controller
--
-- This module orchestrates the popup lifecycle.
--
-- Owns:
--   - Opening and closing the popup
--   - Translating editor state into a new session
--   - Wiring input actions to rendering and teardown
--   - Handling submit, backend execution, and answer persistence
--
-- Does NOT own:
--   - Public setup() API
--   - Config defaults
--   - Low-level rendering details
--
-- Mental model:
-- init.lua is the public front door.
-- controller.lua is the traffic cop.
-- It coordinates context.lua, state.lua, render.lua, input.lua, backend.lua,
-- output.lua, and comments.lua.
--------------------------------------------------------------------------------

local backend = require("claude.backend")
local comments = require("claude.comments")
local context = require("claude.context")
local input = require("claude.input")
local output = require("claude.output")
local render = require("claude.render")
local state = require("claude.state")

local M = {}

local function leave_visual_mode_if_needed()
  if not context.is_visual_mode() then
    return false
  end

  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
  return true
end

local function cancel_request(session)
  if session and session.request and session.request.handle then
    backend.cancel(session.request.handle)
  end

  state.clear_request(session)
end

local function teardown_current_session()
  local session = state.get()

  if not session then
    return
  end

  cancel_request(session)
  render.close(session)
  state.clear()
end

local function install_autoclose(session)
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = session.handles.input_buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if state.get() == session then
          M.close()
        end
      end)
    end,
  })
end

local function redraw_session(session, config)
  if state.get() == session then
    render.redraw(session, config)
  end
end

local function finish_open(session, config)
  if state.get() ~= session then
    return
  end

  render.setup_highlights(config)
  render.create(session, config)

  input.attach(session, config, {
    close = M.close,
    cancel = function()
      if state.is_busy(session) then
        M.cancel(config)
      else
        M.close()
      end
    end,
    submit = function()
      M.submit(config)
    end,
    redraw = function()
      redraw_session(session, config)
    end,
    toggle_mode = function()
      M.toggle_mode(config)
    end,
  })

  install_autoclose(session)
  input.enter_insert_mode(session)
end

local function open_record(record, config)
  output.open_record(record, config, {
    comment = function(selected_record)
      M.comment_record(selected_record, config)
    end,
  })
end

local function build_record(session, config, question, response)
  return {
    id = tostring(vim.uv.hrtime()),
    question = question,
    answer = response.answer or "",
    comment_candidate = response.comment_candidate or {},
    consulted_files = response.consulted_files or {},
    context = vim.deepcopy(session.context),
    model = state.current_model_name(session, config),
    submit_mode = session.submit_mode,
    timestamp = os.date("!%Y-%m-%d %H:%M:%S UTC"),
  }
end

--------------------------------------------------------------------------------
-- open(config, opts)
--
-- Opens the popup or toggles it closed if already open.
--
-- The order matters:
--   1. capture selection while it still exists
--   2. create a new session object
--   3. leave visual mode if needed
--   4. finish opening and install input behavior
--------------------------------------------------------------------------------
function M.open(config, opts)
  opts = opts or {}

  if state.is_open() then
    M.close()
    return
  end

  if state.get() then
    teardown_current_session()
  end

  local session = state.new(context.capture(), opts)
  local left_visual_mode = leave_visual_mode_if_needed()

  state.set(session)

  if left_visual_mode then
    vim.schedule(function()
      finish_open(session, config)
    end)
  else
    finish_open(session, config)
  end
end

function M.open_comment_now(config)
  M.open(config, { submit_mode = "comment_now" })
end

function M.close()
  teardown_current_session()
end

--------------------------------------------------------------------------------
-- cancel(config)
--
-- Cancels the active backend request but keeps the popup open.
--
-- This is separate from close() because users may want to stop a slow request and
-- immediately revise the prompt without destroying the popup state.
--------------------------------------------------------------------------------
function M.cancel(config)
  local session = state.get()

  if not session or not state.is_busy(session) then
    return
  end

  cancel_request(session)
  state.set_phase(session, "idle")
  redraw_session(session, config)
  vim.notify("Claude request cancelled", vim.log.levels.INFO, { title = "claude.nvim" })
end

--------------------------------------------------------------------------------
-- toggle_mode(config)
--
-- Switches the currently open popup between answer mode and comment-now mode.
--
-- This is intentionally a controller action instead of an input action because
-- changing submit mode alters application behavior, not just local keybindings.
--------------------------------------------------------------------------------
function M.toggle_mode(config)
  local session = state.get()

  if not session or state.is_busy(session) then
    return false
  end

  local mode = state.toggle_submit_mode(session)
  redraw_session(session, config)

  return mode
end

--------------------------------------------------------------------------------
-- comment_record(record, config)
--
-- Inserts a stored answer into the source file as comments.
--
-- This is the "answer now, comment later" path. The answer is first reviewed in
-- a scratch buffer, and only on explicit user action do we attempt a safe file
-- write. The write happens on disk so watchdiff.nvim can surface it as an
-- external change if that plugin is active.
--------------------------------------------------------------------------------
function M.comment_record(record, config)
  local ok, err = comments.insert(record, config)

  if ok then
    vim.notify(
      string.format(
        "Inserted Claude comments into %s. Use :WatchDiffHistory to review provenance.",
        record.context.file_label or "the source file"
      ),
      vim.log.levels.INFO,
      { title = "claude.nvim" }
    )
    return true
  end

  vim.notify(err, vim.log.levels.WARN, { title = "claude.nvim" })
  return false
end

function M.comment_last_answer(config)
  local record = state.get_last_record()

  if not record then
    vim.notify("No Claude answer is available to turn into comments yet", vim.log.levels.INFO, { title = "claude.nvim" })
    return false
  end

  return M.comment_record(record, config)
end

--------------------------------------------------------------------------------
-- submit(config)
--
-- Sends the prompt to the backend, stores the response, and then routes the
-- result according to the session's submit mode:
--   - answer       -> open scratch review buffer
--   - comment_now  -> attempt immediate comment insertion, then fall back to the
--                     scratch review buffer if insertion is unsafe
--------------------------------------------------------------------------------
function M.submit(config)
  local session = state.get()

  if not session or state.is_busy(session) then
    return
  end

  local question = vim.trim(input.get_text(session))
  if question == "" then
    vim.notify("Type a question before submitting", vim.log.levels.INFO, { title = "claude.nvim" })
    return
  end

  if session.context.source_buf
    and vim.api.nvim_buf_is_valid(session.context.source_buf)
    and vim.bo[session.context.source_buf].modified
    and (session.submit_mode == "comment_now" or not session.context.selection)
  then
    vim.notify(
      session.submit_mode == "comment_now"
          and "Save or discard the current file before using comment-now mode; Claude needs a stable file to annotate"
        or "Save the current file or select code before asking Claude; the backend can only inspect saved files",
      vim.log.levels.WARN,
      { title = "claude.nvim" }
    )
    return
  end

  state.set_phase(session, "requesting")
  state.clear_request(session)
  redraw_session(session, config)

  local handle = backend.start(question, session, config, {
    on_success = function(response)
      if state.get() ~= session then
        return
      end

      local record = build_record(session, config, question, response)
      state.set_last_record(record)
      state.set_phase(session, "done")
      state.clear_request(session)

      M.close()

      if session.submit_mode == "comment_now" then
        if not M.comment_record(record, config) then
          open_record(record, config)
        end
      else
        open_record(record, config)
      end
    end,
    on_error = function(err)
      if state.get() ~= session then
        return
      end

      state.clear_request(session)
      state.set_phase(session, "error", err)
      redraw_session(session, config)
      vim.notify(err, vim.log.levels.ERROR, { title = "claude.nvim" })
    end,
  })

  state.set_request(session, {
    handle = handle,
    question = question,
  })
end

return M
