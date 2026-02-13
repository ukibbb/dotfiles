--------------------------------------------------------------------------------
-- Claude.nvim Development Helpers
--
-- This module provides hot-reloading and development utilities.
-- It loads automatically when you open any file in claude.nvim/lua/
-- (configured in your autocmds.lua)
--
--------------------------------------------------------------------------------
-- QUICK REFERENCE
--------------------------------------------------------------------------------
--
--   KEYMAPS (available after setup):
--   ┌─────────────┬─────────────────────────────────────────────────────────┐
--   │ <leader>rr  │ Reload all claude modules (use after editing)          │
--   │ <leader>rt  │ Reload AND open popup (fastest way to test changes)    │
--   │ <leader>rd  │ Show debug info about loaded modules                   │
--   └─────────────┴─────────────────────────────────────────────────────────┘
--
--------------------------------------------------------------------------------
-- DEVELOPMENT WORKFLOW
--------------------------------------------------------------------------------
--
--   1. OPEN NEOVIM
--      Just open any file in the claude.nvim folder - dev mode auto-activates
--      You'll see: "claude.nvim dev mode activated!"
--
--   2. EDIT → TEST LOOP (the fast part!)
--      a) Make changes to init.lua or gui.lua
--      b) Press <leader>rt (reload + test)
--      c) The popup opens immediately with your changes
--      d) Close popup with q or <Esc>
--      e) Repeat!
--
--   3. DEBUGGING
--      - If something breaks, press <leader>rd to see loaded modules
--      - Check :messages for error details
--      - Use print() or vim.notify() in your code for debug output
--
--------------------------------------------------------------------------------
-- PRO TIPS
--------------------------------------------------------------------------------
--
--   TIP 1: USE <leader>rt CONSTANTLY
--   Don't manually test by typing :Claude - just hit <leader>rt after every
--   change. It's one keypress vs many, and ensures you always test fresh code.
--
--   TIP 2: SPLIT YOUR TERMINAL
--   Run Neovim in a split terminal. Keep one pane for editing, use <leader>rt
--   to test. This way you can see both code and result without switching.
--
--   TIP 3: ADD TEMPORARY DEBUG PRINTS
--   When debugging, add vim.notify() calls to see what's happening:
--     vim.notify("Got here! value = " .. vim.inspect(some_table))
--   Remove them before committing.
--
--   TIP 4: USE vim.inspect() FOR TABLES
--   Lua tables don't print nicely. Always use vim.inspect():
--     print(vim.inspect(my_table))  -- Shows full table structure
--
--   TIP 5: CHECK :messages FOR ERRORS
--   If reload fails silently, run :messages to see the full error.
--   Also try :lua require("claude") directly to see stack traces.
--
--   TIP 6: TEST VISUAL SELECTION
--   To test with selection context:
--   1. Select some text in visual mode (v or V)
--   2. Press <leader>ac (your normal claude keymap)
--   Hot reload doesn't preserve visual mode, so use normal keymap for this.
--
--   TIP 7: WATCH OUT FOR STATE
--   Module-level variables (like M.current_model) persist across reloads.
--   If you add new state, you might need to restart Neovim to reset it.
--
--   TIP 8: EXTMARKS CAN PILE UP
--   If highlights look wrong after reload, the popup might have stale extmarks.
--   Close and reopen the popup to clear them.
--
--------------------------------------------------------------------------------

local M = {}

