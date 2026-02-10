-- Automatic Commands (Event Handlers)
-- Autocommands run code automatically when events occur
-- Opening a file, saving, entering/leaving a buffer, etc.
-- Like event listeners in JavaScript

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

-- SECTION 5: CHECK IF FILE CHANGED OUTSIDE NEOVIM
-- If you edit a file in another program while it's open in Neovim,
-- this will prompt you to reload it

augroup("CheckTime", { clear = true })

-- EXTERNAL CHANGE DETECTION WITH LINE HIGHLIGHTING
-- When Claude or other tools modify a file, we want to:
-- 1. Detect the change
-- 2. Reload the buffer
-- 3. Highlight exactly which lines changed (green)
-- 4. Keep highlights until user dismisses them

-- Namespace for our highlights - namespaces let us group highlights
-- so we can clear just ours without affecting other plugins
-- nvim_create_namespace returns a unique integer ID
local external_change_ns = vim.api.nvim_create_namespace("ExternalChangeHighlight")

-- Table to store buffer contents as a running snapshot
-- Key = buffer number, Value = array of lines
-- Updated on first load and after each external reload
-- This avoids relying solely on FileChangedShell (which may not fire with autoread)
local pre_reload_content = {}

-- Define custom highlight groups for changed/deleted lines
-- guibg = background color in GUI/truecolor terminals
-- Changed/added lines = green background
vim.api.nvim_set_hl(0, "ExternalChangeAdd", { bg = "#2d4f2d" })
-- Deleted lines = red background (shown as virtual lines)
vim.api.nvim_set_hl(0, "ExternalChangeDel", { bg = "#4f2d2d" })

