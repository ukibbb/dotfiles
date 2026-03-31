--------------------------------------------------------------------------------
-- claude.dev
--
-- Development helpers for working on claude.nvim itself.
--
-- Owns:
--   - Clearing cached claude.* modules from package.loaded
--   - Re-running setup() after a reload
--   - Convenience keymaps for reload, reload+test, and debug info
--
-- Does NOT own:
--   - Normal plugin behavior
--   - Runtime popup state
--
-- How this module relates to the refactor:
-- The plugin is now split into focused modules. reload() clears all of them so
-- a test run always uses fresh code from disk.
--------------------------------------------------------------------------------

local M = {}

--------------------------------------------------------------------------------
-- reload()
--
-- Clears every loaded module whose name starts with "claude" and then re-runs
-- require("claude").setup().
--
-- Why clear all claude.* modules instead of only the main one?
-- Lua caches modules independently. If claude.render stayed cached while
-- claude.init reloaded, the entry point would be fresh but the renderer would
-- still be old code.
--------------------------------------------------------------------------------
function M.reload()
  local cleared = {}

  local ok_existing, existing = pcall(require, "claude")
  if ok_existing and existing and existing.close then
    pcall(existing.close)
  end

  for name, _ in pairs(package.loaded) do
    if name:match("^claude") then
      package.loaded[name] = nil
      table.insert(cleared, name)
    end
  end

  local ok, err = pcall(function()
    require("claude").setup()
  end)

  if ok then
    vim.notify("Reloaded: " .. table.concat(cleared, ", "), vim.log.levels.INFO, { title = "claude.nvim" })
  else
    vim.notify("Reload failed: " .. tostring(err), vim.log.levels.ERROR, { title = "claude.nvim" })
  end

  return ok
end

--------------------------------------------------------------------------------
-- reload_and_test()
--
-- Reloads the plugin and then opens the popup right away.
--
-- The schedule() wrapper gives setup() one event-loop tick to recreate commands,
-- keymaps, and config before we ask the public API to open the popup.
--------------------------------------------------------------------------------
function M.reload_and_test()
  if M.reload() then
    vim.schedule(function()
      require("claude").open()
    end)
  end
end

function M.debug_info()
  local loaded = {}

  for name, _ in pairs(package.loaded) do
    if name:match("^claude") then
      table.insert(loaded, name)
    end
  end

  table.sort(loaded)

  if #loaded > 0 then
    vim.notify(
      "Loaded modules:\n  " .. table.concat(loaded, "\n  "),
      vim.log.levels.INFO,
      { title = "claude.nvim debug" }
    )
  else
    vim.notify("No claude modules currently loaded", vim.log.levels.WARN, { title = "claude.nvim debug" })
  end
end

--------------------------------------------------------------------------------
-- setup()
--
-- Installs development keymaps when you are editing this plugin.
--
-- These mappings are intentionally global in the current Neovim session because
-- they are part of your development workflow, not part of the popup itself.
--------------------------------------------------------------------------------
function M.setup()
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

return M
