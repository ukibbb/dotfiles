--------------------------------------------------------------------------------
-- Claude.nvim - A popup interface for Claude AI
--
-- This is the main entry point for the plugin. It handles:
--   1. Plugin configuration and setup
--   2. State management (open windows, current context)
--   3. User interactions (keymaps, commands)
--   4. Coordinating the GUI module
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- LUA CONCEPT: Module Pattern
-- Same pattern as gui.lua - we create a table M, attach public functions,
-- and return it at the end. This file is loaded via require("claude") or
-- require("claude.init") - Lua treats init.lua as the default module file
-- for a directory (like index.js in Node.js).
--------------------------------------------------------------------------------
local M = {}

--------------------------------------------------------------------------------
-- LUA CONCEPT: require() with Submodules
-- When you have lua/claude/gui.lua, you require it as "claude.gui".
-- The dot notation maps to directory structure: claude/gui.lua
-- This creates a nice namespace hierarchy for organizing plugin code.
--------------------------------------------------------------------------------
local gui = require("claude.gui")

--------------------------------------------------------------------------------
-- LUA CONCEPT: Module-level State
-- M.config is public (attached to M) - users can read/modify it.
-- `state` is private (local) - only this file can access it.
--
-- This is a common pattern: expose configuration but hide internal state.
-- The state table holds runtime data that shouldn't persist between sessions.
--------------------------------------------------------------------------------
M.config = {
  width = 70,
  input_height = 3,
}

local state = {
  handles = nil,  -- Window/buffer handles from gui module
  ns = nil,       -- Namespace for extmarks
  context = nil,  -- Visual selection data
}

--------------------------------------------------------------------------------
-- VISUAL SELECTION HELPER
-- Captures the current visual selection before opening the popup.
--
-- NEOVIM API: vim.fn.mode()
-- Returns current mode as a string: "n" (normal), "v" (visual char),
-- "V" (visual line), "\22" or "^V" (visual block), "i" (insert), etc.
--
-- NEOVIM API: vim.fn.getpos(expr)
-- Gets position of a mark. Returns [bufnum, lnum, col, off].
-- - "v" = start of current visual selection (only valid IN visual mode)
-- - "." = current cursor position (end of selection in visual mode)
-- - "'<" / "'>" = last visual selection (set AFTER leaving visual mode)
--
-- NEOVIM API: vim.api.nvim_buf_get_lines(buf, start, end, strict)
-- - buf: 0 means current buffer
-- - start/end: 0-indexed, end is exclusive
-- - strict: false allows out-of-bounds without error
--------------------------------------------------------------------------------
local function get_visual_selection()
  local mode = vim.fn.mode()

  -- Check if we're in any visual mode (v, V, or Ctrl-V block mode)
  -- LUA: string.match() returns nil if pattern doesn't match
  -- "\22" is the Lua escape for Ctrl-V (ASCII 22)
  if not mode:match("[vV\22]") then
    return nil
  end

  -- While IN visual mode, use "v" for selection start and "." for cursor (end)
  -- getpos returns: [bufnum, lnum, col, off]
  local start_pos = vim.fn.getpos("v")  -- Where visual selection started
  local end_pos = vim.fn.getpos(".")    -- Current cursor position

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  -- Ensure start <= end (user can select bottom-to-top)
  -- LUA: Multiple assignment for swapping values
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Get the selected lines (convert to 0-indexed for nvim API)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  return {
    lines = #lines,                        -- Number of lines selected
    text = table.concat(lines, "\n"),      -- The actual text content
    start_line = start_line,               -- 1-indexed start line
    end_line = end_line,                   -- 1-indexed end line
  }
end

--------------------------------------------------------------------------------
-- CLEANUP FUNCTION
-- Local function = private, can't be called from outside this module.
-- Checks if handles exist before trying to close (defensive programming).
-- Sets handles to nil after closing to mark as "not open".
--------------------------------------------------------------------------------
local function close_popup()
  if state.handles then
    gui.close_windows(state.handles)
    state.handles = nil
  end
  state.context = nil
end

