--------------------------------------------------------------------------------
-- claude.request
--
-- This module builds the structured request that is sent to the backend CLI.
--
-- Owns:
--   - The answer schema we expect back from the backend
--   - The prompt text that explains the task and the available anchor context
--
-- Does NOT own:
--   - Running the backend command
--   - Parsing Neovim editor state directly
--   - Rendering answers
--
-- Why this separation matters:
-- backend.lua should worry about processes and callbacks, not prompt wording.
-- request.lua keeps the "what are we asking Claude to do?" logic in one place.
--------------------------------------------------------------------------------

local M = {}

local RESPONSE_SCHEMA = {
  type = "object",
  additionalProperties = false,
  required = { "answer", "comment_candidate", "consulted_files" },
  properties = {
    answer = { type = "string" },
    comment_candidate = {
      type = "array",
      items = { type = "string" },
    },
    consulted_files = {
      type = "array",
      items = { type = "string" },
    },
  },
}

function M.response_schema()
  return vim.deepcopy(RESPONSE_SCHEMA)
end

function M.response_schema_json()
  return vim.json.encode(M.response_schema())
end

local function append_section(lines, title, value)
  if not value or value == "" then
    return
  end

  lines[#lines + 1] = title
  lines[#lines + 1] = value
  lines[#lines + 1] = ""
end

function M.build_prompt(question, context, config, submit_mode)
  local lines = {
    "You are helping a developer understand code inside a repository.",
    "Start from the provided anchor context and only inspect more files if you need them to answer accurately.",
    "Do not edit files.",
    "Ground the answer in code you actually inspected.",
    "Return data that matches the provided JSON schema.",
    string.format(
      "If inline comments would make sense, set comment_candidate to 1-%d short plain-text lines without comment markers.",
      config.comments.max_lines
    ),
    "If inline comments would be unsafe or awkward, return an empty comment_candidate array.",
    "consulted_files must contain repo-relative paths for files you actually used in the answer.",
    "",
    "Anchor context:",
    string.format("- Mode: %s", context.kind),
    string.format("- Repository root: %s", context.repo_root or vim.uv.cwd()),
    string.format("- Current file: %s", context.relative_path or context.file_label),
    string.format("- Cursor: line %d, column %d", context.cursor_line or 1, context.cursor_col or 1),
  }

  if submit_mode == "comment_now" then
    lines[#lines + 1] = "- Requested output mode: insert explanatory comments into the current file now"
    lines[#lines + 1] = "- Make comment_candidate useful and concise if inline comments are safe"
  else
    lines[#lines + 1] = "- Requested output mode: answer first, let the user decide later whether to insert comments"
  end

  if context.selection then
    lines[#lines + 1] = string.format(
      "- Selected lines: %d-%d",
      context.selection.start_line,
      context.selection.end_line
    )
  end

  lines[#lines + 1] = ""

  if context.selection and context.selection.text ~= "" then
    append_section(lines, "Selected code:", context.selection.text)
  end

  append_section(lines, "User question:", question)

  return table.concat(lines, "\n")
end

return M
