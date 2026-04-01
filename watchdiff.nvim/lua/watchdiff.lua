-- watchdiff.nvim — See what changed in your files since you last looked.
--
-- Detects when external tools (Claude Code, Codex, etc.) modify files on disk.
-- Shows green highlights for added/changed lines, red virtual lines for deleted lines.
-- Highlights accumulate until you review and clear them.
--
-- This is TOOL-AGNOSTIC — works with any external program that writes to files.
--
-- HOW IT WORKS (big picture):
--   1. libuv's fs_event API watches the filesystem for changes (OS-level, very efficient)
--   2. When a file changes, we debounce (wait 200ms for rapid saves to settle)
--   3. We diff the file against what the user last "acknowledged" (saw/saved)
--   4. We apply green/red highlights to show what changed
--   5. Highlights ACCUMULATE until the user reviews and clears them with <leader>ch

local M = {}

-- Default configuration
local defaults = {
  highlights = {
    add = { bg = "#2d4f2d" },
    delete = { bg = "#4f2d2d" },
  },
  debounce_ms = 200,
  ignore_patterns = { "^%.git/", "%.swp$", "~$", "%.DS_Store$", "^4913$", "^%.next/", "^node_modules/" },
  track_unopened_files = false,
  history_limit = 50,
  keys = {
    clear = "<leader>ch",
    history = false,
  },
}

-- Active configuration (set during setup)
local config = {}

-- ═══════════════════════════════════════════════════════
-- STATE: Namespaces, state tables
-- ═══════════════════════════════════════════════════════

-- Namespaces group extmarks (highlights) together.
-- This lets us clear just OUR highlights without affecting other plugins (like gitsigns).
-- Think of it like a separate "layer" in a drawing app.
local external_change_ns = vim.api.nvim_create_namespace("watchdiff")

-- THE ACKNOWLEDGED CONTENT TABLE
-- Key = buffer number (integer), Value = array of line strings
--
-- Stores what the user has last "seen" for each buffer.
-- We always diff against THIS baseline, so changes accumulate across multiple edits:
--
--   Example timeline with two agents editing the same file:
--     1. User opens file (version A)    → acknowledged = A
--     2. Agent 1 edits → file is now B  → diff(A, B) = highlights agent 1's changes
--     3. Agent 2 edits → file is now C  → diff(A, C) = highlights BOTH agents' changes!
--     4. User presses <leader>ch        → acknowledged = C, highlights cleared
--     5. Agent 3 edits → file is now D  → diff(C, D) = only agent 3's changes
--
-- The baseline ONLY updates when:
--   - User opens a file (BufReadPost) — they see the file content
--   - User saves a file (BufWritePost) — they know what they saved
--   - User clears highlights (<leader>ch) — they've reviewed the changes
-- It does NOT update when an external edit is detected.
local acknowledged_content = {}

-- WATCHER STATE
-- The main watcher handle — watches CWD recursively
local watcher_handle = nil
local watcher_generation = 0

-- Debounce timers — one per file path.
-- Key = absolute path, Value = libuv timer handle
--
-- WHAT IS DEBOUNCING?
-- When a tool saves a file, the OS often fires MULTIPLE events rapidly
-- (e.g., "changed", "changed", "changed" within a few milliseconds).
-- We don't want to reload 3 times — that would be slow and flashy.
-- Instead, we WAIT 200ms after the LAST event before doing anything.
-- If another event comes in during the wait, we restart the 200ms countdown.
-- Result: rapid saves → only ONE reload after they stop.
local debounce_timers = {}

-- Flag to prevent double-processing.
-- When our fs_event handler calls :checktime, that can trigger FileChangedShellPost.
-- Without this flag, the same change would be processed TWICE.
-- We set it to true before :checktime and nil after, so FileChangedShellPost knows to skip.
local reloading = {}

-- Suppress baseline refresh while an external reload is in progress.
--
-- Why this exists:
-- BufReadPost fires both when the user opens a file and when Neovim reloads a file
-- from disk after an external change. We WANT BufReadPost to refresh the baseline
-- on first open, but we MUST NOT refresh it during an external reload or the
-- baseline would jump forward to the new content and the diff would appear empty.
local suppress_baseline_update = {}

