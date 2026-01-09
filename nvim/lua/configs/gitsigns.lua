-- Gitsigns Configuration
-- gitsigns.nvim shows git diff indicators in the sign column (left gutter)
-- It shows: added lines, modified lines, deleted lines, and provides git actions

-- Load base46's git theme for consistent sign colors with NvChad's themes
-- This ensures the git signs match your current colorscheme
dofile(vim.g.base46_cache .. "git")

-- Return the configuration table
-- Most options use defaults; we only customize the sign characters
return {
  -- SIGN CHARACTERS
  -- These are the icons shown in the sign column (gutter) next to changed lines
  -- Each sign type can have a custom text character
  
  signs = {
    -- delete: Shows where lines were removed
    -- 󰍵 is a Nerd Font icon (trash/delete icon)
    -- Default signs for add, change, etc. are kept (usually vertical bars)
    delete = { text = "󰍵" },
    
    -- changedelete: Shows where lines were both changed AND deleted
    -- 󱕖 is a Nerd Font icon representing modified-delete
    -- This happens when you modify a line and delete adjacent lines
    changedelete = { text = "󱕖" },
  },
  
  -- OTHER OPTIONS (using defaults)
  
  -- Gitsigns has many other options that use sensible defaults:
  -- signs.add = { text = "│" }           -- Added lines (green bar)
  -- signs.change = { text = "│" }        -- Modified lines (blue bar)
  -- signs.topdelete = { text = "‾" }     -- Deleted line at top of hunk
  -- signcolumn = true                     -- Show signs in sign column
  -- numhl = false                         -- Don't highlight line numbers
  -- linehl = false                        -- Don't highlight entire lines
  -- word_diff = false                     -- Don't show word-level diff
  -- current_line_blame = false            -- Don't show inline git blame
  -- current_line_blame_opts = {...}       -- Blame display options
  -- watch_gitdir = { interval = 1000 }    -- Check for git changes every 1s
  -- attach_to_untracked = true            -- Show signs for untracked files
}
