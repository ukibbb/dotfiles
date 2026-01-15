-- neovim entry point

-- vim.g global variables accessible everywhere in Neovim

-- leader key - before plugins, plugins read this value
vim.g.mapleader = " "

-- vim.fn.stdpath("data") returns ~/.local/share/nvim - where neovim stores data
-- Construct the path where lazy.nvim will be installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Set the cache directory for base46 (NvChad's theming engine)
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"

-- vim.uv is Neovim's async I/O library (libuv bindings)
-- Check if lazy.nvim is NOT installed yet (vim.uv.fs_stat returns nil if path doesn't exist)
if not vim.uv.fs_stat(lazypath) then
    local repo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
  end

-- vim.opt.rtp = runtime path (where Neovim looks for Lua modules)
-- prepend() adds to the BEGINNING of the path (highest priority)
-- Now Neovim can find lazy.nvim with require("lazy")
vim.opt.rtp:prepend(lazypath)



-- Initialize lazy.nvim plugin manager
-- "plugins" means: load lua/plugins/init.lua (or all files in lua/plugins/)
require("lazy").setup(
  "plugins",
  {
    -- defaults.lazy = true means plugins are NOT loaded until needed
    -- This makes Neovim start faster (plugins load on-demand)
    defaults = { lazy = true },

    -- install.colorscheme = fallback theme if your chosen theme fails to load
    -- "nvchad" will be loaded from base46 plugin
    install = { colorscheme = { "nvchad" } },

    -- checker.enabled = false disables automatic update checking
    -- Set to true if you want lazy.nvim to notify you about updates
    checker = { enabled = false },

    -- change_detection.notify = false stops "Config changed" notifications
    -- These can be annoying when editing your config
    change_detection = { notify = false },

    -- performance.rtp.disabled_plugins = disable built-in plugins we don't need
    -- This speeds up startup by not loading unused code
    performance = {
      rtp = {
        -- List of built-in Vim plugins to disable for faster startup and less bloat.
        disabled_plugins = {
          "2html_plugin",        -- :TOhtml command, rarely used (export buffer to HTML)
          "bugreport",           -- :BugReport, not necessary for most users
          "compiler",            -- Compiler plugins (not needed for standard workflows)
          "getscript",           -- :GetScript command (rarely used)
          "getscriptPlugin",     -- Plugin for :GetScript
          "gzip",                -- Editing .gz files (not common)
          "logipat",             -- Plugin for :lpattern command
          "matchit",             -- Extends % matching (modern plugins or treesitter do this better)
          "netrw",               -- Built-in file explorer (use nvim-tree or alternatives)
          "netrwPlugin",         -- Plugin part of netrw (disable all of netrw)
          "netrwSettings",       -- Netrw settings files
          "netrwFileHandlers",   -- File handlers for netrw
          "optwin",              -- :options window
          "rplugin",             -- Remote plugin (not commonly used)
          "rrhelper",            -- R help support (not needed for most)
          "spellfile_plugin",    -- Spellfile plugin (disable if not using vim spellfiles)
          "synmenu",             -- Syntax menu support
          "syntax",              -- Syntax plugin (disable if using treesitter)
          "tar",                 -- Editing .tar files
          "tarPlugin",           -- Plugin for tar files
          "tutor",               -- :Tutor command, for Vim beginners
          "vimball",             -- Vimball archives support
          "vimballPlugin",       -- Plugin for vimballs
          "zip",                 -- Editing .zip files
          "zipPlugin",           -- Plugin for zip files
          "ftplugin",            -- Filetype plugins (disable if set elsewhere)
        },
      },
    },
  }
)

-- Load pre-compiled theme files using dofile (not require)
-- dofile executes Lua files directly - faster for compiled bytecode files
-- These must be loaded AFTER lazy.nvim setup but BEFORE options/mappings
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

-- Load editor options (line numbers, tabs, etc.)
require("options")

-- Load autocommands (automatic actions on events)
require("autocmds")

-- Load keybindings DEFERRED using vim.schedule
-- vim.schedule delays execution to the next event loop iteration
-- WHY? Ensures all plugins are fully loaded before applying keybindings
-- Prevents race conditions where a mapping might reference an unloaded plugin
vim.schedule(function()
  require("mappings")
end)