-- Diff old vs new content and apply change highlights
local function highlight_external_changes(bufnr, old_lines, new_lines)
  vim.api.nvim_buf_clear_namespace(bufnr, external_change_ns, 0, -1)

  local old_text = table.concat(old_lines, "\n") .. "\n"
  local new_text = table.concat(new_lines, "\n") .. "\n"

  local diff = vim.diff(old_text, new_text, {
    result_type = "indices",
    algorithm = "histogram",
  })

  local added_count = 0
  local deleted_count = 0

  for _, hunk in ipairs(diff) do
    local old_start, old_count, new_start, new_count = unpack(hunk)

    for i = new_start, new_start + new_count - 1 do
      if i <= #new_lines then
        local line_len = #new_lines[i]
        vim.api.nvim_buf_set_extmark(bufnr, external_change_ns, i - 1, 0, {
          end_col = line_len,
          hl_group = "ExternalChangeAdd",
          hl_eol = true,
          line_hl_group = "ExternalChangeAdd",
          priority = 100,
        })
        added_count = added_count + 1
      end
    end

    if old_count > 0 then
      local deleted_lines = {}
      local win_width = vim.api.nvim_win_get_width(0)
      for i = old_start, old_start + old_count - 1 do
        if old_lines[i] then
          local line_text = "- " .. old_lines[i]
          local padding = string.rep(" ", math.max(0, win_width - #line_text))
          table.insert(deleted_lines, { { line_text .. padding, "ExternalChangeDel" } })
          deleted_count = deleted_count + 1
        end
      end

      if #deleted_lines > 0 then
        local insert_line = math.min(new_start, #new_lines)
        if insert_line < 1 then insert_line = 1 end

        vim.api.nvim_buf_set_extmark(bufnr, external_change_ns, insert_line - 1, 0, {
          virt_lines = deleted_lines,
          virt_lines_above = true,
          priority = 100,
        })
      end
    end
  end

  pre_reload_content[bufnr] = new_lines

  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(function()
        local parser = vim.treesitter.get_parser(bufnr)
        if parser then parser:parse(true) end
      end)
    end
  end)

  if added_count > 0 or deleted_count > 0 then
    vim.notify(
      string.format("File reloaded: +%d/-%d lines. <leader>ch to clear highlights.", added_count, deleted_count),
      vim.log.levels.WARN
    )
  end
end

-- Flag to skip FileChangedShellPost when handled by fs_event watcher
local claude_reloading = {}

-- ===== OLD SOLUTION: CLAUDE CODE HOOK-BASED CHANGE DETECTION =====
-- This was the original approach where Claude Code's hooks notify Neovim directly.
-- It requires Claude Code-specific hooks in claude/settings.json (PreToolUse + PostToolUse).
-- To switch back to this approach:
--   1. Uncomment this function
--   2. Comment out or remove the fs_event watcher section below
--   3. Restore the hooks in claude/settings.json (see bottom of this file for the hook config)
--
-- HOW IT WORKED:
-- Claude Code has a hook system that runs shell commands before/after tool use.
-- PreToolUse hook: Before Claude edits a file, copies it to /tmp/claude_pre_<md5hash>
--   This creates a "before" snapshot so we can diff against it later.
-- PostToolUse hook: After Claude edits a file, calls nvim --server <socket> --remote-expr
--   This pokes Neovim via RPC, passing the file path and snapshot path.
--   Neovim then diffs the snapshot (old) against the buffer (new) and highlights changes.
--
-- FUNCTION: claude_check_file(filepath, pre_path)
--   filepath: the file Claude just edited
--   pre_path: path to the pre-edit snapshot in /tmp (created by PreToolUse hook)
--
--   For OPEN buffers:
--     1. Reads current buffer lines (this is the "before" content)
--     2. Runs :checktime to reload the file from disk
--     3. Reads buffer lines again (this is the "after" content)
--     4. Diffs old vs new and applies highlights
--
--   For UNOPENED files:
--     1. Reads the pre-snapshot file (the copy made by PreToolUse hook)
--     2. Opens the file with :edit (loads new content into a buffer)
--     3. Diffs snapshot vs buffer and applies highlights
--     4. Deletes the snapshot file from /tmp
--
-- _G.claude_check_file = function(filepath, pre_path)
--   local bufnr = vim.fn.bufnr(filepath)
--   if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
--     local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--     claude_reloading[bufnr] = true
--     vim.cmd("checktime " .. bufnr)
--     claude_reloading[bufnr] = nil
--     local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--     highlight_external_changes(bufnr, old_lines, new_lines)
--   else
--     local old_lines = {}
--     if pre_path and pre_path ~= "" and vim.fn.filereadable(pre_path) == 1 then
--       old_lines = vim.fn.readfile(pre_path)
--     end
--     vim.cmd("edit " .. vim.fn.fnameescape(filepath))
--     bufnr = vim.fn.bufnr(filepath)
--     local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--     highlight_external_changes(bufnr, old_lines, new_lines)
--   end
--   if pre_path and pre_path ~= "" then
--     os.remove(pre_path)
--   end
--   return "1"
-- end
--
-- REQUIRED CLAUDE/SETTINGS.JSON HOOKS (restore these if switching back):
-- {
--   "hooks": {
--     "PreToolUse": [{
--       "matcher": "Edit|Write",
--       "hooks": [{
--         "type": "command",
--         "command": "fp=$(cat | jq -r '.tool_input.file_path'); [ -f \"$fp\" ] && cp \"$fp\" \"/tmp/claude_pre_$(echo \"$fp\" | md5)\" || true; true"
--       }]
--     }],
--     "PostToolUse": [{
--       "matcher": "Edit|Write",
--       "hooks": [{
--         "type": "command",
--         "command": "fp=$(cat | jq -r '.tool_input.file_path'); pre=\"/tmp/claude_pre_$(echo \"$fp\" | md5)\"; efp=$(printf '%s' \"$fp\" | sed \"s/'/''/g\"); epre=$(printf '%s' \"$pre\" | sed \"s/'/''/g\"); for s in /tmp/nvim*.sock; do [ -S \"$s\" ] && nvim --server \"$s\" --remote-expr \"v:lua.claude_check_file('$efp','$epre')\" 2>/dev/null; done; true"
--       }]
--     }]
--   }
-- }
-- ===== END OLD SOLUTION =====

-- ===== NEW SOLUTION: UNIVERSAL FILE CHANGE DETECTION (TOOL-AGNOSTIC) =====
-- Uses libuv fs_event to watch the working directory for ANY file changes.
-- Works with Claude Code, Codex, manual edits, or any other external tool.
-- No hooks needed — Neovim detects changes itself.
--
-- THE BIG IDEA:
-- Instead of relying on Claude Code hooks to TELL us about changes,
-- we use the operating system's file-watching API to DETECT changes ourselves.
-- This means ANY program that modifies a file will trigger our diff highlights.
--
-- Neovim bundles "libuv" (the same async I/O library that powers Node.js).
-- We access it via `vim.uv` — it gives us timers, file watchers, and more.

-- GIT BASELINE HELPER
-- When an external tool edits a file that's NOT currently open in Neovim,
-- we need something to compare against (the "before" content).
-- Solution: ask git for the last-committed version of that file.
-- If the file is untracked (brand new), this returns nil and we fall back to {}.
local function git_head_contents(filepath)
  -- Step 1: Find the root of the git repository
  -- `git rev-parse --show-toplevel` prints the absolute path to the repo root
  -- e.g., "/Users/lukasz/Desktop/dotfiles"
  -- vim.fn.systemlist() runs a shell command and returns output as a list of lines
  local result = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })

  -- vim.v.shell_error is set by Neovim after every shell command
  -- Non-zero means the command failed (maybe we're not in a git repo)
  if vim.v.shell_error ~= 0 or #result == 0 then return nil end

  local git_root = result[1]  -- First line of output = the repo root path

  -- Step 2: Convert absolute path to relative path (git needs relative paths)
  -- Example: "/Users/lukasz/Desktop/dotfiles/nvim/init.lua" becomes "nvim/init.lua"
  local rel_path = filepath
  -- string:sub(start, end) extracts a substring
  -- We check if filepath starts with the git root
  if filepath:sub(1, #git_root) == git_root then
    -- Skip past the git root + the "/" separator (hence +2)
    rel_path = filepath:sub(#git_root + 2)
  end

  -- Step 3: Get the file content from the last commit
  -- `git show HEAD:path/to/file` prints the file as it was in the latest commit
  -- HEAD = the latest commit on the current branch
  -- The colon syntax HEAD:file is git's way of addressing files inside commits
  local lines = vim.fn.systemlist({ "git", "show", "HEAD:" .. rel_path })

  -- If the command failed (file doesn't exist in git history = new/untracked file)
  if vim.v.shell_error ~= 0 then return nil end

  return lines  -- Return the list of lines from the last commit
end

-- FILE WATCHER STATE (module-level variables)
-- These variables persist for the lifetime of the Neovim session.
-- They track the watcher and any pending debounce timers.

-- The libuv fs_event handle — this is our connection to the OS file watcher.
-- nil when no watcher is active.
local watcher_handle = nil

-- A Lua table (like a dictionary/hashmap) mapping file paths to timer handles.
-- Used for debouncing — see explanation below in on_fs_event.
-- Key = absolute file path (string), Value = libuv timer handle
local debounce_timers = {}

-- How long to wait (in milliseconds) before processing a file change.
-- WHAT IS DEBOUNCING?
-- When a tool saves a file, the OS might fire MULTIPLE events rapidly
-- (e.g., "changed", "changed", "changed" within a few ms).
-- We don't want to reload 3 times — that would be slow and flashy.
-- Instead, we WAIT 200ms after the LAST event before doing anything.
-- If another event comes in during the wait, we restart the timer.
-- This is called "debouncing" — like a physical button that bounces
-- when pressed and you want to register only one press.
local DEBOUNCE_MS = 200

-- PROCESS A DETECTED FILE CHANGE
-- This is the main function that handles a file change event.
-- It decides what to do based on whether the file is already open in Neovim.
local function process_file_change(abs_path)
  -- vim.fn.filereadable() returns 1 if the file exists and can be read, 0 otherwise
  -- If the file was deleted (not just modified), we have nothing to show — skip it
  if vim.fn.filereadable(abs_path) ~= 1 then return end

  -- vim.fn.bufnr() looks up whether this file is loaded in a Neovim buffer
  -- Returns the buffer number (integer >= 0) if found, or -1 if not found
  -- A "buffer" is Neovim's in-memory representation of a file
  local bufnr = vim.fn.bufnr(abs_path)

  -- CASE 1: File IS open in a buffer (we're looking at it or it's in the buffer list)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    -- Grab what's currently in the buffer (this is the "before" state)
    -- nvim_buf_get_lines(buffer, start_line, end_line, strict)
    --   0 = first line, -1 = last line, false = don't error on out-of-range
    local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Read the file directly from disk to see what changed
    -- vim.fn.readfile() reads a file into a Lua table (one string per line)
    local disk_lines = vim.fn.readfile(abs_path)
    if not disk_lines then return end

    -- EARLY RETURN: If buffer content matches disk content, nothing changed
    -- This happens when YOU save from Neovim — the file on disk updates,
    -- the OS fires a change event, but the buffer already has the same content.
    -- table.concat() joins a list of strings with a separator (like JS Array.join)
    local old_text = table.concat(old_lines, "\n")
    local disk_text = table.concat(disk_lines, "\n")
    if old_text == disk_text then return end

    -- Content differs! An external tool changed this file.
    -- Set the claude_reloading flag so the FileChangedShellPost autocmd
    -- (defined further down) knows to skip its own handling.
    -- We're handling the diff ourselves right here.
    claude_reloading[bufnr] = true

    -- :checktime tells Neovim: "hey, check if this file changed on disk"
    -- Since autoread is on, Neovim will reload the buffer from disk.
    -- We pass the buffer number so only THIS buffer gets checked.
    vim.cmd("checktime " .. bufnr)

    -- Clear the flag — we only needed it for the duration of checktime
    claude_reloading[bufnr] = nil

    -- Now the buffer has the NEW content (reloaded from disk).
    -- Read it again to get the "after" state.
    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Diff old vs new and apply green/red highlights (function defined above)
    highlight_external_changes(bufnr, old_lines, new_lines)

  -- CASE 2: File is NOT open in any buffer
  else
    -- We have no buffer to read "before" content from.
    -- Use git to get the last-committed version as our baseline.
    -- If git_head_contents returns nil (untracked file), fall back to empty table {}.
    -- Empty baseline means the ENTIRE file will show as green (all new).
    local old_lines = git_head_contents(abs_path) or {}

    -- Open the file in Neovim — this creates a new buffer with the file content
    -- vim.fn.fnameescape() escapes special characters in the path
    -- (spaces, #, %, etc.) so Neovim's command parser doesn't choke on them
    vim.cmd("edit " .. vim.fn.fnameescape(abs_path))

    -- Get the buffer number of the newly opened file
    bufnr = vim.fn.bufnr(abs_path)
    if bufnr == -1 then return end  -- Shouldn't happen, but just in case

    -- Read the buffer content (this is the "after" — the new version on disk)
    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Diff the git baseline (old) vs current file (new) and highlight
    highlight_external_changes(bufnr, old_lines, new_lines)
  end
end

-- FS_EVENT CALLBACK
-- This function is called by libuv every time a file changes in our watched directory.
-- It runs OUTSIDE of Neovim's main thread (in libuv's event loop), which is why
-- we need vim.schedule_wrap() below to safely call Neovim APIs.
--
-- Parameters (provided by libuv automatically):
--   err:      error string if something went wrong, nil if OK
--   filename: the path of the changed file, RELATIVE to the watched directory
--   events:   table with boolean fields like { change = true } or { rename = true }
local function on_fs_event(err, filename, events)
  -- If there was an error or no filename, nothing we can do
  if err or not filename then return end

  -- FILTER OUT FILES WE DON'T CARE ABOUT
  -- string:match() tests a string against a Lua pattern (like regex but simpler)
  -- Lua patterns: ^ = start, $ = end, %  = escape (NOT backslash like regex)
  --   %.git/ means literal ".git/" (% escapes the dot)
  --   %.swp$ means ends with ".swp"
  if filename:match("^%.git/")       -- Git's internal files (constantly changing)
    or filename:match("%.swp$")      -- Vim swap files (created while editing)
    or filename:match("~$")          -- Backup files (some editors create these)
    or filename:match("%.DS_Store$") -- macOS folder metadata (useless noise)
    or filename:match("^4913$")      -- Neovim writes this to test write permissions
  then
    return  -- Ignore this event entirely
  end

  -- Build the absolute path from the relative filename
  -- vim.uv.cwd() returns the current working directory (like `pwd` in the shell)
  -- We need absolute paths because buffer names in Neovim are absolute
  local cwd = vim.uv.cwd()
  local abs_path = cwd .. "/" .. filename

  -- DEBOUNCING LOGIC
  -- If we already have a timer running for this file (from a recent event),
  -- stop and destroy it — we'll create a fresh one with a full 200ms countdown.
  -- This way, rapid-fire events only trigger ONE reload after they stop.
  if debounce_timers[abs_path] then
    debounce_timers[abs_path]:stop()   -- Stop the countdown
    debounce_timers[abs_path]:close()  -- Free the libuv resource (important!)
    debounce_timers[abs_path] = nil    -- Remove from our tracking table
  end

  -- Create a new libuv timer
  -- vim.uv.new_timer() returns a timer handle — it's a libuv object, not a number
  local timer = vim.uv.new_timer()
  debounce_timers[abs_path] = timer  -- Store it so we can cancel it later

  -- Start the timer:
  --   arg1: delay in ms (wait this long before firing)
  --   arg2: repeat interval (0 = fire once, don't repeat)
  --   arg3: callback function to run when timer fires
  --
  -- vim.schedule_wrap() is CRITICAL here. Libuv callbacks run in a separate
  -- thread from Neovim's main loop. If you call vim.cmd() or vim.api.* directly
  -- from a libuv callback, Neovim will crash or behave unpredictably.
  -- vim.schedule_wrap() wraps our function so it gets queued into Neovim's
  -- main event loop and runs safely. Think of it like JavaScript's setTimeout
  -- posting to the main thread — same concept.
  timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
    -- Timer fired! Clean up the timer first.
    timer:stop()
    timer:close()
    debounce_timers[abs_path] = nil

    -- Now safely process the file change (we're on Neovim's main thread now)
    process_file_change(abs_path)
  end))
end

-- START WATCHING THE CURRENT DIRECTORY
-- Creates a libuv fs_event watcher on the current working directory.
-- { recursive = true } means it watches ALL subdirectories too.
-- Every time a file changes anywhere in the tree, on_fs_event is called.
local function start_watcher()
  -- Don't create a second watcher if one is already running
  if watcher_handle then return end

  local cwd = vim.uv.cwd()  -- Get the current working directory

  -- vim.uv.new_fs_event() creates a new filesystem event watcher handle
  -- This is a libuv object that talks to the OS kernel's file notification system:
  --   macOS: uses FSEvents (efficient, kernel-level)
  --   Linux: uses inotify
  --   Windows: uses ReadDirectoryChangesW
  watcher_handle = vim.uv.new_fs_event()

  if watcher_handle then
    -- handle:start(path, options, callback)
    --   path: directory to watch
    --   { recursive = true }: watch all subdirectories (not just top-level)
    --   on_fs_event: our callback function defined above
    watcher_handle:start(cwd, { recursive = true }, on_fs_event)
  end
end

-- STOP THE WATCHER AND CLEAN EVERYTHING UP
-- Called when changing directories (so we can start watching the new dir)
-- and when quitting Neovim (so we don't leak resources).
local function stop_watcher()
  -- Clean up any pending debounce timers
  -- pairs() iterates over all key-value pairs in a table (like Object.entries in JS)
  for path, timer in pairs(debounce_timers) do
    timer:stop()                  -- Stop the countdown
    timer:close()                 -- Free the libuv resource
    debounce_timers[path] = nil   -- Remove from table
  end

  -- Clean up the watcher handle itself
  if watcher_handle then
    watcher_handle:stop()    -- Stop listening for events
    watcher_handle:close()   -- Free the OS resource
    watcher_handle = nil     -- Clear our reference so start_watcher() can create a new one
  end
end

-- ===== END NEW SOLUTION =====

-- Save buffer content when first loaded from disk
-- This ensures we always have a baseline to diff against,
-- even if FileChangedShell doesn't fire (autoread bypasses it)
autocmd("BufReadPost", {
  desc = "Save buffer snapshot for external change diffing",
  group = "CheckTime",
  callback = function(args)
    local bufnr = args.buf
    -- Only snapshot real files, not special buffers
    if vim.bo[bufnr].buftype == "" then
      pre_reload_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end
  end,
})

-- Also snapshot after saving (so the baseline matches what's on disk)
autocmd("BufWritePost", {
  desc = "Update buffer snapshot after save",
  group = "CheckTime",
  callback = function(args)
    local bufnr = args.buf
    if vim.bo[bufnr].buftype == "" then
      pre_reload_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end
  end,
})

-- FileChangedShell fires BEFORE buffer is reloaded (when change is detected)
-- With autoread=true this may not always fire, but when it does,
-- it gives us the freshest pre-reload content
autocmd("FileChangedShell", {
  desc = "Save buffer content before external reload",
  group = "CheckTime",
  callback = function(args)
    local bufnr = args.buf
    -- Always capture the latest content right before reload
    pre_reload_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    -- Tell Neovim to reload the buffer
    vim.v.fcs_choice = "reload"
  end,
})

autocmd("FileChangedShellPost", {
  desc = "Highlight changed lines after external file modification",
  group = "CheckTime",
  callback = function(args)
    -- Skip if already handled by fs_event watcher
    if claude_reloading[args.buf] then return end

    local bufnr = args.buf
    local old_lines = pre_reload_content[bufnr]

    if not old_lines or #old_lines == 0 then
      pre_reload_content[bufnr] = nil
      vim.notify("File reloaded (no previous content to diff)", vim.log.levels.INFO)
      return
    end

    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    highlight_external_changes(bufnr, old_lines, new_lines)
  end,
})

-- WATCHER LIFECYCLE AUTOCMDS
-- These autocmds manage the watcher's lifetime:
-- start it when Neovim opens, restart it if you :cd somewhere else,
-- and clean it up when you quit.

-- VimEnter fires once, right after Neovim finishes starting up.
-- This is the right time to start watching — the UI is ready, cwd is set.
autocmd("VimEnter", {
  desc = "Start fs_event watcher for external change detection",
  group = "CheckTime",
  callback = start_watcher,  -- Just pass the function reference (no () — we're not calling it here)
})

-- DirChanged fires when you change the working directory (e.g., :cd ~/other-project)
-- The old watcher is still watching the OLD directory, so we need to:
--   1. Stop the old watcher (stop_watcher)
--   2. Start a new one in the new directory (start_watcher)
autocmd("DirChanged", {
  desc = "Restart fs_event watcher in new directory",
  group = "CheckTime",
  callback = function()
    stop_watcher()
    start_watcher()
  end,
})

-- VimLeave fires right before Neovim exits.
-- We stop the watcher to free OS resources cleanly.
-- Without this, the libuv handle would be garbage-collected eventually,
-- but it's good practice to clean up explicitly.
autocmd("VimLeave", {
  desc = "Stop fs_event watcher on exit",
  group = "CheckTime",
  callback = stop_watcher,
})

-- Keymap to clear the external change highlights
-- User presses this when they've reviewed the changes
vim.keymap.set("n", "<leader>ch", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, external_change_ns, 0, -1)
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