-- Optional metadata about the NEXT externally observed change for a path.
-- This is how other plugins (like claude.nvim) can tell watchdiff:
--   "the next write to foo.lua is from Claude and is an inserted comment block".
local pending_annotations = {}

-- Recent change history by file path.
-- Clearing highlights updates the baseline, but history remains available so the
-- user can later inspect when/how a tool changed a file.
local change_history = {}

-- libuv handles can race with scheduled callbacks during restart/shutdown.
-- Keep stop/close idempotent so stale callbacks cannot double-close handles.
local function handle_is_closing(handle)
  if not handle then return true end
  local ok, is_closing = pcall(function()
    return handle:is_closing()
  end)
  return not ok or is_closing
end

local function safe_stop(handle)
  if handle_is_closing(handle) then return end
  pcall(function()
    handle:stop()
  end)
end

local function safe_close(handle)
  if handle_is_closing(handle) then return end
  pcall(function()
    handle:close()
  end)
end

local function normalize_path(path)
  if not path or path == "" then
    return nil
  end

  return vim.uv.fs_realpath(path) or path
end

local function display_path(path)
  local normalized = normalize_path(path) or path
  local cwd = vim.uv.cwd()

  if normalized and cwd and normalized:sub(1, #cwd) == cwd then
    return normalized:sub(#cwd + 2)
  end

  return normalized or "[unknown]"
end

local function get_pending_annotation(path)
  return pending_annotations[normalize_path(path)]
end

local function clear_pending_annotation(path)
  pending_annotations[normalize_path(path)] = nil
end

local function append_history_entry(path, added_count, deleted_count, annotation)
  local normalized = normalize_path(path)
  if not normalized then return nil end

  local history = change_history[normalized] or {}
  local entry = {
    timestamp = os.date("!%Y-%m-%d %H:%M:%S UTC"),
    path = normalized,
    display_path = display_path(normalized),
    source = annotation and annotation.source or "external",
    action = annotation and annotation.action or "modify",
    summary = annotation and annotation.summary or nil,
    meta = annotation and annotation.meta or nil,
    added = added_count,
    deleted = deleted_count,
  }

  table.insert(history, entry)

  while #history > config.history_limit do
    table.remove(history, 1)
  end

  change_history[normalized] = history
  return entry
end

local function notify_change(entry)
  if not entry then return end

  local prefix = entry.source ~= "external" and (entry.source .. " updated ") or "File reloaded: "
  local target = entry.source ~= "external" and entry.display_path or ""
  local summary = entry.summary and (" - " .. entry.summary) or ""

  vim.notify(
    string.format(
      "%s%s+%d/-%d lines. <leader>ch to clear highlights.%s",
      prefix,
      target ~= "" and (target .. " ") or "",
      entry.added,
      entry.deleted,
      summary
    ),
    vim.log.levels.WARN
  )
end

-- ═══════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════

-- Find the pixel width of the window displaying a given buffer.
-- We need this for deleted-line virtual text so the red background fills the full width.
--
-- WHY NOT JUST USE vim.api.nvim_win_get_width(0)?
-- Window 0 = "current window". But if the changed file is in a DIFFERENT split,
-- we'd measure the wrong window and the red background would be the wrong width.
local function get_buf_win_width(bufnr)
  -- Loop through ALL open windows to find one showing our buffer
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      return vim.api.nvim_win_get_width(win)
    end
  end
  -- Buffer not visible in any window (hidden buffer) — use terminal width as fallback
  return vim.o.columns
end

-- Find a loaded normal-file buffer for an absolute path.
-- Matches by realpath first to handle symlink/canonical path differences.
local function find_loaded_file_buffer(abs_path)
  local target_real = vim.uv.fs_realpath(abs_path) or abs_path

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" then
        local name_real = vim.uv.fs_realpath(name) or name
        if name_real == target_real or name == abs_path then
          return bufnr
        end
      end
    end
  end

  return -1
end

-- Get file contents from the last git commit.
-- Used as a baseline when an external tool modifies a file that ISN'T open in Neovim.
-- Returns nil if the file isn't tracked by git (brand new file).
local function git_head_contents(filepath)
  -- Step 1: Find the git repo root (e.g., "/Users/lukasz/Desktop/dotfiles")
  -- vim.fn.systemlist() runs a shell command and returns output as a list of lines
  local result = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })

  -- vim.v.shell_error is non-zero when the last shell command failed
  -- (maybe we're not in a git repo at all)
  if vim.v.shell_error ~= 0 or #result == 0 then return nil end

  local git_root = result[1]  -- First line of output = repo root path

  -- Step 2: Convert absolute path to relative (git needs relative paths)
  -- "/Users/.../dotfiles/nvim/init.lua" → "nvim/init.lua"
  local rel_path = filepath
  if filepath:sub(1, #git_root) == git_root then
    rel_path = filepath:sub(#git_root + 2)  -- +2 to skip the "/" separator
  end

  -- Step 3: Get file content from the latest commit
  -- "git show HEAD:path/to/file" prints the file as it was in the last commit
  local lines = vim.fn.systemlist({ "git", "show", "HEAD:" .. rel_path })
  if vim.v.shell_error ~= 0 then return nil end

  return lines
end

-- ═══════════════════════════════════════════════════════
-- DIFFING AND HIGHLIGHTING
-- ═══════════════════════════════════════════════════════

-- Compute diff between old and new content, then apply highlights to the buffer.
-- old_lines = what the user last acknowledged (their baseline)
-- new_lines = what's in the buffer now (after external edit)
-- abs_path  = file path used for history/provenance
local function highlight_external_changes(bufnr, old_lines, new_lines, abs_path)
  -- Clear our previous highlights and re-apply from scratch.
  -- This is correct because we always diff from the acknowledged baseline —
  -- the full diff naturally includes ALL changes since the user last reviewed.
  vim.api.nvim_buf_clear_namespace(bufnr, external_change_ns, 0, -1)

  -- Skip inline highlights for very large files to avoid freezing Neovim
  if #old_lines > 5000 or #new_lines > 5000 then
    return
  end

  -- vim.diff() takes strings, not tables — join lines with newlines
  -- The trailing "\n" is POSIX convention (files end with a newline)
  local old_text = table.concat(old_lines, "\n") .. "\n"
  local new_text = table.concat(new_lines, "\n") .. "\n"

  -- Compute the diff as a list of "hunks" (contiguous blocks of changes)
  -- Each hunk = {old_start, old_count, new_start, new_count}
  --   old_start: line number in old text where the change begins
  --   old_count: how many old lines are affected (0 = pure insertion)
  --   new_start: line number in new text where the change begins
  --   new_count: how many new lines are affected (0 = pure deletion)
  -- "histogram" algorithm gives better diffs than classic "myers" for code
  local diff = vim.diff(old_text, new_text, {
    result_type = "indices",
    algorithm = "histogram",
  })

  local added_count = 0
  local deleted_count = 0

  -- Use the correct window width (the window actually showing this buffer)
  local win_width = get_buf_win_width(bufnr)

  -- Process each hunk
  for _, hunk in ipairs(diff) do
    local old_start, old_count, new_start, new_count = unpack(hunk)

    -- ADDED/CHANGED LINES → green background
    -- These lines exist in the new version but not (or differently) in the old version
    for i = new_start, new_start + new_count - 1 do
      if i <= #new_lines then
        -- Extmarks are Neovim's way of attaching metadata to buffer positions.
        -- They "stick" to text — if you insert a line above, the extmark moves down.
        -- We use them for highlighting because they're efficient and auto-cleanup.
        vim.api.nvim_buf_set_extmark(bufnr, external_change_ns, i - 1, 0, {
          end_col = #new_lines[i],
          hl_group = "WatchDiffAdd",
          hl_eol = true,                        -- Color past end of text too
          line_hl_group = "WatchDiffAdd",        -- Also highlight the line number column
          priority = 100,                        -- Draw on top of other highlights
        })
        added_count = added_count + 1
      end
    end

    -- DELETED LINES → red virtual text above the deletion point
    -- These lines existed in the old version but are gone now.
    -- We can't highlight lines that don't exist, so we use "virtual lines" —
    -- fake lines that Neovim displays but aren't actually in the buffer.
    if old_count > 0 then
      local deleted_lines = {}
      for i = old_start, old_start + old_count - 1 do
        if old_lines[i] then
          -- Prefix with "- " to visually indicate deletion (like a diff)
          local line_text = "- " .. old_lines[i]
          -- Pad with spaces so the red background fills the entire window width
          local padding = string.rep(" ", math.max(0, win_width - #line_text))
          -- Virtual text is a list of {text, highlight_group} chunks
          table.insert(deleted_lines, { { line_text .. padding, "WatchDiffDel" } })
          deleted_count = deleted_count + 1
        end
      end

      if #deleted_lines > 0 then
        -- Place virtual lines above where the content was deleted
        local insert_line = math.min(new_start, #new_lines)
        if insert_line < 1 then insert_line = 1 end

        vim.api.nvim_buf_set_extmark(bufnr, external_change_ns, insert_line - 1, 0, {
          virt_lines = deleted_lines,      -- The fake lines to display
          virt_lines_above = true,         -- Show ABOVE the anchor line
          priority = 100,
        })
      end
    end
  end

  -- Force treesitter to restart so syntax highlighting works after reload.
  -- :checktime can cause treesitter to detach from the buffer, so just
  -- re-parsing isn't enough — we need to stop and start highlighting.
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.treesitter.stop, bufnr)
      pcall(vim.treesitter.start, bufnr)
    end
  end)

  if added_count == 0 and deleted_count == 0 then
    return nil
  end

  local annotation = get_pending_annotation(abs_path)
  local entry = append_history_entry(abs_path, added_count, deleted_count, annotation)
  notify_change(entry)

  if annotation then
    clear_pending_annotation(abs_path)
  end

  return entry
end

-- Reload a changed buffer via :checktime.
-- Some Neovim sessions intermittently fail to update the persistent undo file
-- during external reloads (E828). Retry once with undofile disabled so the
-- buffer still reloads and watchdiff can continue processing the change.
local function reload_buffer_with_checktime(bufnr)
  local ok, err = pcall(vim.cmd, "checktime " .. bufnr)
  if ok then
    return true
  end

  local err_text = tostring(err)
  if not err_text:match("E828") or not vim.api.nvim_buf_is_valid(bufnr) then
    return false, err_text
  end

  local restore_undofile = vim.bo[bufnr].undofile
  if not restore_undofile then
    return false, err_text
  end

  vim.bo[bufnr].undofile = false
  local retry_ok, retry_err = pcall(vim.cmd, "checktime " .. bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.bo[bufnr].undofile = restore_undofile
  end

  if retry_ok then
    return true
  end

  return false, tostring(retry_err)
end

-- ═══════════════════════════════════════════════════════
-- FILE SYSTEM WATCHER (the main detection mechanism)
-- ═══════════════════════════════════════════════════════
--
-- Uses libuv's fs_event to watch for file changes.
-- libuv is the same async I/O library that powers Node.js.
-- Neovim bundles it and exposes it via vim.uv

-- PROCESS A FILE CHANGE
-- Called after debounce timer fires. This is the main logic that decides
-- what to do when an external tool has modified a file.
local function process_file_change(abs_path)
  -- File was deleted (not modified)? Nothing to show.
  if vim.fn.filereadable(abs_path) ~= 1 then return end

  -- Check if this file is already open in a Neovim buffer.
  -- vim.fn.bufnr() returns the buffer number (>= 0) or -1 if not found.
  -- Resolve symlinks for reliable buffer matching
  local resolved = vim.uv.fs_realpath(abs_path) or abs_path
  local bufnr = vim.fn.bufnr(resolved)
  -- Fallback: try original path if resolved didn't match
  if bufnr == -1 then bufnr = vim.fn.bufnr(abs_path) end
  if bufnr == -1 or not vim.api.nvim_buf_is_loaded(bufnr) then
    bufnr = find_loaded_file_buffer(abs_path)
  end
  local is_loaded_buffer = bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr)

  -- Default behavior: only process files that are currently loaded in Neovim.
  -- This avoids pulling in unrelated large/generated files changed by tools.
  if not is_loaded_buffer and not config.track_unopened_files then return end

  -- ── CASE 1: File IS open in a buffer ──
  if is_loaded_buffer then

    -- SAFETY: Don't reload if the user has unsaved edits!
    -- vim.bo[bufnr].modified = true when buffer has changes not saved to disk.
    -- Reloading would silently DESTROY the user's work.
    if vim.bo[bufnr].modified then
      local filename = vim.fn.fnamemodify(abs_path, ":t")  -- :t = tail (just the filename)
      vim.notify(
        "External change detected in " .. filename .. " but buffer has unsaved edits. Use :e! to reload.",
        vim.log.levels.WARN
      )
      return  -- Do NOT reload — user's unsaved work is preserved
    end

    -- Read what's currently on disk to compare with buffer
    local disk_lines = vim.fn.readfile(abs_path)
    if not disk_lines then return end

    -- Read what's currently in the buffer
    local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- If buffer already matches disk, this was probably OUR OWN save — skip.
    -- (User saves in Neovim → file on disk updates → fs_event fires →
    --  we'd reload and diff for no reason because nothing actually changed)
    if table.concat(current_lines, "\n") == table.concat(disk_lines, "\n") then return end

    -- Content differs! An external tool changed this file.
    -- Set flag so FileChangedShellPost doesn't also try to process this.
    reloading[bufnr] = true
    suppress_baseline_update[bufnr] = true

    local reload_ok, reload_err = reload_buffer_with_checktime(bufnr)
    reloading[bufnr] = nil
    suppress_baseline_update[bufnr] = nil

    if not reload_ok then
      local filename = vim.fn.fnamemodify(abs_path, ":t")
      vim.notify("watchdiff: failed to reload " .. filename .. ": " .. reload_err, vim.log.levels.WARN)
      return
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    -- Diff from the ACKNOWLEDGED baseline (what user last saw/saved).
    -- NOT from the pre-reload content. This is the key to accumulating highlights
    -- across multiple agent edits — we always show ALL changes since the user last reviewed.
    local old_lines = acknowledged_content[bufnr] or current_lines
    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local highlight_ok, highlight_err = xpcall(function()
      highlight_external_changes(bufnr, old_lines, new_lines, resolved)
    end, debug.traceback)
    if not highlight_ok then
      local filename = vim.fn.fnamemodify(abs_path, ":t")
      vim.notify("watchdiff: failed to diff " .. filename .. ": " .. highlight_err, vim.log.levels.WARN)
    end

  -- ── CASE 2: File is NOT open in any buffer ──
  else
    -- No buffer to read "before" from. Use git as baseline.
    -- For untracked (brand new) files, git returns nil → fall back to {} (empty).
    -- Empty baseline = the ENTIRE file shows as green (all new lines).
    local old_lines = git_head_contents(abs_path) or {}

    -- Silently load without stealing focus (bufadd + bufload don't switch windows)
    bufnr = vim.fn.bufadd(abs_path)
    -- pcall: bufload can fail with E518 if file content triggers Vim's modeline
    -- parser (e.g. JSON files starting with "{", source maps containing "\n").
    -- The buffer still loads successfully despite the modeline error.
    local ok = pcall(vim.fn.bufload, bufnr)
    if not ok or not vim.api.nvim_buf_is_valid(bufnr) then return end

    -- Override acknowledged_content to the git baseline.
    -- BufReadPost already set it to the NEW content when bufload ran,
    -- but we want highlights to show ALL changes from the git version.
    acknowledged_content[bufnr] = old_lines

    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    highlight_external_changes(bufnr, old_lines, new_lines, resolved)

    local filename = vim.fn.fnamemodify(abs_path, ":t")
    vim.notify("New external file: " .. filename, vim.log.levels.INFO)
  end
end

-- DEBOUNCE HELPER
-- Wraps process_file_change with debounce logic.
-- If the same file changes again within the debounce window, we restart the timer.
local function debounce_file_change(abs_path)
  -- Cancel any existing timer for this file (restart the countdown)
  if debounce_timers[abs_path] then
    safe_stop(debounce_timers[abs_path])
    safe_close(debounce_timers[abs_path])
    debounce_timers[abs_path] = nil
  end

  -- Create a new timer
  local timer = vim.uv.new_timer()
  debounce_timers[abs_path] = timer

  -- vim.schedule_wrap() is CRITICAL here.
  -- libuv callbacks run on a SEPARATE THREAD from Neovim's main loop.
  -- If you call vim.cmd() or vim.api.* directly from a libuv callback,
  -- Neovim will crash or behave unpredictably.
  -- schedule_wrap() queues the function to run on Neovim's main thread (safe).
  -- Think of it like JavaScript's setTimeout posting to the main thread.
  local gen = watcher_generation
  timer:start(config.debounce_ms, 0, vim.schedule_wrap(function()
    if debounce_timers[abs_path] ~= timer then return end
    debounce_timers[abs_path] = nil
    safe_stop(timer)
    safe_close(timer)
    if gen ~= watcher_generation then return end
    process_file_change(abs_path)
  end))
end

-- FS_EVENT CALLBACK (for the main CWD watcher)
-- Called by libuv when any file changes under the watched directory.
-- Runs on the libuv thread (NOT Neovim's main thread).
-- Parameters (provided by libuv automatically):
--   err:      error string if something went wrong, nil if OK
--   filename: path of the changed file, RELATIVE to the watched directory
--   events:   table like { change = true } or { rename = true }
local function on_fs_event(err, filename, _events)
  if err or not filename then return end

  -- Detect temp files from atomic writes (e.g., "file.lua.tmp.12345.67890").
  -- Tools like Claude Code write to a temp file then rename it to the target.
  -- macOS FSEvents often reports the temp file but NOT the rename target.
  -- Extract the actual filename so we process the real file instead.
  local base = filename:match("^(.+)%.tmp%.[%d.]+$")
  if base then
    filename = base
  end

  -- Filter out files we don't care about using configured ignore patterns.
  -- Lua patterns: ^ = start of string, $ = end, % = escape (NOT backslash like regex)
  for _, pattern in ipairs(config.ignore_patterns) do
    if filename:match(pattern) then
      return
    end
  end

  -- Build absolute path from relative filename
  local abs_path = vim.uv.cwd() .. "/" .. filename
  debounce_file_change(abs_path)
end

-- START the main CWD watcher
local function start_watcher()
  if watcher_handle then return end  -- Don't create a second watcher

  local cwd = vim.uv.cwd()

  -- new_fs_event() creates a handle that talks to the OS kernel's file watcher:
  --   macOS: FSEvents (efficient, kernel-level)
  --   Linux: inotify
  --   Windows: ReadDirectoryChangesW
  watcher_handle = vim.uv.new_fs_event()

  if not watcher_handle then
    vim.notify("watchdiff: failed to create fs_event handle", vim.log.levels.ERROR)
    return
  end

  -- { recursive = true } watches ALL subdirectories, not just the top level
  local ok, err = watcher_handle:start(cwd, { recursive = true }, on_fs_event)
  if err then
    vim.notify("watchdiff: watcher failed to start: " .. tostring(err), vim.log.levels.ERROR)
    safe_close(watcher_handle)
    watcher_handle = nil
  end
end

-- STOP the main CWD watcher and clean up debounce timers
local function stop_watcher()
  watcher_generation = watcher_generation + 1
  for path, timer in pairs(debounce_timers) do
    safe_stop(timer)
    safe_close(timer)
    debounce_timers[path] = nil
  end

  if watcher_handle then
    safe_stop(watcher_handle)
    safe_close(watcher_handle)
    watcher_handle = nil
  end
end

-- ═══════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════

-- Clear highlights for a buffer and update its baseline.
-- Press <leader>ch to dismiss all green/red change highlights.
-- This ALSO updates the acknowledged baseline to current content,
-- so future diffs will only show changes made AFTER this point.
function M.clear(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Clear the visual highlights
  vim.api.nvim_buf_clear_namespace(bufnr, external_change_ns, 0, -1)

  -- Update baseline: user has now "seen" the current content.
  -- Next external edit will diff against THIS version, not the old one.
  acknowledged_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  vim.notify("Change highlights cleared", vim.log.levels.INFO)
end

-- Register metadata for the next detected change to a path.
--
-- Example use from another plugin:
--   require("watchdiff").annotate_next_change({
--     path = "/tmp/foo.lua",
--     source = "claude.nvim",
--     action = "insert_comment",
--     summary = "Inserted explanation comments",
--   })
function M.annotate_next_change(opts)
  opts = opts or {}

  local path = opts.path
  if not path or path == "" then
    path = vim.api.nvim_buf_get_name(0)
  end

  local normalized = normalize_path(path)
  if not normalized then
    return false
  end

  pending_annotations[normalized] = {
    source = opts.source or "external",
    action = opts.action or "modify",
    summary = opts.summary,
    meta = opts.meta,
    timestamp = os.date("!%Y-%m-%d %H:%M:%S UTC"),
  }

  return true
end

function M.discard_next_change(path)
  if not path or path == "" then
    path = vim.api.nvim_buf_get_name(0)
  end

  clear_pending_annotation(path)
end

function M.get_history(target)
  local path = target

  if type(target) == "number" then
    path = vim.api.nvim_buf_get_name(target)
  elseif path == nil then
    path = vim.api.nvim_buf_get_name(0)
  end

  local normalized = normalize_path(path)
  if not normalized then
    return {}
  end

  return vim.deepcopy(change_history[normalized] or {})
end

function M.show_history(target)
  local history = M.get_history(target)

  if #history == 0 then
    vim.notify("watchdiff: no recorded change history for this file", vim.log.levels.INFO)
    return false
  end

  vim.cmd("botright 12new")
  local buf = vim.api.nvim_get_current_buf()
  local lines = { "# WatchDiff History", "" }
  local scratch_name = string.format("WatchDiff History [%s]", vim.fs.basename(history[#history].display_path))

  for i = #history, 1, -1 do
    local entry = history[i]
    lines[#lines + 1] = string.format("- %s | %s | %s | +%d/-%d", entry.timestamp, entry.source, entry.action, entry.added, entry.deleted)
    lines[#lines + 1] = string.format("  %s", entry.display_path)
    if entry.summary then
      lines[#lines + 1] = string.format("  %s", entry.summary)
    end
    if entry.meta and entry.meta.question then
      lines[#lines + 1] = string.format("  Question: %s", entry.meta.question)
    end
    lines[#lines + 1] = ""
  end

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, scratch_name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, desc = "Close WatchDiff history" })

  return true
end

-- ═══════════════════════════════════════════════════════
-- SETUP
-- ═══════════════════════════════════════════════════════

function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Enable autoread so :checktime reloads buffers automatically
  vim.o.autoread = true

  -- Define colors for change indicators
  -- bg = background color (requires truecolor terminal)
  vim.api.nvim_set_hl(0, "WatchDiffAdd", config.highlights.add)   -- Green = added/changed
  vim.api.nvim_set_hl(0, "WatchDiffDel", config.highlights.delete) -- Red = deleted

  -- Create autocommand group
  local group = vim.api.nvim_create_augroup("WatchDiff", { clear = true })
  local autocmd = vim.api.nvim_create_autocmd

  -- ═══════════════════════════════════════════════════════
  -- AUTOCMDS: Lifecycle events for the watcher system
  -- ═══════════════════════════════════════════════════════

  -- Save baseline when a file is first opened.
  -- The user sees the file content, so that becomes their acknowledged baseline.
  autocmd("BufReadPost", {
    desc = "Save acknowledged content on file open",
    group = group,
    callback = function(args)
      local bufnr = args.buf
      -- Only for real files — skip special buffers like terminals, help, quickfix
      -- vim.bo[bufnr].buftype is "" for normal file buffers, "terminal" for terminals, etc.
      if vim.bo[bufnr].buftype == "" and not suppress_baseline_update[bufnr] then
        acknowledged_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      end
    end,
  })

  -- Update baseline when the user saves.
  -- After saving, the user knows what's in the file — that's their new baseline.
  autocmd("BufWritePost", {
    desc = "Update acknowledged content after save",
    group = group,
    callback = function(args)
      local bufnr = args.buf
      if vim.bo[bufnr].buftype == "" then
        acknowledged_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      end
    end,
  })

  -- Clean up when a buffer is deleted.
  -- Remove stale entries from acknowledged_content so they don't leak memory.
  autocmd({ "BufDelete", "BufWipeout" }, {
    desc = "Clean up acknowledged content",
    group = group,
    callback = function(args)
      acknowledged_content[args.buf] = nil
      suppress_baseline_update[args.buf] = nil
      reloading[args.buf] = nil
    end,
  })

  -- FileChangedShell fires when Neovim detects an external change
  -- (via :checktime or when you focus the Neovim window).
  -- We control what happens: reload automatically, or ask the user.
  autocmd("FileChangedShell", {
    desc = "Handle external file changes safely (protect unsaved edits)",
    group = group,
    callback = function(args)
      local bufnr = args.buf

      -- SAFETY: If the buffer has unsaved user edits, do NOT auto-reload.
      -- vim.v.fcs_choice controls what Neovim does:
      --   "reload" = reload from disk silently
      --   "ask"    = prompt the user to decide
      --   ""       = do nothing
      if vim.bo[bufnr].modified then
        vim.v.fcs_choice = "ask"
        return
      end

      -- Buffer is clean (no unsaved changes) — safe to reload automatically
      suppress_baseline_update[bufnr] = true
      vim.v.fcs_choice = "reload"
    end,
  })

  -- FileChangedShellPost fires AFTER Neovim reloads a buffer from disk.
  -- This is the fallback path — it fires when Neovim detects changes on its own
  -- (e.g., when you alt-tab back to Neovim, or when :checktime runs from a timer).
  -- Our fs_event watcher usually handles things first and sets reloading to skip this.
  autocmd("FileChangedShellPost", {
    desc = "Highlight changed lines (fallback for non-watcher detection)",
    group = group,
    callback = function(args)
      -- Skip if our fs_event watcher already handled this change
      if reloading[args.buf] then return end

      local bufnr = args.buf
      local old_lines = acknowledged_content[bufnr]

      -- No baseline means we can't compute a diff — just tell the user
      if not old_lines or #old_lines == 0 then
        suppress_baseline_update[bufnr] = nil
        vim.notify("File reloaded (no baseline to diff against)", vim.log.levels.INFO)
        return
      end

      local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      highlight_external_changes(bufnr, old_lines, new_lines, vim.api.nvim_buf_get_name(bufnr))
      suppress_baseline_update[bufnr] = nil
    end,
  })

  -- WATCHER LIFECYCLE
  -- Start the watcher when Neovim opens, restart when CWD changes, clean up on exit.

  autocmd("VimEnter", {
    desc = "Start fs_event watcher on startup",
    group = group,
    callback = start_watcher,
  })

  autocmd("DirChanged", {
    desc = "Restart main watcher when CWD changes",
    group = group,
    callback = function()
      stop_watcher()
      start_watcher()
    end,
  })

  autocmd("VimLeave", {
    desc = "Clean up watcher on exit",
    group = group,
    callback = stop_watcher,
  })

  -- Start watcher immediately if setup() is called after VimEnter
  -- (which is the normal case with lazy.nvim's VeryLazy event)
  if vim.v.vim_did_enter == 1 then
    start_watcher()

    -- Capture baselines for buffers already open before the plugin loaded.
    -- With lazy loading (VeryLazy event), BufReadPost already fired for
    -- initial buffers before our autocmd was created. Without this,
    -- acknowledged_content is empty and we can't diff against a baseline.
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
        acknowledged_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      end
    end
  end

  -- KEYMAP: Clear highlights after reviewing changes
  if config.keys.clear then
    vim.keymap.set("n", config.keys.clear, function()
      M.clear()
    end, { desc = "Clear external change highlights" })
  end

  if config.keys.history then
    vim.keymap.set("n", config.keys.history, function()
      M.show_history()
    end, { desc = "Show watchdiff change history" })
  end

  pcall(vim.api.nvim_del_user_command, "WatchDiffHistory")
  vim.api.nvim_create_user_command("WatchDiffHistory", function()
    M.show_history()
  end, { desc = "Show watchdiff history for current file" })
end

return M
