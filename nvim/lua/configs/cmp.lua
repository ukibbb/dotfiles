-- nvim-cmp is the autocompletion engine - it shows suggestions as you type
-- This file configures how completions are displayed and interacted with

-- Load base46's cmp theme for consistent styling with NvChad's themes
-- dofile() executes a Lua file, vim.g.base46_cache is the path to cached themes
dofile(vim.g.base46_cache .. "cmp")

-- Load the nvim-cmp module
local cmp = require "cmp"

-- Define our completion options
local options = {
  -- COMPLETION BEHAVIOR
  
  completion = { 
    -- completeopt controls how the completion menu behaves
    -- "menu" = show completion menu
    -- "menuone" = show menu even if there's only one match (useful to see docs)
    completeopt = "menu,menuone" 
  },

  -- SNIPPET EXPANSION
  
  snippet = {
    -- This function tells cmp how to expand snippets when you select them
    -- We use LuaSnip as our snippet engine, so we call its expand function
    expand = function(args)
      -- args.body contains the snippet text that needs to be expanded
      require("luasnip").lsp_expand(args.body)
    end,
  },

  -- KEYBINDINGS
  -- These control how you interact with the completion menu
  
  mapping = {
    -- Ctrl+p: Select previous item in the completion menu (p = previous)
    -- Standard Vim convention for "previous" in lists
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    
    -- Ctrl+n: Select next item in the completion menu (n = next)
    ["<C-n>"] = cmp.mapping.select_next_item(),
    
    -- Ctrl+d: Scroll documentation window DOWN by 4 lines
    -- When hovering a completion item, this scrolls its documentation
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    
    -- Ctrl+f: Scroll documentation window UP by 4 lines (f = forward)
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    
    -- Ctrl+Space: Manually trigger completion menu
    -- Useful when completion doesn't auto-appear or you dismissed it
    ["<C-Space>"] = cmp.mapping.complete(),
    
    -- Ctrl+e: Close the completion menu without selecting anything (e = exit)
    ["<C-e>"] = cmp.mapping.close(),

    -- Enter: Confirm the selected completion
    -- behavior = Insert means insert the completion at cursor position
    -- select = true means confirm even if nothing is explicitly selected
    --   (uses the first/highlighted item)
    ["<CR>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    },

    -- Tab: Smart tab behavior - does different things based on context
    -- This is a function mapping that checks the current state
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        -- If completion menu is open, select next item
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        -- If inside a snippet, expand it or jump to next placeholder
        -- Snippets have "tabstops" - positions you can jump between
        require("luasnip").expand_or_jump()
      else
        -- Otherwise, just insert a regular tab character
        -- fallback() calls the original Tab behavior
        fallback()
      end
    end, { "i", "s" }), -- Works in insert (i) and select (s) modes

    -- Shift+Tab: Reverse of Tab - go backwards
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        -- If menu is open, select previous item
        cmp.select_prev_item()
      elseif require("luasnip").jumpable(-1) then
        -- If inside a snippet, jump to previous placeholder
        -- -1 means jump backwards
        require("luasnip").jump(-1)
      else
        -- Otherwise, default behavior (usually does nothing or un-indents)
        fallback()
      end
    end, { "i", "s" }),
  },

  -- COMPLETION SOURCES
  -- Sources provide the actual completion candidates
  -- Order matters: first sources have higher priority in the menu
  
  sources = {
    -- LSP completions: Most important source
    -- Provides language-aware completions (functions, types, variables, etc.)
    -- This is what makes completion "smart" and context-aware
    { name = "nvim_lsp" },
    
    -- Snippet completions from LuaSnip
    -- Shows available snippets that match what you're typing
    { name = "luasnip" },
    
    -- Buffer completions: Words from the current buffer
    -- Useful fallback when LSP doesn't have suggestions
    { name = "buffer" },
    
    -- Neovim Lua API completions
    -- Only useful when writing Neovim config or plugins
    -- Provides vim.api, vim.fn, vim.lsp, etc.
    { name = "nvim_lua" },
    
    -- File path completions (async version for better performance)
    -- When you type a path like "./src/", it shows matching files
    { name = "async_path" },
  },
}

return options
