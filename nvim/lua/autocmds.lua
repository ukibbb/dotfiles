-- Automatic Commands (Event Handlers)
-- Autocommands run code automatically when events occur
-- Opening a file, saving, entering/leaving a buffer, etc.
-- Like event listeners in JavaScript

-- In Neovim, `vim` is a global table that provides access to all Neovim APIs.
-- Localizing it silences "undefined global" warnings from the Lua language server
-- and is slightly faster (Lua looks up local variables faster than globals).
local vim = vim

-- Python: make try/except/finally/raise red (#F07178 from ayu_dark palette)
-- We set this after ColorScheme loads so it doesn't get overwritten by the theme
vim.api.nvim_set_hl(0, "@keyword.exception.python", { fg = "#F07178" })

local autocmd = vim.api.nvim_create_autocmd  -- Function to create autocommands
local augroup = vim.api.nvim_create_augroup  -- Function to create autocommand groups

-- ABOUT AUTOCOMMAND GROUPS (augroups)
-- Groups organize related autocommands together
-- { clear = true } removes old autocmds in this group when re-sourcing
-- Without this, reloading your config would CREATE DUPLICATE autocommands!

-- SECTION 1: HIGHLIGHT YANK (Visual Feedback)
-- Flash/highlight text briefly when you yank (copy) it
-- This provides visual feedback so you know what was copied

augroup("YankHighlight", { clear = true })  -- Create group named "YankHighlight"

autocmd("TextYankPost", {  -- Event: after yanking text
  desc = "Highlight yanked text",  -- Description (shows in :autocmd)
  group = "YankHighlight",         -- Assign to our group
  callback = function()
    -- vim.highlight.on_yank() is a built-in helper function
    -- higroup = highlight group to use (default: "IncSearch")
    -- timeout = how long to highlight in milliseconds
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- SECTION 2: RESTORE CURSOR POSITION
-- When reopening a file, jump to where cursor was last time
-- Extremely useful - you don't lose your place!
augroup("RestoreCursor", { clear = true })

autocmd("BufReadPost", {  -- Event: after reading a buffer (opening a file)
  desc = "Restore cursor to last position",
  group = "RestoreCursor",
  callback = function()
    -- Get the mark " (double quote) which stores last cursor position
    local mark = vim.api.nvim_buf_get_mark(0, '"')  -- 0 = current buffer
    local line_count = vim.api.nvim_buf_line_count(0)  -- Total lines in file

    -- Only restore if:
    -- 1. mark[1] > 0 = mark exists (line number > 0)
    -- 2. mark[1] <= line_count = mark is within file bounds (file wasn't truncated)
    if mark[1] > 0 and mark[1] <= line_count then
      -- pcall = protected call (won't crash if something goes wrong)
      -- nvim_win_set_cursor sets cursor position: {line, column}
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- SECTION 3: AUTO-RESIZE SPLITS
-- When you resize Neovim window, make all splits equal size
-- Useful when using Neovim in a terminal and resizing the terminal

augroup("AutoResize", { clear = true })

autocmd("VimResized", {  -- Event: Neovim window was resized
  desc = "Auto-resize splits when window is resized",
  group = "AutoResize",
  callback = function()
    -- tabdo = execute command in all tabs
    -- wincmd = = make all windows equal size
    vim.cmd("tabdo wincmd =")
  end,
})

-- SECTION 4: CLOSE SPECIAL BUFFERS WITH 'q'
-- Some buffer types (help, quickfix, etc.) should be closeable with just 'q'
-- This makes navigation faster - no need to type :q or :close

augroup("CloseWithQ", { clear = true })

autocmd("FileType", {  -- Event: filetype was detected for a buffer
  desc = "Close certain filetypes with just 'q'",
  group = "CloseWithQ",
  -- pattern = list of filetypes this applies to
  pattern = {
    "help",              -- :help windows
    "qf",                -- Quickfix list (:copen)
    "lspinfo",           -- :LspInfo window
    "man",               -- :Man pages
    "notify",            -- Notification windows
    "spectre_panel",     -- Search/replace plugin
    "startuptime",       -- :StartupTime profiling
    "checkhealth",       -- :checkhealth window
  },
  callback = function(event)
    -- event.buf = buffer number where the event occurred
    vim.bo[event.buf].buflisted = false  -- Don't show in buffer list

    -- Set buffer-local keymap: q = close window
    -- buffer = event.buf means this only applies to this specific buffer
    vim.keymap.set("n", "q", "<cmd>close<CR>", {
      buffer = event.buf,
      silent = true,  -- Don't show message when pressing q
      desc = "Close this window",
    })
  end,
})

-- SECTION 5: EXTERNAL FILE CHANGE DETECTION
-- ===========================================
-- Detects when external tools (Claude Code, Codex, etc.) modify files on disk.
-- Shows green highlights for added/changed lines, red virtual lines for deleted lines.
-- User presses <leader>ch to clear highlights after reviewing.
--
-- HOW IT WORKS (big picture):
--   1. libuv's fs_event API watches the filesystem for changes (OS-level, very efficient)
--   2. When a file changes, we debounce (wait 200ms for rapid saves to settle)
--   3. We diff the file against what the user last "acknowledged" (saw/saved)
--   4. We apply green/red highlights to show what changed
--   5. Highlights ACCUMULATE until the user reviews and clears them with <leader>ch
--
-- This is TOOL-AGNOSTIC — works with any external program, not just Claude Code.

augroup("CheckTime", { clear = true })

-- ═══════════════════════════════════════════════════════
-- SETUP: Namespaces, state tables, and highlight colors
-- ═══════════════════════════════════════════════════════

-- Namespaces group extmarks (highlights) together.
-- This lets us clear just OUR highlights without affecting other plugins (like gitsigns).
-- Think of it like a separate "layer" in a drawing app.
local external_change_ns = vim.api.nvim_create_namespace("ExternalChangeHighlight")

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

-- Define colors for change indicators
-- bg = background color (requires truecolor terminal, which you have)
vim.api.nvim_set_hl(0, "ExternalChangeAdd", { bg = "#2d4f2d" })  -- Green = added/changed
vim.api.nvim_set_hl(0, "ExternalChangeDel", { bg = "#4f2d2d" })  -- Red = deleted

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
local function highlight_external_changes(bufnr, old_lines, new_lines)
  -- Clear our previous highlights and re-apply from scratch.
  -- This is correct because we always diff from the acknowledged baseline —
  -- the full diff naturally includes ALL changes since the user last reviewed.
  vim.api.nvim_buf_clear_namespace(bufnr, external_change_ns, 0, -1)

  -- Skip inline highlights for very large files to avoid freezing Neovim
  if #old_lines > 5000 or #new_lines > 5000 then
    vim.notify(
      string.format("File too large for inline diff (%d lines). Use :diff to review.", #new_lines),
      vim.log.levels.INFO
    )
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
    -- unpack() extracts table values into separate variables
    local old_start, old_count, new_start, new_count = table.unpack(hunk)

    -- ADDED/CHANGED LINES → green background
    -- These lines exist in the new version but not (or differently) in the old version
    for i = new_start, new_start + new_count - 1 do
      if i <= #new_lines then
        -- Extmarks are Neovim's way of attaching metadata to buffer positions.
        -- They "stick" to text — if you insert a line above, the extmark moves down.
        -- We use them for highlighting because they're efficient and auto-cleanup.
        vim.api.nvim_buf_set_extmark(bufnr, external_change_ns, i - 1, 0, {
          end_col = #new_lines[i],
          hl_group = "ExternalChangeAdd",
          hl_eol = true,                        -- Color past end of text too
          line_hl_group = "ExternalChangeAdd",   -- Also highlight the line number column
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
          table.insert(deleted_lines, { { line_text .. padding, "ExternalChangeDel" } })
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

  -- Force treesitter to re-parse so syntax highlighting updates after reload
  -- vim.schedule() defers this to after the current function finishes
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(function()
        local parser = vim.treesitter.get_parser(bufnr)
        if parser then parser:parse(true) end
      end)
    end
  end)

  -- Notify the user about what changed
  if added_count > 0 or deleted_count > 0 then
    vim.notify(
      string.format("File reloaded: +%d/-%d lines. <leader>ch to clear highlights.", added_count, deleted_count),
      vim.log.levels.WARN
    )
  end
end

-- Flag to prevent double-processing.
-- When our fs_event handler calls :checktime, that can trigger FileChangedShellPost.
-- Without this flag, the same change would be processed TWICE.
-- We set it to true before :checktime and nil after, so FileChangedShellPost knows to skip.
local claude_reloading = {}

-- ═══════════════════════════════════════════════════════
-- OLD SOLUTION (kept for reference — commented out)
-- ═══════════════════════════════════════════════════════

-- The original approach used Claude Code hooks (PreToolUse + PostToolUse) to notify
-- Neovim via RPC sockets. It required a custom nvim() shell wrapper (in .zshrc) that
-- started Neovim with --listen <socket>, and Claude Code hooks that called
-- nvim --server <socket> --remote-expr to poke Neovim after each file edit.
--
-- The current fs_event approach replaced it because:
--   1. It's tool-agnostic (works with ANY external editor, not just Claude Code)
--   2. It needs no hooks or socket setup
--   3. It's simpler to maintain
--
-- To switch back, see git history for the hook-based implementation.

-- ═══════════════════════════════════════════════════════
-- FILE SYSTEM WATCHER (the main detection mechanism)
-- ═══════════════════════════════════════════════════════
--
-- Uses libuv's fs_event to watch for file changes.
-- libuv is the same async I/O library that powers Node.js.
-- Neovim bundles it and exposes it via vim.uv

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
local DEBOUNCE_MS = 200

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

  -- ── CASE 1: File IS open in a buffer ──
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then

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
    claude_reloading[bufnr] = true

    -- :checktime tells Neovim: "check if this file changed on disk".
    -- Since autoread is on (see options.lua), Neovim reloads the buffer from disk.
    vim.cmd("checktime " .. bufnr)

    -- Clear the flag — only needed for the duration of :checktime
    claude_reloading[bufnr] = nil

    -- Diff from the ACKNOWLEDGED baseline (what user last saw/saved).
    -- NOT from the pre-reload content. This is the key to accumulating highlights
    -- across multiple agent edits — we always show ALL changes since the user last reviewed.
    local old_lines = acknowledged_content[bufnr] or current_lines
    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    highlight_external_changes(bufnr, old_lines, new_lines)

  -- ── CASE 2: File is NOT open in any buffer ──
  else
    -- No buffer to read "before" from. Use git as baseline.
    -- For untracked (brand new) files, git returns nil → fall back to {} (empty).
    -- Empty baseline = the ENTIRE file shows as green (all new lines).
    local old_lines = git_head_contents(abs_path) or {}

    -- Silently load without stealing focus (bufadd + bufload don't switch windows)
    bufnr = vim.fn.bufadd(abs_path)
    vim.fn.bufload(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    -- Override acknowledged_content to the git baseline.
    -- BufReadPost already set it to the NEW content when bufload ran,
    -- but we want highlights to show ALL changes from the git version.
    acknowledged_content[bufnr] = old_lines

    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    highlight_external_changes(bufnr, old_lines, new_lines)

    local filename = vim.fn.fnamemodify(abs_path, ":t")
    vim.notify("New external file: " .. filename, vim.log.levels.INFO)
  end
end

-- DEBOUNCE HELPER
-- Wraps process_file_change with debounce logic.
-- If the same file changes again within 200ms, we restart the timer.
local function debounce_file_change(abs_path)
  -- Cancel any existing timer for this file (restart the countdown)
  if debounce_timers[abs_path] then
    debounce_timers[abs_path]:stop()
    debounce_timers[abs_path]:close()
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
  timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
    timer:stop()
    timer:close()
    debounce_timers[abs_path] = nil
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

  -- Filter out files we don't care about.
  -- Lua patterns: ^ = start of string, $ = end, % = escape (NOT backslash like regex)
  if filename:match("^%.git/")       -- Git internals (constantly changing)
    or filename:match("%.swp$")      -- Vim swap files
    or filename:match("~$")          -- Backup files (some editors create these)
    or filename:match("%.DS_Store$") -- macOS folder metadata
    or filename:match("^4913$")      -- Neovim writes this to test write permissions
  then
    return
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

  if watcher_handle then
    -- { recursive = true } watches ALL subdirectories, not just the top level
    watcher_handle:start(cwd, { recursive = true }, on_fs_event)
  end
end

-- STOP the main CWD watcher and clean up debounce timers
local function stop_watcher()
  watcher_generation = watcher_generation + 1
  for path, timer in pairs(debounce_timers) do
    timer:stop()
    timer:close()
    debounce_timers[path] = nil
  end

  if watcher_handle then
    watcher_handle:stop()
    watcher_handle:close()
    watcher_handle = nil
  end
end

-- ═══════════════════════════════════════════════════════
-- AUTOCMDS: Lifecycle events for the watcher system
-- ═══════════════════════════════════════════════════════

-- Save baseline when a file is first opened.
-- The user sees the file content, so that becomes their acknowledged baseline.
autocmd("BufReadPost", {
  desc = "Save acknowledged content on file open",
  group = "CheckTime",
  callback = function(args)
    local bufnr = args.buf
    -- Only for real files — skip special buffers like terminals, help, quickfix
    -- vim.bo[bufnr].buftype is "" for normal file buffers, "terminal" for terminals, etc.
    if vim.bo[bufnr].buftype == "" then
      acknowledged_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end
  end,
})

-- Update baseline when the user saves.
-- After saving, the user knows what's in the file — that's their new baseline.
autocmd("BufWritePost", {
  desc = "Update acknowledged content after save",
  group = "CheckTime",
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
  group = "CheckTime",
  callback = function(args)
    acknowledged_content[args.buf] = nil
  end,
})

-- FileChangedShell fires when Neovim detects an external change
-- (via :checktime or when you focus the Neovim window).
-- We control what happens: reload automatically, or ask the user.
autocmd("FileChangedShell", {
  desc = "Handle external file changes safely (protect unsaved edits)",
  group = "CheckTime",
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
    vim.v.fcs_choice = "reload"
  end,
})

-- FileChangedShellPost fires AFTER Neovim reloads a buffer from disk.
-- This is the fallback path — it fires when Neovim detects changes on its own
-- (e.g., when you alt-tab back to Neovim, or when :checktime runs from a timer).
-- Our fs_event watcher usually handles things first and sets claude_reloading to skip this.
autocmd("FileChangedShellPost", {
  desc = "Highlight changed lines (fallback for non-watcher detection)",
  group = "CheckTime",
  callback = function(args)
    -- Skip if our fs_event watcher already handled this change
    if claude_reloading[args.buf] then return end

    local bufnr = args.buf
    local old_lines = acknowledged_content[bufnr]

    -- No baseline means we can't compute a diff — just tell the user
    if not old_lines or #old_lines == 0 then
      vim.notify("File reloaded (no baseline to diff against)", vim.log.levels.INFO)
      return
    end

    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    highlight_external_changes(bufnr, old_lines, new_lines)
  end,
})

-- WATCHER LIFECYCLE
-- Start the watcher when Neovim opens, restart when CWD changes, clean up on exit.

autocmd("VimEnter", {
  desc = "Start fs_event watcher on startup",
  group = "CheckTime",
  callback = start_watcher,
})

autocmd("DirChanged", {
  desc = "Restart main watcher when CWD changes",
  group = "CheckTime",
  callback = function()
    stop_watcher()
    start_watcher()
  end,
})

autocmd("VimLeave", {
  desc = "Clean up watcher on exit",
  group = "CheckTime",
  callback = stop_watcher,
})

-- KEYMAP: Clear highlights after reviewing changes.
-- Press <leader>ch to dismiss all green/red change highlights.
-- This ALSO updates the acknowledged baseline to current content,
-- so future diffs will only show changes made AFTER this point.
vim.keymap.set("n", "<leader>ch", function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Clear the visual highlights
  vim.api.nvim_buf_clear_namespace(bufnr, external_change_ns, 0, -1)

  -- Update baseline: user has now "seen" the current content.
  -- Next external edit will diff against THIS version, not the old one.
  acknowledged_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  vim.notify("Change highlights cleared", vim.log.levels.INFO)
end, { desc = "Clear external change highlights" })

-- SECTION 6: AUTO-CREATE DIRECTORIES
-- When saving a file in a directory that doesn't exist, create it automatically
-- Example: :w ~/new/deep/path/file.lua creates ~/new/deep/path/ if needed
augroup("AutoMkdir", { clear = true })

autocmd("BufWritePre", {  -- Event: before writing a buffer (saving)
  desc = "Auto-create parent directories",
  group = "AutoMkdir",
  callback = function(event)
    -- Only for regular files (not special buffers)
    if event.match:match("^%w%w+://") then
      return  -- Skip URLs (fugitive://, oil://, etc.)
    end

    -- Get directory path from full file path
    local file = vim.uv.fs_realpath(event.match) or event.match
    local dir = vim.fn.fnamemodify(file, ":p:h")  -- :h = head (parent directory)

    -- Create directory if it doesn't exist
    -- 755 = permissions (rwxr-xr-x)
    -- "p" = create parent directories too (like mkdir -p)
    vim.fn.mkdir(dir, "p")
  end,
})

-- SECTION 7: REMOVE TRAILING WHITESPACE
-- Automatically remove trailing whitespace when saving
-- Trailing whitespace is ugly and can cause issues in some contexts

augroup("TrimWhitespace", { clear = true })

autocmd("BufWritePre", {  -- Event: before writing/saving
  desc = "Remove trailing whitespace on save",
  group = "TrimWhitespace",
  pattern = "*",  -- Apply to all files
  callback = function()
    -- Save current cursor position
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    -- %s = substitute command (like sed)
    -- \s\+$ = one or more whitespace characters at end of line
    -- //e = replace with nothing, 'e' flag suppresses error if no match
    vim.cmd([[%s/\s\+$//e]])

    -- Restore cursor position (substitute might have moved it)
    pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
  end,
})

-- SECTION 8: FILETYPE-SPECIFIC SETTINGS
-- Some filetypes need different settings
-- Example: Markdown needs wrap, Go uses tabs, Python uses 4-space indent

augroup("FileTypeSettings", { clear = true })

-- Markdown: enable word wrap (text files should wrap)
autocmd("FileType", {
  desc = "Enable wrap for markdown",
  group = "FileTypeSettings",
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true       -- Enable line wrapping
    vim.opt_local.spell = true      -- Enable spell checking
  end,
})

-- Go: use tabs (Go convention)
autocmd("FileType", {
  desc = "Use tabs for Go",
  group = "FileTypeSettings",
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false  -- Use real tabs, not spaces
    vim.opt_local.tabstop = 4        -- Tab = 4 characters wide
    vim.opt_local.shiftwidth = 4     -- Indent = 4 characters
  end,
})

-- Python: 4-space indent (PEP 8 style guide)
autocmd("FileType", {
  desc = "Python 4-space indent",
  group = "FileTypeSettings",
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

-- SECTION 9: CLAUDE.NVIM DEVELOPMENT MODE
-- Auto-load development helpers when editing the claude.nvim plugin
-- This sets up hot-reload keymaps automatically when you open plugin files
--
-- HOW IT WORKS:
-- "once = true" means this only fires ONCE per Neovim session
-- First time you open any file in claude.nvim/lua/, dev helpers load
-- Then the autocmd deletes itself (no need to check again)

augroup("ClaudeNvimDev", { clear = true })

autocmd("BufEnter", {
  desc = "Auto-load claude.nvim dev helpers",
  group = "ClaudeNvimDev",
  pattern = "*/claude.nvim/lua/*.lua",  -- Only files in the plugin
  once = true,                           -- Fire only once, then remove
  callback = function()
    -- pcall catches errors if the module doesn't exist yet
    local ok, dev = pcall(require, "claude.dev")
    if ok then
      dev.setup()
      vim.notify("claude.nvim dev mode activated!", vim.log.levels.INFO)
    end
  end,
})

-- CUSTOM USER EVENT (ADVANCED - LIKE NVCHAD USES)
-- This creates a custom "FilePost" event that fires after UI is ready AND
-- a real file is open. Useful for lazy-loading plugins that need the UI.

augroup("FilePost", { clear = true })

autocmd({ "UIEnter", "BufReadPost", "BufNewFile" }, {
  desc = "Custom FilePost event for lazy-loading",
  group = "FilePost",
  callback = function(args)
    local file = vim.api.nvim_buf_get_name(args.buf)  -- Get filename
    local buftype = vim.bo[args.buf].buftype          -- Get buffer type

    -- vim.g.ui_entered tracks if UIEnter has fired
    if not vim.g.ui_entered and args.event == "UIEnter" then
      vim.g.ui_entered = true
    end

    -- Only fire FilePost if:
    -- 1. UI has entered
    -- 2. File exists (not empty buffer)
    -- 3. Not a special buffer (nofile = scratch buffers)
    if file ~= "" and buftype ~= "nofile" and vim.g.ui_entered then
      -- Fire our custom User event
      vim.api.nvim_exec_autocmds("User", { pattern = "FilePost", modeline = false })

      -- Delete this augroup (only need to fire once)
      vim.api.nvim_del_augroup_by_name("FilePost")

      -- Schedule filetype detection (after event loop completes)
      vim.schedule(function()
        vim.api.nvim_exec_autocmds("FileType", {})
      end)
    end
  end,
})
