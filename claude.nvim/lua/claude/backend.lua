--------------------------------------------------------------------------------
-- claude.backend
--
-- This module owns the async request to the external Claude backend.
--
-- Owns:
--   - Building the backend command line
--   - Starting and cancelling the async process
--   - Parsing the backend's structured JSON response
--
-- Does NOT own:
--   - Neovim popup state
--   - Where answers are rendered
--   - Comment insertion
--
-- Why this file exists:
-- controller.lua should be able to say "ask Claude" without caring whether that
-- means running `claude -p`, a test stub, or a future different transport.
--------------------------------------------------------------------------------

local request = require("claude.request")
local state = require("claude.state")

local M = {}

local function normalize_payload(decoded)
  decoded.answer = vim.trim(decoded.answer or "")
  decoded.comment_candidate = type(decoded.comment_candidate) == "table" and decoded.comment_candidate or {}
  decoded.consulted_files = type(decoded.consulted_files) == "table" and decoded.consulted_files or {}
  return decoded
end

local function normalize_response(stdout)
  local ok, decoded = pcall(vim.json.decode, stdout)

  if ok and type(decoded) == "table" then
    if type(decoded.structured_output) == "table" then
      return normalize_payload(decoded.structured_output)
    end

    if decoded.answer ~= nil or decoded.comment_candidate ~= nil or decoded.consulted_files ~= nil then
      return normalize_payload(decoded)
    end
  end

  return {
    answer = vim.trim(stdout or ""),
    comment_candidate = {},
    consulted_files = {},
  }
end

local function format_error(result)
  local stderr = vim.trim(result.stderr or "")
  local stdout = vim.trim(result.stdout or "")

  if stderr ~= "" then
    return stderr
  end

  if stdout ~= "" then
    return stdout
  end

  return string.format("Backend exited with code %s", tostring(result.code))
end

local function default_command(question, session, config)
  local model_name = state.current_model_name(session, config)
  local model_alias = config.backend.model_aliases[model_name] or model_name
  local cmd = { config.backend.command }

  vim.list_extend(cmd, config.backend.extra_args)

  cmd[#cmd + 1] = "--model"
  cmd[#cmd + 1] = model_alias
  cmd[#cmd + 1] = "--json-schema"
  cmd[#cmd + 1] = request.response_schema_json()
  cmd[#cmd + 1] = request.build_prompt(question, session.context, config, session.submit_mode)

  local opts = {
    cwd = session.context.repo_root,
    text = true,
  }

  if config.backend.env and next(config.backend.env) ~= nil then
    opts.env = config.backend.env
  end

  return cmd, opts
end

--------------------------------------------------------------------------------
-- start(question, session, config, callbacks)
--
-- Starts the external backend process.
--
-- The backend is configurable. By default we run the local `claude` CLI, but
-- tests can inject backend.build_command to return a fake command that prints a
-- canned JSON payload. That keeps the rest of the plugin testable even when the
-- real Claude CLI is unavailable or rate-limited.
--------------------------------------------------------------------------------
function M.start(question, session, config, callbacks)
  local cmd
  local opts

  if type(config.backend.build_command) == "function" then
    cmd, opts = config.backend.build_command(question, session, config, request)
  else
    cmd, opts = default_command(question, session, config)
  end

  local ok, handle = pcall(vim.system, cmd, opts or {}, function(result)
    vim.schedule(function()
      if result.code == 0 then
        callbacks.on_success(normalize_response(result.stdout or ""))
      else
        callbacks.on_error(format_error(result))
      end
    end)
  end)

  if not ok then
    callbacks.on_error(tostring(handle))
    return nil
  end

  return handle
end

function M.cancel(handle)
  if handle and handle.kill then
    pcall(handle.kill, handle, 15)
  end
end

return M