--------------------------------------------------------------------------------
-- SUBMIT HANDLER
-- Called when user presses Enter. Currently just prints debug info.
-- The early return pattern (`if not x then return end`) is common in Lua
-- for guard clauses - exit early if preconditions aren't met.
--------------------------------------------------------------------------------
local function on_submit()
  if not state.handles then return end

  ----------------------------------------------------------------------------
  -- NEOVIM API: nvim_buf_get_lines(buf, start, end, strict)
  -- Retrieves lines from a buffer.
  -- - start: 0-indexed start line
  -- - end: -1 means "to the end"
  -- - strict: false allows out-of-bounds indices
  -- Returns a Lua table (array) of strings, one per line.
  ----------------------------------------------------------------------------
  local lines = vim.api.nvim_buf_get_lines(state.handles.input_buf, 0, -1, false)
  local context = state.context

  ----------------------------------------------------------------------------
  -- LUA: print() for Debugging
  -- print() outputs to :messages in Neovim. Multiple arguments are
  -- separated by tabs. For complex tables, use vim.inspect():
  --   print(vim.inspect(lines))
  ----------------------------------------------------------------------------
  print("onSubmit", "lines", lines, "context", context)

  close_popup()
end

--------------------------------------------------------------------------------
-- MAIN POPUP FUNCTION
-- This is public (M.open_popup) so it can be called from keymaps and commands.
--
-- PATTERN: Toggle Behavior
-- If already open, close instead of opening a second popup.
-- This provides a natural UX - same key opens and closes.
--------------------------------------------------------------------------------
function M.open_popup()
  ----------------------------------------------------------------------------
  -- NEOVIM API: nvim_win_is_valid(win)
  -- Returns true if the window handle still points to an open window.
  -- Windows can be closed by the user or other code, so always check
  -- before operating on a window handle.
  --
  -- LUA: Short-circuit Evaluation
  -- `a and b and c` evaluates left-to-right and stops at first falsy value.
  -- Here we check: handles exists AND input_win exists AND window is valid.
  -- If any is false/nil, the whole expression is false and we don't toggle.
  ----------------------------------------------------------------------------
  if state.handles and state.handles.input_win and vim.api.nvim_win_is_valid(state.handles.input_win) then
    close_popup()
    return
  end

  -- Initialize highlight groups (idempotent - safe to call multiple times)
  gui.setup_highlights()

  ----------------------------------------------------------------------------
  -- IMPORTANT: Capture Selection FIRST
  -- Visual selection data is lost when we exit visual mode or switch windows.
  -- We must capture it before doing anything else.
  --
  -- NOTE: get_visual_selection() is referenced but not defined in this file.
  -- This would cause an error - it should be defined or imported.
  ----------------------------------------------------------------------------
  state.context = get_visual_selection()

  ----------------------------------------------------------------------------
  -- NEOVIM API: nvim_feedkeys(keys, mode, escape_ks)
  -- Simulates key presses as if the user typed them.
  -- - keys: the key sequence to send
  -- - mode: "n" = process as if in normal mode mapping
  -- - escape_ks: false = don't escape K_SPECIAL bytes
  --
  -- NEOVIM API: nvim_replace_termcodes(str, from_part, do_lt, special)
  -- Converts special key names like "<Esc>" to their internal representation.
  -- Required because nvim_feedkeys needs actual key codes, not string names.
  -- This is equivalent to Vimscript's escape(str, '\<')
  ----------------------------------------------------------------------------
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

  ----------------------------------------------------------------------------
  -- NEOVIM API: nvim_create_namespace(name)
  -- Creates or retrieves a namespace for extmarks and highlights.
  -- Namespaces let you group decorations so you can clear them together.
  -- Same name always returns the same namespace ID (idempotent).
  ----------------------------------------------------------------------------
  state.ns = vim.api.nvim_create_namespace("claude")

  -- Delegate window creation to the gui module
  state.handles = gui.create_windows(M.config, state.context, state.ns)

  ----------------------------------------------------------------------------
  -- NEOVIM API: vim.cmd(command)
  -- Executes a Vimscript command. "startinsert" enters insert mode.
  -- Equivalent to typing :startinsert in command mode.
  -- For newer code, prefer vim.api functions when available.
  ----------------------------------------------------------------------------
  vim.cmd("startinsert")

  ----------------------------------------------------------------------------
  -- NEOVIM API: vim.keymap.set(mode, lhs, rhs, opts)
  -- Creates a keymap. This is the modern Lua API (Neovim 0.7+).
  -- - mode: "n" = normal, "i" = insert, "v" = visual, etc.
  -- - lhs: the key(s) to press
  -- - rhs: function to call OR string command to execute
  -- - opts: table of options:
  --   - buffer: if set, keymap only applies to this buffer (buffer-local)
  --   - silent: don't show the command in the command line
  --   - desc: description (shows in :map and which-key plugins)
  --
  -- PATTERN: Buffer-local Keymaps
  -- By setting buffer = state.handles.input_buf, these keymaps ONLY work
  -- in the input buffer. They're automatically cleaned up when the buffer
  -- is deleted. This is cleaner than global keymaps with manual cleanup.
  ----------------------------------------------------------------------------
  local opts = { buffer = state.handles.input_buf, silent = true }

  -- Enter to submit (works in both normal and insert mode)
  vim.keymap.set("i", "<CR>", on_submit, opts)
  vim.keymap.set("n", "<CR>", on_submit, opts)

  -- Various ways to close the popup
  vim.keymap.set("n", "q", close_popup, opts)
  vim.keymap.set("n", "<Esc>", close_popup, opts)
  vim.keymap.set("i", "<Esc>", close_popup, opts)
  vim.keymap.set("i", "<C-c>", close_popup, opts)

  ----------------------------------------------------------------------------
  -- LUA CONCEPT: Inline Anonymous Functions
  -- For simple one-off operations, you can define the function inline.
  -- This Ctrl+L handler clears the input buffer.
  ----------------------------------------------------------------------------
  vim.keymap.set("i", "<C-l>", function()
    vim.api.nvim_buf_set_lines(state.handles.input_buf, 0, -1, false, { "" })
  end, opts)

  ----------------------------------------------------------------------------
  -- NEOVIM API: nvim_create_autocmd(events, opts)
  -- Creates an autocommand that fires on specified events.
  -- - events: string or array of event names
  -- - opts.buffer: only fire for this buffer
  -- - opts.once: if true, delete the autocmd after it fires once
  -- - opts.callback: function to run (receives event info as argument)
  --
  -- WinLeave fires when focus leaves a window. We use this to auto-close
  -- the popup when the user clicks elsewhere or switches windows.
  --
  -- NEOVIM API: vim.schedule(fn)
  -- Schedules a function to run "soon" in Neovim's event loop.
  -- Required here because you can't safely close a window from within
  -- a WinLeave event - the window switch isn't complete yet.
  -- vim.schedule defers execution until it's safe.
  ----------------------------------------------------------------------------
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = state.handles.input_buf,
    once = true,
    callback = function()
      vim.schedule(close_popup)
    end,
  })
