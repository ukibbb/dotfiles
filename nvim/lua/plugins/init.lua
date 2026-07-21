local dotfiles_dir = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath("config")), ":h")

return {
  -- CORE
  -- plenary.nvim: Lua utility library (like lodash for Neovim Lua)
  -- Many plugins require this. Contains async helpers, path utils, etc.
  -- We don't configure it - just need it available for other plugins
  "nvim-lua/plenary.nvim",

  -- nvim-web-devicons: Provides file type icons
  -- Required by many plugins (NvChad UI, telescope, file managers, etc.)
  "nvim-tree/nvim-web-devicons",


  -- NVCHAD UI
  -- Base46: NvChad's theming engine
  -- init.lua loads dofile(vim.g.base46_cache .. "defaults")
  -- Pre-compiled theme highlights for fast startup
  -- The build function generates cached highlight files after install/update
  {
    "nvchad/base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  -- NvChad UI: Provides the renamer component
  -- Your lspconfig uses require "nvchad.lsp.renamer"
  --  nvchad.lsp.renamer, nvchad.lsp.diagnostic_config()
  -- lazy = false means load immediately (required for LSP setup)
  {
    "nvchad/ui",
    lazy = false,
    config = function()
      require "nvchad"
    end,
  },


  -- Volt: NvChad's UI framework for building floating windows and popups
  -- Used by NvChad's theme picker, cheatsheet, and other UI elements
  "nvzone/volt",

  -- Menu: Right-click context menu support for NvChad
  "nvzone/menu",

  -- Minty: Color picker utilities (Huefy = color picker, Shades = shade generator)
  -- cmd = {...} means lazy-load only when these commands are used
  { "nvzone/minty", cmd = { "Huefy", "Shades" } },


  -- INDENT GUIDES
  -- indent-blankline: Shows vertical lines at indentation levels
  -- Makes it easier to see code structure and nested blocks
  {
    "lukas-reineke/indent-blankline.nvim",
    -- Load after a real file is opened (not on empty buffer)
    event = "User FilePost",
    opts = {
      -- Character to use for indent lines (│ is a clean vertical bar)
      indent = { char = "│", highlight = "IblChar" },
      -- Scope shows the current block you're in with a different highlight
      scope = { char = "│", highlight = "IblScopeChar" },
    },
    config = function(_, opts)
      -- pcall = "protected call". It tries to run the function but if the file
      -- doesn't exist yet (e.g. cache was deleted), it just skips instead of crashing.
      -- The cache gets rebuilt when you run :lua require("base46").load_all_highlights()
      local ok = pcall(dofile, vim.g.base46_cache .. "blankline")
      -- If cache is missing, create temporary fallback highlights so ibl doesn't crash
      if not ok then
        vim.api.nvim_set_hl(0, "IblChar", { fg = "#3b3f4c" })
        vim.api.nvim_set_hl(0, "IblScopeChar", { fg = "#5c6370" })
      end

      -- Register hooks to hide indentation on first space level
      -- This prevents an indent line at column 0 which looks weird
      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)

      -- Setup the plugin with our options
      require("ibl").setup(opts)

      -- Reload theme (ensures colors are applied correctly)
      pcall(dofile, vim.g.base46_cache .. "blankline")
    end,
  },



  -- CODE FORMATTING
  -- conform.nvim: Code formatter that runs external formatters (prettier, black, etc.)
  -- Faster and more reliable than LSP formatting for most use cases

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- LINTING
  -- nvim-lint: Asynchronous linter plugin
  -- Runs mypy on save for Python type checking (complements pyright)
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      local mypy_missing_notified = false

      if vim.fn.executable("mypy") == 1 then
        lint.linters_by_ft = { python = { "mypy" } }
      else
        lint.linters_by_ft = {}
      end

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("Lint", { clear = true }),
        callback = function(args)
          if vim.bo[args.buf].filetype ~= "python" then return end

          if vim.fn.executable("mypy") ~= 1 then
            if not mypy_missing_notified then
              vim.notify("nvim-lint: mypy is not installed or not on PATH; skipping Python lint.", vim.log.levels.WARN)
              mypy_missing_notified = true
            end
            return
          end

          mypy_missing_notified = false
          lint.try_lint()
        end,
      })
    end,
  },


  -- nvim-lspconfig: Configurations for LSP servers
  -- Your configs/lspconfig.lua uses vim.lsp.config() and vim.lsp.enable()
  -- Pre-configured settings for language servers (lua_ls, html, cssls)
  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    config = function()
      -- Load your custom LSP configuration
      require("configs.lspconfig").defaults()
    end,
  },

  -- GIT INTEGRATION
  {
    "lewis6991/gitsigns.nvim",
    -- Load when editing a real file
    event = "User FilePost",
    opts = function()
      -- Load config from our separate gitsigns config file
      return require "configs.gitsigns"
    end,
  },

  -- Unified: Inline unified diffs in buffer
  -- Shows git diff inline without a separate window, with file tree for changed files
  {
    "axkirillov/unified.nvim",
    cmd = "Unified",
    keys = {
      { "<leader>gd", "<cmd>Unified<cr>", desc = "Toggle inline diff" },
    },
    opts = {},
  },

  -- LSP (LANGUAGE SERVER PROTOCOL)
  -- Mason: Package manager for LSP servers, formatters, linters, DAP adapters
  -- Provides a nice UI for installing and managing these external tools
  {
    "mason-org/mason.nvim",
    -- Only load when these commands are used (manual installation)
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = function()
      -- Load config from our separate mason config file
      return require "configs.mason"
    end,
  },

  -- AUTOCOMPLETION

  -- nvim-cmp: Autocompletion engine - the popup that suggests completions as you type
  -- This is the core plugin; it needs "sources" to provide completion candidates
  {
    "hrsh7th/nvim-cmp",
    -- Only load when entering insert mode (when you start typing)
    event = "InsertEnter",
    -- Dependencies are plugins that nvim-cmp needs to function
    dependencies = {
      {
        -- LuaSnip: Snippet engine - expands shortcuts into code templates
        -- Example: typing "fn" and pressing Tab could expand to a full function definition
        "L3MON4D3/LuaSnip",
        -- friendly-snippets provides a large collection of pre-made snippets
        dependencies = "rafamadriz/friendly-snippets",
        opts = {
          -- history = true allows jumping back to previous snippet positions
          history = true,
          -- Update snippet placeholders as you type (real-time updates)
          updateevents = "TextChanged,TextChangedI"
        },
        config = function(_, opts)
          -- Apply LuaSnip configuration
          require("luasnip").config.set_config(opts)
          -- Load our snippet configuration (loads snippet files)
          require "configs.luasnip"
        end,
      },

      {
        -- nvim-autopairs: Automatically insert closing brackets, quotes, etc.
        -- Type "(" and it automatically adds ")"
        "windwp/nvim-autopairs",
        opts = {
          -- fast_wrap lets you wrap existing text with pairs using Alt+e
          fast_wrap = {},
          -- Don't auto-pair in these special buffers
          disable_filetype = { "TelescopePrompt", "vim" },
        },
        config = function(_, opts)
          require("nvim-autopairs").setup(opts)

          -- Integrate autopairs with nvim-cmp
          -- When you confirm a completion that ends with a pair character,
          -- autopairs will handle the closing character correctly
          local cmp_autopairs = require "nvim-autopairs.completion.cmp"
          require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
      },
      {
        "saadparwaiz1/cmp_luasnip",  -- Snippets from LuaSnip as completion items
        "hrsh7th/cmp-nvim-lua",       -- Neovim Lua API completions (for plugin dev)
        "hrsh7th/cmp-nvim-lsp",       -- LSP completions (most important source)
        "hrsh7th/cmp-buffer",         -- Words from the current buffer
        "https://codeberg.org/FelipeLema/cmp-async-path.git", -- File path completions (async version)
      },
    },
    opts = function()
      -- Load our main cmp configuration
      return require "configs.cmp"
    end,
  },

  -- FUZZY FINDER

  -- Telescope: Fuzzy finder for files, text, buffers, git, and more
  -- The Swiss Army knife of Neovim - find anything quickly
  {
    "nvim-telescope/telescope.nvim",
    -- Telescope uses treesitter for syntax highlighting in previews
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- Only load when :Telescope command is used
    cmd = "Telescope",
    opts = function()
      return require "configs.telescope"
    end,
  },

  -- SYNTAX HIGHLIGHTING

  -- Treesitter: Advanced syntax highlighting using real parsers (not regex)
  -- Provides: accurate highlighting, code folding, text objects, and more
  -- Much better than Vim's traditional regex-based syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    -- The master branch is frozen; Neovim 0.12 requires the new main branch API.
    branch = "main",
    -- Upstream does not support lazy-loading on the main branch.
    lazy = false,
    -- Run :TSUpdate after install to compile the parsers
    build = ":TSUpdate",
    opts = function()
      return require "configs.treesitter"
    end,
    config = function(_, opts)
      local treesitter = require "nvim-treesitter"

      treesitter.setup(opts.setup)

      for filetype, parser in pairs(opts.parsers_by_filetype or {}) do
        vim.treesitter.language.register(parser, filetype)
      end

      if opts.ensure_installed and #opts.ensure_installed > 0 then
        treesitter.install(opts.ensure_installed)
      end

      local indent_filetypes = {}
      for _, filetype in ipairs(opts.indent_filetypes or {}) do
        indent_filetypes[filetype] = true
      end

      vim.api.nvim_create_autocmd("FileType", {
        desc = "Start treesitter",
        group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
        pattern = opts.highlight_filetypes,
        callback = function(args)
          if pcall(vim.treesitter.start, args.buf) and indent_filetypes[vim.bo[args.buf].filetype] then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- MARKDOWN RENDERING
  -- render-markdown.nvim: Enhanced markdown rendering with treesitter
  -- Renders markdown with proper formatting, heading highlights, code blocks, etc.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- Only load for markdown files
    ft = "markdown",
    -- Requires treesitter for markdown parsing
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = function()
      return require "configs.render-markdown"
    end,
  },

  -- REMOTE DEVELOPMENT
  -- distant.nvim: Edit files, run programs, and use LSP on remote machines
  -- Enables seamless development on Raspberry Pi or other remote servers
  {
    "chipsenkbeil/distant.nvim",
    branch = "v0.3",
    -- Load when distant commands are used
    cmd = {
      "DistantInstall",
      "DistantClientVersion",
      "DistantConnect",
      "DistantLaunch",
      "DistantOpen",
      "DistantShell",
      "DistantSpawn",
    },
    opts = function()
      return require "configs.distant"
    end,
    config = function(_, opts)
      require("distant"):setup(opts)
    end,
  },

  -- TMUX INTEGRATION
  -- vim-tmux-navigator: Seamless navigation between tmux panes and Neovim splits
  -- Allows Ctrl+h/j/k/l to move between Neovim splits AND tmux panes
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },

  -- NVIM-TREE
  -- File explorer sidebar with git integration and icons
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
      { "<leader>E", "<cmd>NvimTreeFindFile<cr>", desc = "Find file in explorer" },
    },
    opts = function()
      local api = require "nvim-tree.api"
      local function on_attach(bufnr)
        -- Apply all default mappings first
        api.config.mappings.default_on_attach(bufnr)
        local opts = { buffer = bufnr, noremap = true, silent = true }
        -- Cmd+\ → open in vertical split (via Karabiner)
        vim.keymap.set("n", "<M-C-\\>", api.node.open.vertical, vim.tbl_extend("force", opts, { desc = "Open: Vertical Split" }))
        -- Cmd+- → open in horizontal split (via Karabiner)
        vim.keymap.set("n", "<M-C-_>", api.node.open.horizontal, vim.tbl_extend("force", opts, { desc = "Open: Horizontal Split" }))
      end
      return {
        on_attach = on_attach,
      filters = {
        dotfiles = false,
      },
      disable_netrw = true,
      hijack_netrw = true,
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      view = {
        side = "left",
        width = 35,
        preserve_window_proportions = true,
      },
      renderer = {
        root_folder_label = false,
        highlight_git = "name",
        icons = {
          glyphs = {
            default = "󰈚",
            folder = {
              default = "",
              empty = "",
              empty_open = "",
              open = "",
              symlink = "",
            },
            git = {
              unmerged = "",
              untracked = "★",
            },
          },
        },
      },
      actions = {
        open_file = {
          quit_on_open = false,
        },
      },
      git = {
        enable = true,
        ignore = false,
      },
      filesystem_watchers = {
        ignore_dirs = { ".next", "node_modules", ".git" },
      },
    }
    end,
  },

  -- NEOGIT
  -- Magit-inspired git interface - powerful interactive git UI
  -- Full git workflow: staging, committing, branching, rebasing, etc.
  -- Replaces lazygit with a native Neovim experience
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",        -- Required
      "sindrets/diffview.nvim",        -- For diff integration
      "nvim-telescope/telescope.nvim", -- For fuzzy finding
    },
    cmd = "Neogit",
    keys = {
      -- <leader>gg = "git gui" - main entry point (same as old lazygit binding)
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit: open" },
      -- Quick access to common popups
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit: commit" },
      { "<leader>gp", "<cmd>Neogit push<cr>", desc = "Neogit: push" },
      { "<leader>gP", "<cmd>Neogit pull<cr>", desc = "Neogit: pull" },
      { "<leader>gb", "<cmd>Neogit branch<cr>", desc = "Neogit: branch" },
    },
    opts = {
      -- APPEARANCE
      -- Open in a new tab (like lazygit) - other options: "split", "floating", "vsplit"
      kind = "tab",

      -- Show hints at bottom of status buffer (helpful for learning)
      disable_hint = false,

      -- Graph style for commit history
      -- "ascii" = basic, "unicode" = prettier lines, "kitty" = requires kitty terminal
      graph_style = "unicode",

      -- Signs in the gutter
      signs = {
        hunk = { "", "" },
        item = { "", "" },
        section = { "", "" },
      },

      -- INTEGRATIONS
      integrations = {
        -- Use telescope for fuzzy menus
        telescope = true,
        -- Use diffview for viewing diffs (you have it installed)
        diffview = true,
      },

      -- BEHAVIOR
      -- Automatically refresh when git files change
      filewatcher = {
        enabled = true,
      },

      -- Remember cursor position in status buffer
      remember_settings = true,

      -- Auto show console output on errors
      console_timeout = 2000,

      -- COMMIT EDITOR
      commit_editor = {
        kind = "tab",           -- Open commit editor in new tab
        show_staged_diff = true, -- Show diff of staged changes
      },

      -- MAPPINGS
      -- Default mappings are intuitive, but listed here for reference:
      -- s = stage, u = unstage, x = discard, c = commit, P = push, F = fetch
      -- Tab = toggle section, Enter = go to item, q = close
    },
  },

  -- DIFFVIEW.NVIM
  -- Git diff viewer with file panel - browse all changed files in one tabpage
  -- Great for: reviewing PRs, browsing history, resolving merge conflicts
  -- Complements codediff.nvim (diffview = file navigation, codediff = char-level diffs)
  {
    "sindrets/diffview.nvim",
    -- Lazy load on commands
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      -- <leader>gv = "git view" - open diff view for all changed files
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open" },
      -- Compare against a specific branch (e.g., main)
      { "<leader>gm", "<cmd>DiffviewOpen origin/main...HEAD<cr>", desc = "Diffview: vs main" },
      -- <leader>gl = "git log" - file history browser
      { "<leader>gl", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
      -- History for entire repo
      { "<leader>gL", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: repo history" },
      -- Close diffview from anywhere
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
    },
    opts = {
      -- Use diff3 conflict style (shows base in middle)
      diff_binaries = false,
      enhanced_diff_hl = true,  -- Better diff highlighting

      -- FILE PANEL (left sidebar)
      file_panel = {
        listing_style = "tree",  -- "list" or "tree"
        tree_options = {
          flatten_dirs = true,   -- Flatten single-child directories
          folder_statuses = "only_folded",  -- Show status on folders
        },
        win_config = {
          position = "left",
          width = 35,
        },
      },

      -- KEY MAPPINGS
      -- These apply inside diffview tabs
      keymaps = {
        view = {
          -- Navigation between files
          { "n", "<tab>", "<cmd>DiffviewFocusFiles<cr>", { desc = "Focus file panel" } },
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
        file_panel = {
          -- File panel specific
          { "n", "j", "j", { desc = "Move down" } },
          { "n", "k", "k", { desc = "Move up" } },
          { "n", "<cr>", "<cmd>DiffviewOpen<cr>", { desc = "Open diff" } },
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          -- Staging
          { "n", "s", "<cmd>DiffviewStageFile<cr>", { desc = "Stage file" } },
          { "n", "-", "<cmd>DiffviewStageFile<cr>", { desc = "Stage file" } },
          { "n", "S", "<cmd>DiffviewStageAllFiles<cr>", { desc = "Stage all" } },
          { "n", "u", "<cmd>DiffviewUnstageFile<cr>", { desc = "Unstage file" } },
          { "n", "U", "<cmd>DiffviewUnstageAllFiles<cr>", { desc = "Unstage all" } },
        },
        file_history_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
      },

      -- HOOKS
      -- Customize behavior at certain events
      hooks = {
        -- Disable fold column in diff views for cleaner look
        diff_buf_read = function()
          vim.opt_local.foldcolumn = "0"
        end,
      },
    },
  },

  -- CODEDIFF.NVIM
  -- VSCode-style side-by-side diff with character-level highlighting
  -- Uses VSCode's diff algorithm (implemented in C) for accurate diffs
  -- Much better than built-in vimdiff for reviewing changes
  {
    "esmuellert/codediff.nvim",
    -- Requires nui.nvim for the UI components
    dependencies = { "MunifTanjim/nui.nvim" },
    -- Lazy load on command (C library downloads automatically on first use)
    cmd = "CodeDiff",
    keys = {
      -- <leader>gD = "git Diff" - compare current file with git
      { "<leader>gD", "<cmd>CodeDiff<cr>", desc = "CodeDiff explorer" },
      -- Compare current buffer with HEAD (most common use case)
      { "<leader>gf", function()
          local file = vim.fn.expand("%")
          if file ~= "" then
            vim.cmd("CodeDiff file " .. file .. " HEAD")
          else
            vim.notify("No file in current buffer", vim.log.levels.WARN)
          end
        end,
        desc = "Diff file vs HEAD"
      },
      -- View file history (commits that touched this file)
      { "<leader>gh", "<cmd>CodeDiff history<cr>", desc = "File history" },
    },
    opts = {
      -- Highlight groups for diff colors
      -- These link to standard diff highlights by default
      -- Customize if you want different colors
      highlights = {
        added_line = "DiffAdd",        -- Green background for added lines
        removed_line = "DiffDelete",   -- Red background for removed lines
        added_char = "DiffText",       -- Deeper green for added characters
        removed_char = "DiffText",     -- Deeper red for removed characters
      },
    },
  },

  -- WATCHDIFF.NVIM
  -- Detects external file changes and highlights diffs inline
  {
    dir = dotfiles_dir .. "/watchdiff.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- CLAUDE.NVIM
  {
    dir = dotfiles_dir .. "/claude.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
