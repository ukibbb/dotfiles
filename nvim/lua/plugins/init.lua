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
      -- Load base46 theme colors for the indent lines
      dofile(vim.g.base46_cache .. "blankline")

      -- Register hooks to hide indentation on first space level
      -- This prevents an indent line at column 0 which looks weird
      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)

      -- Setup the plugin with our options
      require("ibl").setup(opts)

      -- Reload theme (ensures colors are applied correctly)
      dofile(vim.g.base46_cache .. "blankline")
    end,
  },



  -- CODE FORMATTING
  -- conform.nvim: Code formatter that runs external formatters (prettier, black, etc.)
  -- Faster and more reliable than LSP formatting for most use cases

  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
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

  -- Lazygit: Terminal UI for git inside Neovim
  -- Full git interface with staging, committing, rebasing, and conflict resolution
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open Lazygit" },
    },
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
    -- Use the master branch (some plugins require specific branches)
    branch = "master",
    -- Load when opening or creating files
    event = { "BufReadPost", "BufNewFile" },
    -- Also load when these commands are used
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    -- Run :TSUpdate after install to compile the parsers
    build = ":TSUpdate",
    opts = function()
      return require "configs.treesitter"
    end,
    config = function(_, opts)
      -- Setup treesitter with our configuration
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- FILE MANAGER
  -- Oil: Edit your filesystem like a buffer
  -- Navigate directories and rename/move/delete files using normal editing commands
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
    opts = {
      -- Automatically open preview when entering Oil buffer
      view_options = {
        show_hidden = true,
      },
      preview_win = {
        update_on_cursor_moved = true,
      },
      keymaps = {
        ["<C-p>"] = "actions.preview",
        ["q"] = "actions.close",
      },
    },
    config = function(_, opts)
      require("oil").setup(opts)
      -- Auto-open preview when Oil buffer is entered
      vim.api.nvim_create_autocmd("User", {
        pattern = "OilEnter",
        callback = vim.schedule_wrap(function(args)
          local oil = require("oil")
          if vim.api.nvim_get_current_buf() == args.data.buf and oil.get_cursor_entry() then
            oil.open_preview()
          end
        end),
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

  -- CLAUDE.NVIM
  {
    dir = "~/Desktop/dotfiles/claude.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