end

--------------------------------------------------------------------------------
-- PLUGIN SETUP FUNCTION
-- This is the standard entry point for Neovim plugins. Users call it in
-- their config like:
--   require("claude").setup({ width = 80 })
--
-- NEOVIM API: vim.tbl_deep_extend(behavior, ...)
-- Merges tables recursively. "force" means later tables override earlier.
-- Pattern: merge user opts over defaults to allow partial configuration.
--   { a = 1, b = { c = 2 } } + { b = { d = 3 } } = { a = 1, b = { c = 2, d = 3 } }
--
-- LUA: `opts or {}` Default Pattern
-- If opts is nil (user called setup() with no arguments), use empty table.
-- This prevents errors when accessing opts properties.
--------------------------------------------------------------------------------
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  ----------------------------------------------------------------------------
  -- NEOVIM API: vim.keymap.set() for Global Keymaps
  -- Without the buffer option, these are global keymaps.
  -- <leader> is a user-configured prefix key (often space or backslash).
  -- "ac" = "ask claude" - mnemonic naming convention.
  --
  -- Same keymap for both "n" (normal) and "v" (visual) mode means
  -- the popup works with or without a selection.
  ----------------------------------------------------------------------------
  vim.keymap.set("n", "<leader>ac", M.open_popup, { desc = "Ask Claude" })
  vim.keymap.set("v", "<leader>ac", M.open_popup, { desc = "Ask Claude with selection" })

  ----------------------------------------------------------------------------
  -- NEOVIM API: nvim_create_user_command(name, command, opts)
  -- Creates a custom Ex command (like :Claude).
  -- - name: command name (must start with uppercase)
  -- - command: function to call OR string to execute
  -- - opts.desc: description shown in :command output
  --
  -- User can now type :Claude to open the popup.
  ----------------------------------------------------------------------------
  vim.api.nvim_create_user_command("Claude", M.open_popup, { desc = "Open Claude popup" })
end

--------------------------------------------------------------------------------
-- LUA CONCEPT: Module Return
-- Return the module table so require("claude") gives access to:
--   - M.config (configuration table)
--   - M.setup(opts) (initialization function)
--   - M.open_popup() (main function to open the UI)
--------------------------------------------------------------------------------
return M
