-- Treesitter Configuration
-- nvim-treesitter provides advanced syntax highlighting and code understanding
-- Unlike traditional regex-based highlighting, treesitter actually PARSES code
-- This gives accurate highlighting that understands language structure

-- Load base46's syntax and treesitter themes
-- pcall() = protected call, won't error if files don't exist
-- This provides graceful degradation if themes aren't cached yet
pcall(function()
  -- Load syntax highlight colors (general code colors)
  dofile(vim.g.base46_cache .. "syntax")
  -- Load treesitter-specific highlight colors
  dofile(vim.g.base46_cache .. "treesitter")
end)

-- Return the configuration table
return {
  -- PARSER INSTALLATION
  -- Treesitter needs language-specific parsers to understand each language
  
  -- List of parsers to install automatically
  -- These are the minimum parsers needed for basic Neovim config editing
  ensure_installed = {
    "lua",        -- Lua language (for Neovim config)
    "luadoc",     -- Lua documentation comments
    "printf",     -- Printf-style format strings (used in many languages)
    "vim",        -- Vimscript language
    "vimdoc",     -- Vim documentation (help files)
    "python",     -- Python language
    "typescript", -- TypeScript language
    "tsx",        -- TypeScript with JSX (React)
    "javascript", -- JavaScript (needed for TypeScript projects)
  },
  
  -- You can add more parsers based on languages you use:
  -- "javascript", "typescript", "python", "rust", "go", "c", "cpp",
  -- "html", "css", "json", "yaml", "markdown", "bash", etc.
  -- Or install them on-demand with :TSInstall <language>

  -- HIGHLIGHTING
  -- The main feature - syntax highlighting using tree-sitter parsing
  
  highlight = {
    -- Enable treesitter-based syntax highlighting
    -- This replaces Vim's traditional regex-based highlighting
    -- Much more accurate: understands code structure, not just patterns
    enable = true,
    
    -- Use languagetree for embedded languages
    -- Example: correctly highlights JavaScript inside HTML <script> tags
    -- Each embedded language gets its own parser
    use_languagetree = true,
  },

  -- INDENTATION
  -- Treesitter can calculate correct indentation based on code structure
  
  indent = { 
    -- Enable treesitter-based automatic indentation
    -- When you press Enter, treesitter figures out the correct indent level
    -- Based on actual code structure (inside function? inside if block? etc.)
    enable = true 
  },
  
  -- OTHER MODULES (using defaults or disabled)

  -- Treesitter has many other modules that can be enabled:
  
  -- incremental_selection = { enable = true }
  --   Expand selection based on syntax: select word -> statement -> function -> file
  
  -- textobjects = { ... }
  --   Define text objects like "function", "class", "parameter" for motions
  --   Example: daf = delete a function, vif = select inside function
  
  -- folding = { enable = true }
  --   Code folding based on syntax structure (fold functions, classes, etc.)
  
  -- refactor = { ... }
  --   Highlighting for same variables, smart rename, etc.
  
  -- playground = { ... }
  --   Debug tool to explore the syntax tree
}
