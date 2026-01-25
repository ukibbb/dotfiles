-- Telescope Configuration
-- Telescope is a highly extensible fuzzy finder for files, text, buffers, etc.
-- It's like Ctrl+P/Cmd+P in VS Code but much more powerful.

-- Load base46's telescope theme for consistent styling with NvChad's themes
dofile(vim.g.base46_cache .. "telescope")

-- Return the configuration table
return {
  -- DEFAULT SETTINGS
  -- These apply to all Telescope pickers unless overridden
  
  defaults = {
    -- Hide .git internals but show .github, .gitignore, etc.
    file_ignore_patterns = { "^.git/" },

    -- PROMPT APPEARANCE
    -- The text shown before where you type in the prompt
    -- "   " includes a search icon (Nerd Font) and padding
    prompt_prefix = "   ",
    
    -- Icon shown next to the currently selected item in results
    --  is a small arrow/chevron pointing right
    selection_caret = " ",
    
    -- Prefix for non-selected entries (just spacing for alignment)
    entry_prefix = " ",

    -- LAYOUT SETTINGS
    
    -- Results ordering: "ascending" puts best matches at the TOP
    -- "descending" would put them at the bottom
    -- "ascending" means you type and the best match is right above your prompt
    sorting_strategy = "ascending",
    
    -- Configuration for the picker window dimensions
    layout_config = {
      horizontal = {
        -- Position the prompt (input) at the top of the window
        -- This works well with ascending sort: prompt at top, results below
        prompt_position = "top",
        
        -- Preview window takes 55% of the width
        -- The results list gets the remaining 45%
        preview_width = 0.55,
      },
      -- Telescope window takes 87% of the editor width
      width = 0.87,
      -- Telescope window takes 80% of the editor height
      height = 0.80,
    },

    -- KEYBINDINGS
    
    mappings = {
      -- Normal mode mappings (when you press Escape in telescope)
      n = {
        -- Press "q" to close telescope (vim-like quit)
        -- By default, you'd need to press <Esc> or <C-c>
        ["q"] = require("telescope.actions").close
      },

      -- Insert mode mappings (default mode when telescope opens)
      i = {
        ["<M-j>"] = require("telescope.actions").move_selection_next,
        ["<M-k>"] = require("telescope.actions").move_selection_previous,
      },
    },
  },

  -- PICKERS
  -- Configure individual pickers (find_files, live_grep, etc.)
  pickers = {
    find_files = {
      hidden = true,  -- Show dotfiles
    },
    live_grep = {
      additional_args = function()
        return { "--hidden" }
      end,
    },
  },

  -- EXTENSIONS
  -- Telescope extensions add extra functionality

  -- List of extension names to load
  -- "themes" = NvChad's theme picker extension
  extensions_list = { "themes" },
  
  -- Extension-specific configuration (empty = use defaults)
  extensions = {},
  
  -- OTHER OPTIONS (using defaults)
  
  -- Many other options use sensible defaults:
  -- file_ignore_patterns = {}     -- Patterns to exclude from searches
  -- file_sorter = ...             -- Algorithm for sorting results
  -- generic_sorter = ...          -- Sorter for non-file searches
  -- path_display = {}             -- How to display file paths
  -- winblend = 0                  -- Window transparency (0 = opaque)
  -- border = true                 -- Show border around telescope
  -- color_devicons = true         -- Colorize file icons
}
