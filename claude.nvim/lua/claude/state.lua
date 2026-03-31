--------------------------------------------------------------------------------
-- claude.state
--
-- This module owns runtime state for the currently open popup session.
--
-- Owns:
--   - The current popup session
--   - Per-session data such as handles, context, and selected model
--
-- Does NOT own:
--   - Window creation logic
--   - Input keymaps
--   - Configuration defaults
--
-- Mental model:
-- The plugin supports one popup at a time. That means we do not need a complex
-- state manager. We just keep a single "current session" table and helper
-- functions that make that choice explicit.
--------------------------------------------------------------------------------

local M = {}

local current_session = nil
local last_record = nil

--------------------------------------------------------------------------------
-- new(context, opts)
--
-- Creates a fresh session object for one popup lifetime.
--
-- Each session stores only runtime data that should disappear when the popup is
-- closed. Configuration is not stored here on purpose; configuration belongs to
-- claude.config and is passed in from the outside.
--------------------------------------------------------------------------------
function M.new(context, opts)
  opts = opts or {}

  return {
    context = context,
    handles = nil,
    model_index = 1,
    namespaces = {},
    phase = "idle",
    last_error = nil,
    request = nil,
    submit_mode = opts.submit_mode or "answer",
  }
end

function M.set(session)
  current_session = session
end

function M.get()
  return current_session
end

function M.clear()
  current_session = nil
end

function M.set_phase(session, phase, err)
  if not session then
    return
  end

  session.phase = phase
  session.last_error = err
end

function M.is_busy(session)
  session = session or current_session

  return session and (session.phase == "requesting" or session.phase == "streaming") or false
end

function M.set_request(session, request)
  if session then
    session.request = request
  end
end

function M.clear_request(session)
  if session then
    session.request = nil
  end
end

--------------------------------------------------------------------------------
-- is_open(session)
--
-- Returns true when a popup has a live input window.
--
-- The input window is the best signal for "is the popup usable right now?"
-- because that window is where the user types and where focus should land.
--------------------------------------------------------------------------------
function M.is_open(session)
  session = session or current_session

  return session
    and session.handles
    and session.handles.input_win
    and vim.api.nvim_win_is_valid(session.handles.input_win)
    or false
end

function M.current_model_name(session, config)
  return config.models[session.model_index]
end

--------------------------------------------------------------------------------
-- advance_model(session, config)
--
-- Rotates through the configured models and returns the newly selected name.
--
-- This logic lives in state.lua because "which model is selected right now" is
-- runtime state, not rendering logic. render.lua only asks what to draw.
--------------------------------------------------------------------------------
function M.advance_model(session, config)
  session.model_index = session.model_index % #config.models + 1
  return M.current_model_name(session, config)
end

function M.mode_label(session)
  if session and session.submit_mode == "comment_now" then
    return "comments"
  end

  return "answer"
end

--------------------------------------------------------------------------------
-- toggle_submit_mode(session)
--
-- Switches the popup between normal answer mode and immediate comment-now mode.
--
-- Keeping this here makes the mode transition explicit and centralized. The UI
-- asks state.lua which mode is active; it should also ask state.lua to change it.
--------------------------------------------------------------------------------
function M.toggle_submit_mode(session)
  if not session then
    return "answer"
  end

  session.submit_mode = session.submit_mode == "comment_now" and "answer" or "comment_now"
  return session.submit_mode
end

--------------------------------------------------------------------------------
-- set_last_record(record)
--
-- Persists the most recent successful answer outside the popup session.
--
-- Why keep this separately from current_session?
-- The popup can close after a response arrives, but the user may still want to
-- reopen the answer or insert it into the source file as comments later.
--------------------------------------------------------------------------------
function M.set_last_record(record)
  last_record = record
end

function M.get_last_record()
  return last_record
end

return M
