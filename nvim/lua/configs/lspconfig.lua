-- LSP Configuration

-- code complition, go to definition, find references
-- diagnostics (errors, warnings), hover documentation
-- code actions (quick fixes), rename symbol, and more


local M = {}
local map = vim.keymap.set

-- on_attach CALLBACK
-- This function runs whenever an LSP server attaches to a buffer
-- sets up buffer-local keymaps for LSP features

M.on_attach = function(_, bufnr)
  -- Helper function to create keymap options with a description
  -- buffer = bufnr makes the keymap only work in this specific buffer
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  -- NAVIGATION KEYMAPS
  -- These let you jump to different code locations

  -- gD: Go to Declaration
  -- Declaration is where something is introduced (e.g., in C: 'extern int x;' or a function prototype). 
  -- It states that something exists without providing the actual implementation or value.
  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")

  -- gd: Go to Definition
  -- Definition is where the entity is given its actual meaning or value 
  -- (e.g., 'int x = 5;' or a function implementation). 
  -- You can't have multiple definitions, but you can have multiple declarations.
  map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")

  -- WORKSPACE MANAGEMENT
  -- What is an "LSP workspace"?  
  -- Workspace in LSP (Language Server Protocol) - is a set of folders and files that the language 
  -- server treats as a single project.
  -- This allows the language server to understand your codebase 
  -- even if it spans multiple directories, which is common in monorepos or projects with separate library/app folders.
  --
  -- Why do you need LSP workspace management?
  -- If your project uses code from multiple folders 
  -- (for example, shared libraries, or code generated into a separate folder),
  -- letting the LSP know about all relevant folders enables features such as
  --  "go to definition" and code completion to work across directories.
  -- If you don't add all relevant folders, the language server may not find all symbols, 
  -- resulting in incomplete or missing language features.
  -- These keymaps below let you add or remove folders from the current LSP workspace, 
  -- so LSP features work across your entire codebase, not just a single folder.
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  
  -- Leader+wr: Remove a folder from the workspace
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

  -- Leader+wl: List all workspace folders
  -- Prints the list of folders the LSP is aware of
  -- This keymap prints the current list of folders in your LSP workspace.
  -- Pressing <leader>wl will call vim.lsp.buf.list_workspace_folders() and print the result.
  -- vim.inspect formats the output as a readable Lua table in the command line.
  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")

  -- CODE INTELLIGENCE

  -- Go to type definition
  -- For a variable, jumps to where its TYPE is defined
  -- e.g., for "local x: MyClass", jumps to MyClass definition
  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  
  -- Leader+ra: Rename symbol across the project
  -- Uses NvChad's custom renamer UI instead of the basic one
  map("n", "<leader>ra", require "nvchad.lsp.renamer", opts "NvRenamer")
end


-- on_init CALLBACK

-- This function runs when an LSP server first initializes
-- Used to configure server behavior before it starts processing

M.on_init = function(client, _)
  -- Disable semantic tokens (LSP-based syntax highlighting)
  -- Why disable? Treesitter provides better, more consistent highlighting
  -- Semantic tokens can conflict with treesitter and cause flickering
   -- Check Neovim version because the API changed in 0.11
   if vim.fn.has "nvim-0.11" ~= 1 then
    -- Neovim < 0.11: Use supports_method as a function call
    if client.supports_method "textDocument/semanticTokens" then
      -- Set capability to nil to disable semantic tokens
      client.server_capabilities.semanticTokensProvider = nil
    end
  else
    -- Neovim >= 0.11: Use supports_method as a method call (with colon)
    if client:supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end
end


-- Starts with default capabilities from Neovim's LSP protocol module
M.capabilities = vim.lsp.protocol.make_client_capabilities()


-- Enhance completion capabilities
-- These tell the LSP what completion features we support
M.capabilities.textDocument.completion.completionItem = {
    -- We can display documentation in markdown or plain text
    documentationFormat = { "markdown", "plaintext" },
    
    -- We support snippets (completions that expand into templates)
    snippetSupport = true,
    
    -- We support preselecting the "best" completion item
    preselectSupport = true,
    
    -- We support insertReplace mode (replacing existing text)
    insertReplaceSupport = true,
    
    -- We can show extra label details (like function signatures)
    labelDetailsSupport = true,
    
    -- We can show deprecated items differently (usually strikethrough)
    deprecatedSupport = true,
    
    -- We support commit characters (characters that auto-confirm completion)
    commitCharactersSupport = true,
    
    -- We support completion item tags (like deprecated markers)
    tagSupport = { valueSet = { 1 } },
    
    -- We support resolving additional info lazily
    -- This improves performance by loading docs only when needed
    resolveSupport = {
      properties = {
        "documentation",        -- Fetch documentation lazily
        "detail",               -- Fetch detail text lazily
        "additionalTextEdits",  -- Fetch extra edits (like auto-imports) lazily
      },
    },
  }
  
  -- DEFAULTS FUNCTION
  -- Sets up the default LSP configuration for all servers
  
  M.defaults = function()
    -- Load base46's LSP theme for consistent diagnostic colors
    dofile(vim.g.base46_cache .. "lsp")
    
    -- Apply NvChad's diagnostic configuration (signs, virtual text, etc.)
    require("nvchad.lsp").diagnostic_config()
  
    -- Create an autocommand that runs our on_attach when any LSP attaches
    -- This ensures keymaps are set up for every buffer with LSP support
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        -- args.buf is the buffer that the LSP attached to
        M.on_attach(_, args.buf)
      end,
    })
  
    -- LUA LANGUAGE SERVER SETTINGS
    -- Special configuration for Lua development (Neovim config writing)
    
    local lua_lsp_settings = {
      Lua = {
        -- Tell the LSP we're using LuaJIT (Neovim's Lua runtime)
        runtime = { version = "LuaJIT" },
        
        -- Add Neovim's Lua libraries to the LSP's understanding
        -- This gives you completions for vim.api, vim.fn, etc.
        workspace = {
          library = {
            -- Neovim's runtime Lua files (core API)
            vim.fn.expand "$VIMRUNTIME/lua",
            -- NvChad's type definitions for better completions
            vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
            -- lazy.nvim's Lua files (for plugin development)
            vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
            -- luv (libuv bindings) library types
            "${3rd}/luv/library",
          },
        },
      },
    }
  
    -- NEOVIM 0.11+ LSP CONFIGURATION API
    -- Neovim 0.11 introduced a new way to configure LSP servers
  
    -- Apply our capabilities and on_init to ALL LSP servers
    -- "*" is a wildcard that matches any server name
    vim.lsp.config("*", { capabilities = M.capabilities, on_init = M.on_init })
    
    -- Apply Lua-specific settings to the lua_ls (lua-language-server)
    vim.lsp.config("lua_ls", { settings = lua_lsp_settings })
    
    -- Enable the Lua language server
    -- This tells Neovim to start lua_ls when editing Lua files
    vim.lsp.enable "lua_ls"
    
    -- Enable HTML and CSS language servers
    -- These provide completions and diagnostics for HTML/CSS files
    local servers = { "html", "cssls" }
    vim.lsp.enable(servers)
  end
  
  -- Export the module so other files can require() it
  return M