--------------------------------------------------------------------------------
-- HOW NEOVIM MODULE LOADING WORKS
--
-- When you call require("claude"), Neovim:
--   1. Checks if package.loaded["claude"] exists (cached)
--   2. If cached, returns the cached version immediately
--   3. If not cached, searches runtimepath for lua/claude/init.lua
--   4. Executes the file and stores result in package.loaded["claude"]
--
-- PROBLEM: Changes to files are NOT reflected until you restart Neovim,
-- because the module stays cached in package.loaded.
--
-- SOLUTION: Clear the cache before re-requiring. That's what reload() does.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- reload()
-- Clears all claude.* modules from cache and re-requires the main module.
--
-- HOW IT WORKS:
-- 1. Iterate through package.loaded (table of all loaded modules)
-- 2. Find any module name starting with "claude"
-- 3. Set it to nil (removes from cache)
-- 4. Re-require the main module
--
-- WHY CLEAR ALL SUBMODULES?
-- If you only clear "claude" but not "claude.gui", then when init.lua
-- does require("claude.gui"), it gets the OLD cached version.
-- Clearing all claude.* ensures a complete fresh load.
--------------------------------------------------------------------------------
function M.reload()
  -- Count cleared modules for feedback
  local cleared = {}

  -- package.loaded is a table: { ["module.name"] = <module table>, ... }
  -- pairs() iterates over all key-value pairs
  for name, _ in pairs(package.loaded) do
    -- string.match with ^ anchors to start of string
    -- So "^claude" matches "claude", "claude.gui", "claude.dev", etc.
    if name:match("^claude") then
      package.loaded[name] = nil
      table.insert(cleared, name)
    end
  end

  -- Re-require and setup the plugin
  -- pcall = "protected call" - catches errors instead of crashing
  -- Returns: success (bool), result or error message
  local ok, err = pcall(function()
    require("claude").setup()
  end)

  if ok then
    -- vim.notify is the modern way to show messages (supports plugins like nvim-notify)
    -- vim.log.levels.INFO makes it a non-intrusive info message
    vim.notify(
      "Reloaded: " .. table.concat(cleared, ", "),
      vim.log.levels.INFO,
      { title = "claude.nvim" }
    )
  else
    -- vim.log.levels.ERROR makes it a red error message
    vim.notify(
      "Reload failed: " .. tostring(err),
      vim.log.levels.ERROR,
      { title = "claude.nvim" }
    )
  end

  return ok
end

--------------------------------------------------------------------------------
-- reload_and_test()
-- Reloads the plugin AND opens the popup immediately.
-- This is the fastest way to test changes - one keypress does everything.
--
-- WHY vim.schedule()?
-- Ensures the module is fully loaded before trying to use it.
-- vim.schedule queues the function to run on the next event loop iteration.
-- This prevents race conditions where open_popup runs before setup completes.
--------------------------------------------------------------------------------
function M.reload_and_test()
  if M.reload() then
    vim.schedule(function()
      require("claude").open_popup()
    end)
  end
end

--------------------------------------------------------------------------------
-- debug_info()
-- Shows which claude modules are currently loaded.
-- Useful for debugging module loading issues.
--
-- USE THIS WHEN:
-- - Reload seems to have no effect (module might not be clearing)
-- - You're not sure if a submodule is loaded
-- - Debugging require() issues
--------------------------------------------------------------------------------
function M.debug_info()
  local loaded = {}

  for name, _ in pairs(package.loaded) do
    if name:match("^claude") then
      table.insert(loaded, name)
    end
  end

  -- table.sort modifies in place (Lua convention)
  table.sort(loaded)

  if #loaded > 0 then
    vim.notify(
      "Loaded modules:\n  " .. table.concat(loaded, "\n  "),
      vim.log.levels.INFO,
      { title = "claude.nvim debug" }
    )
  else
    vim.notify(
      "No claude modules currently loaded",
      vim.log.levels.WARN,
      { title = "claude.nvim debug" }
    )
  end
end

--------------------------------------------------------------------------------
-- setup()
-- Creates the development keymaps.
--
-- Called automatically when you open a file in claude.nvim/lua/
-- (via the autocmd in your autocmds.lua)
--
-- KEYMAP DESIGN:
-- - <leader>r prefix groups all reload-related commands
-- - rr = "reload reload" (double tap for most common action)
-- - rt = "reload test"
-- - rd = "reload debug"
--------------------------------------------------------------------------------
function M.setup()
  -- vim.keymap.set(mode, key, action, opts)
  -- mode: "n" = normal mode
  -- desc: shows in which-key and :map output

  vim.keymap.set("n", "<leader>rr", M.reload, {
    desc = "Reload claude.nvim",
  })

  vim.keymap.set("n", "<leader>rt", M.reload_and_test, {
    desc = "Reload claude.nvim and test",
  })

  vim.keymap.set("n", "<leader>rd", M.debug_info, {
    desc = "Show claude.nvim debug info",
  })

  vim.notify(
    "Dev mode: <leader>rr (reload) | <leader>rt (reload+test) | <leader>rd (debug)",
    vim.log.levels.INFO,
    { title = "claude.nvim" }
  )
end

--------------------------------------------------------------------------------
-- Module return
-- Returns the table so functions are accessible via require():
--   require("claude.dev").reload()
--   require("claude.dev").setup()
--------------------------------------------------------------------------------
return M
