-- Mason Configuration
-- Mason is a package manager for LSP servers, formatters, linters, and DAP adapters
-- It provides a nice UI (:Mason) to install and manage these external tools

-- Load base46's mason theme for consistent styling with NvChad's themes
-- This styles the Mason UI window to match your colorscheme
dofile(vim.g.base46_cache .. "mason")

-- Return the configuration table
return {
  -- PATH SETTING
  
  -- PATH = "skip" tells Mason to NOT modify the system PATH
  -- Why? Because we already add Mason's bin directory to PATH in options.lua
  -- Having both would be redundant and could cause issues
  -- Options: "prepend" (add to start), "append" (add to end), "skip" (don't modify)
  PATH = "skip",

  -- UI CONFIGURATION
  -- These settings customize how the :Mason window looks
  
  ui = {
    -- Custom icons for package status indicators
    -- These replace the default ASCII characters with Nerd Font icons
    icons = {
      -- Pending: Package is being installed/updated (loading spinner)
      package_pending = " ",
      
      -- Installed: Package is successfully installed (checkmark)
      package_installed = " ",
      
      -- Uninstalled: Package is available but not installed (X mark)
      package_uninstalled = " ",
    },
  },

  -- INSTALLATION SETTINGS
  
  -- Maximum number of packages that can be installed simultaneously
  -- Higher = faster bulk installs, but uses more system resources
  -- Default is 4, 10 is more aggressive for faster setup
  max_concurrent_installers = 10,
  
  -- OTHER OPTIONS (using defaults)
  
  -- Mason has many other options that use sensible defaults:
  -- pip = { ... }                   -- Python pip settings
  -- github = { ... }                -- GitHub download settings  
  -- log_level = vim.log.levels.INFO -- Logging verbosity
  -- install_root_dir = ...          -- Where to install packages
  -- registries = { ... }            -- Package registries to use
}
