-- Automatic Commands (Event Handlers)
-- Autocommands run code automatically when events occur  
-- Opening a file, saving, entering/leaving a buffer, etc.                 
-- Like event listeners in JavaScript                                     

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

-- Table to store buffer contents BEFORE reload
-- Key = buffer number, Value = array of lines
-- We need this to compare old vs new content after reload
local pre_reload_content = {}

-- Define custom highlight groups for changed/deleted lines
-- guibg = background color in GUI/truecolor terminals
-- Changed/added lines = green background
vim.api.nvim_set_hl(0, "ExternalChangeAdd", { bg = "#2d4f2d" })
-- Deleted lines = red background (shown as virtual lines)
vim.api.nvim_set_hl(0, "ExternalChangeDel", { bg = "#4f2d2d" })

-- FileChangedShell fires BEFORE buffer is reloaded (when change is detected)
-- We use this to save the current content for comparison
-- The hook from Claude sends :checktime which triggers this event chain
autocmd("FileChangedShell", {
  desc = "Save buffer content before external reload",
  group = "CheckTime",
  callback = function(args)
    local bufnr = args.buf
    -- Save current content BEFORE Neovim reloads the file
    -- This will be compared in FileChangedShellPost
    pre_reload_content[bufnr] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    -- Return nil to let autoread handle the reload
  end,
})

autocmd("FileChangedShellPost", {
  -- FileChangedShellPost fires AFTER buffer is reloaded from disk
  -- At this point, buffer contains NEW content, but we saved OLD content above
  desc = "Highlight changed lines after external file modification",
  group = "CheckTime",
  callback = function(args)
    local bufnr = args.buf
    local old_lines = pre_reload_content[bufnr]

    -- If we don't have previous content, we can't diff properly
    -- This happens on first load or if FileChangedShell didn't fire
    if not old_lines or #old_lines == 0 then
      pre_reload_content[bufnr] = nil
      vim.notify("File reloaded (no previous content to diff)", vim.log.levels.INFO)
      return
    end

    -- DEBUG: uncomment to see what's being compared
    -- vim.notify(string.format("DEBUG: old=%d lines, new=%d lines", #old_lines, #new_lines), vim.log.levels.DEBUG)

    -- Get the new content (what was just loaded from disk)
    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Clear any existing highlights from previous external changes
    -- nvim_buf_clear_namespace(buffer, namespace, start_line, end_line)
    -- -1 for end means "to the end of buffer"
    vim.api.nvim_buf_clear_namespace(bufnr, external_change_ns, 0, -1)

    -- Use vim.diff to get proper diff hunks between old and new content
    -- This handles insertions, deletions, and changes properly
    local old_text = table.concat(old_lines, "\n") .. "\n"
    local new_text = table.concat(new_lines, "\n") .. "\n"

    local diff = vim.diff(old_text, new_text, {
      result_type = "indices", -- Returns line ranges instead of patch text
      algorithm = "histogram", -- Better diff algorithm
    })

    local added_count = 0
    local deleted_count = 0

    -- diff returns list of hunks: {old_start, old_count, new_start, new_count}
    for _, hunk in ipairs(diff) do
      local old_start, old_count, new_start, new_count = unpack(hunk)

      -- Highlight added/changed lines in green (full line block)
      -- Using extmarks with line_hl_group + hl_eol for full window-width background
      for i = new_start, new_start + new_count - 1 do
        if i <= #new_lines then
          local line_len = #new_lines[i]
          vim.api.nvim_buf_set_extmark(bufnr, external_change_ns, i - 1, 0, {
            end_col = line_len,
            hl_group = "ExternalChangeAdd",
            hl_eol = true, -- Extend highlight to end of window
            line_hl_group = "ExternalChangeAdd", -- Full line green background
            priority = 100,
          })
          added_count = added_count + 1
        end
      end

      -- Show deleted lines as virtual lines with red background
      -- These appear above the line where deletion occurred
      if old_count > 0 then
        local deleted_lines = {}
        -- Get window width to pad virtual lines to full width
        local win_width = vim.api.nvim_win_get_width(0)
        for i = old_start, old_start + old_count - 1 do
          if old_lines[i] then
            -- Pad line with spaces to fill window width for block effect
            local line_text = "- " .. old_lines[i]
            local padding = string.rep(" ", math.max(0, win_width - #line_text))
            -- Each virt_line is a list of {text, highlight} chunks
            table.insert(deleted_lines, { { line_text .. padding, "ExternalChangeDel" } })
            deleted_count = deleted_count + 1
          end
        end

        if #deleted_lines > 0 then
          -- Place virtual lines at the position where content was deleted
          -- new_start is where in the new file the deletion "happened"
          local insert_line = math.min(new_start, #new_lines)
          if insert_line < 1 then insert_line = 1 end

          vim.api.nvim_buf_set_extmark(bufnr, external_change_ns, insert_line - 1, 0, {
            virt_lines = deleted_lines,
            virt_lines_above = true, -- Show above the current line
            priority = 100,
          })
        end
      end
    end

    -- Clean up stored content (free memory)
    pre_reload_content[bufnr] = nil

    -- Notify user with count of changed lines
    vim.notify(
      string.format("File reloaded: +%d/-%d lines. <leader>ch to clear highlights.", added_count, deleted_count),
      vim.log.levels.WARN
    )
  end,
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
