local dotfiles_dir = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath "config"), ":h")

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
      local lint = require "lint"
      local mypy_missing_notified = false

      lint.linters_by_ft = { python = { "mypy" } }

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("Lint", { clear = true }),
        callback = function(args)
          if vim.bo[args.buf].filetype ~= "python" then
            return
          end

          if vim.fn.executable "mypy" ~= 1 then
            if not mypy_missing_notified then
              vim.notify("nvim-lint: mypy is not installed or not on PATH; skipping Python lint.", vim.log.levels.WARN)
              mypy_missing_notified = true
            end
            return
          end

          mypy_missing_notified = false
          lint.try_lint "mypy"
        end,
      })
    end,
  },

  -- nvim-lspconfig: Configurations for LSP servers
  -- Your configs/lspconfig.lua uses vim.lsp.config() and vim.lsp.enable()
  -- Pre-configured settings for language servers (lua_ls, html, cssls)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
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
      { "<leader>gd", "<cmd>Unified<cr>", desc = "Open or refresh inline diff" },
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

  -- DEBUGGING
  -- nvim-dap: Debug Adapter Protocol client for Python, Go, and JavaScript/TypeScript
  {
    "mfussenegger/nvim-dap",
    cmd = {
      "DapClearBreakpoints",
      "DapContinue",
      "DapDisconnect",
      "DapEval",
      "DapNew",
      "DapPause",
      "DapRestartFrame",
      "DapSetLogLevel",
      "DapShowLog",
      "DapStepInto",
      "DapStepOut",
      "DapStepOver",
      "DapTerminate",
      "DapToggleBreakpoint",
      "DapToggleRepl",
    },
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
      },
      "mfussenegger/nvim-dap-python",
      "leoluz/nvim-dap-go",
    },
    keys = {
      {
        "<F5>",
        function()
          require("dap").continue()
        end,
        desc = "DAP: start or continue",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "DAP: step over",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "DAP: step into",
      },
      {
        "<F12>",
        function()
          require("dap").step_out()
        end,
        desc = "DAP: step out",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "DAP: toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
        end,
        desc = "DAP: conditional breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "DAP: start or continue",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        mode = { "n", "x" },
        desc = "DAP: evaluate",
      },
      {
        "<leader>dn",
        function()
          if vim.bo.filetype == "python" then
            require("dap-python").test_method()
          elseif vim.bo.filetype == "go" then
            require("dap-go").debug_test()
          else
            vim.notify("Nearest-test debugging is configured for Python and Go only", vim.log.levels.WARN)
          end
        end,
        desc = "DAP: debug nearest test",
      },
      {
        "<leader>dp",
        function()
          require("dap").pause()
        end,
        desc = "DAP: pause",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "DAP: run last",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "DAP: toggle REPL",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "DAP: terminate",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "DAP: toggle UI",
      },
    },
    config = function()
      require("configs.dap").setup()
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
          updateevents = "TextChanged,TextChangedI",
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
      "saadparwaiz1/cmp_luasnip", -- Snippets from LuaSnip as completion items
      "hrsh7th/cmp-nvim-lua", -- Neovim Lua API completions (for plugin dev)
      "hrsh7th/cmp-buffer", -- Words from the current buffer
      "https://codeberg.org/FelipeLema/cmp-async-path.git", -- File path completions (async version)
    },
    opts = function()
      -- Load our main cmp configuration
      return require "configs.cmp"
    end,
    config = function(_, opts)
      local cmp = require "cmp"
      cmp.setup(opts)
      cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "vim-dadbod-completion", priority = 900 },
          { name = "luasnip", priority = 750 },
        }, {
          { name = "nvim_lua", priority = 500 },
          { name = "buffer", priority = 250 },
          { name = "async_path", priority = 200 },
        }),
      })
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

  -- DATABASE CLIENTS

  -- DBee: Full database workspace with connection drawer, SQL scratchpads,
  -- paginated results, and call history. The fork keeps its Go backend patched.
  {
    "ukibbb/nvim-dbee",
    commit = "6f2948a5bc958c0cb85c520c29953148663cd362",
    cmd = "Dbee",
    dependencies = { "MunifTanjim/nui.nvim" },
    build = function(plugin)
      local output_dir = vim.fn.stdpath "data" .. "/dbee/bin"
      local output = output_dir .. "/dbee" .. (vim.fn.has "win32" == 1 and ".exe" or "")
      local candidate = output .. ".tmp-" .. vim.fn.getpid()
      vim.fn.mkdir(output_dir, "p")
      vim.fn.delete(candidate)

      local function abort(message)
        vim.fn.delete(candidate)
        error(message)
      end

      local function run(command, opts)
        local ok, process = pcall(vim.system, command, opts)
        if not ok then
          abort(tostring(process))
        end
        return process:wait()
      end

      local function command_error(result, fallback)
        local stderr = result.stderr or ""
        local stdout = result.stdout or ""
        return stderr ~= "" and stderr or stdout ~= "" and stdout or fallback
      end

      local go_version = run({ "go", "env", "GOVERSION" }, {
        env = { GOTOOLCHAIN = "local" },
        text = true,
      })
      if go_version.code ~= 0 then
        abort(command_error(go_version, "failed to read Go version"))
      end
      if vim.trim(go_version.stdout or "") ~= "go1.26.6" then
        abort("DBee backend requires Go 1.26.6; found " .. vim.trim(go_version.stdout or "unknown"))
      end

      local checkout = run({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }, { text = true })
      if checkout.code ~= 0 then
        abort(command_error(checkout, "failed to read DBee checkout revision"))
      end
      if vim.trim(checkout.stdout or "") ~= plugin.commit then
        abort("DBee checkout does not match the pinned commit " .. plugin.commit)
      end

      local result = run({
        "go",
        "build",
        "-C",
        plugin.dir .. "/dbee",
        "-o",
        candidate,
      }, { env = { CGO_ENABLED = "1", GOTOOLCHAIN = "local" }, text = true })

      if result.code ~= 0 then
        abort(command_error(result, "failed to build DBee backend"))
      end

      local metadata = run({ "go", "version", "-m", candidate }, {
        env = { GOTOOLCHAIN = "local" },
        text = true,
      })
      local metadata_output = metadata.stdout or ""
      if metadata.code ~= 0 then
        abort(command_error(metadata, "failed to read DBee binary metadata"))
      end
      if not metadata_output:find("vcs.revision=" .. plugin.commit, 1, true) then
        abort("DBee binary metadata does not match the pinned commit " .. plugin.commit)
      end
      if not metadata_output:find("vcs.modified=false", 1, true) then
        abort "DBee binary was built from a modified checkout"
      end

      local scan = run({ "govulncheck", "-mode=binary", candidate }, { text = true })
      if scan.code ~= 0 then
        abort(command_error(scan, "DBee backend failed vulnerability scan"))
      end

      local binary_version = run({ candidate, "-version" }, { text = true })
      if binary_version.code ~= 0 or vim.trim(binary_version.stdout or "") ~= plugin.commit then
        abort(command_error(binary_version, "DBee binary does not match the pinned commit"))
      end

      local installed, install_error = vim.uv.fs_rename(candidate, output)
      if not installed then
        abort("failed to install scanned DBee backend: " .. tostring(install_error))
      end
    end,
    keys = {
      {
        "<leader>Bd",
        function()
          require("dbee").toggle()
        end,
        desc = "DBee: toggle database workspace",
      },
    },
    opts = {},
  },

  -- Dbout: Node-backed database client with a Telescope connection manager,
  -- object inspector, SQL formatter, and JSON result viewer.
  {
    "zongben/dbout.nvim",
    commit = "411e46041adeb8661e044f8421d8db5c56a9ef5d",
    cmd = "Dbout",
    build = "npm ci",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      {
        "<leader>Bo",
        function()
          require("telescope").extensions.dbout.dbout()
        end,
        desc = "Dbout: connections",
      },
    },
    opts = {
      keymaps = {
        global = {
          toggle_inspector = "<F8>",
          toggle_viewer = "<F9>",
          close = "q",
        },
        queryer = {
          query = "<F6>",
          format = "<F7>",
        },
      },
    },
    config = function(_, opts)
      require("dbout").setup(opts)
      require("telescope").load_extension "dbout"
    end,
  },

  -- Dadbod: Lightweight command interface used directly through :DB and by DBUI.
  {
    "tpope/vim-dadbod",
    commit = "6d1d41da4873a445c5605f2005ad2c68c99d8770",
    cmd = "DB",
  },

  -- Dadbod UI: Connection drawer, schema browser, saved queries, and async results.
  {
    "kristijanhusak/vim-dadbod-ui",
    commit = "afd07819d8efcefc3317205b855ad4e3513b0011",
    dependencies = {
      "tpope/vim-dadbod",
      {
        "kristijanhusak/vim-dadbod-completion",
        commit = "a8dac0b3cf6132c80dc9b18bef36d4cf7a9e1fe6",
        dependencies = { "tpope/vim-dadbod" },
        ft = { "sql", "mysql", "plsql" },
      },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIClose",
      "DBUIAddConnection",
      "DBUIFindBuffer",
      "DBUIRenameBuffer",
      "DBUILastQueryInfo",
    },
    keys = {
      { "<leader>Bu", "<cmd>DBUIToggle<cr>", desc = "Dadbod UI: toggle database drawer" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_save_location = vim.fn.stdpath "data" .. "/db_ui"
      vim.g.db_ui_disable_mappings_sql = 1
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("DadbodSqlMappings", { clear = true })

      local function map_dbui_buffer(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].dbui_db_key_name == nil then
          return
        end
        if not vim.tbl_contains({ "sql", "mysql", "plsql" }, vim.bo[bufnr].filetype) then
          return
        end

        vim.keymap.set("n", "<leader>Bp", "<Plug>(DBUI_EditBindParameters)", {
          buffer = bufnr,
          desc = "Dadbod UI: edit bind parameters",
          remap = true,
          silent = true,
        })

        local has_save_mapping = vim.api.nvim_buf_call(bufnr, function()
          return not vim.tbl_isempty(vim.fn.maparg("<Plug>(DBUI_SaveQuery)", "n", false, true))
        end)
        if has_save_mapping then
          vim.keymap.set("n", "<leader>Bs", "<Plug>(DBUI_SaveQuery)", {
            buffer = bufnr,
            desc = "Dadbod UI: save query",
            remap = true,
            silent = true,
          })
        end
      end

      vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
        group = group,
        pattern = "*",
        callback = function(args)
          vim.schedule(function()
            map_dbui_buffer(args.buf)
          end)
        end,
      })
    end,
  },

  -- Dadbod Grip: Editable grids and a query workspace backed by database CLIs.
  {
    "joryeugene/dadbod-grip.nvim",
    commit = "2100fb7b9d817651ff417b8b8b40a061f0812553",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      { "<leader>Bg", "<cmd>GripConnect<cr>", desc = "Dadbod Grip: connect" },
    },
    opts = function()
      local state_dir = vim.fn.stdpath "state" .. "/dadbod-grip"
      vim.fn.mkdir(state_dir, "p", 448)
      return {
        ai = false,
        completion = true,
        connections_path = state_dir .. "/connections.json",
        discovery = false,
        picker = "telescope",
      }
    end,
  },

  -- GUIDED CODE EXPLORATION
  {
    "error311/wayfinder.nvim",
    cmd = {
      "Wayfinder",
      "WayfinderExportQuickfix",
      "WayfinderExportTrailQuickfix",
      "WayfinderTrailNext",
      "WayfinderTrailPrev",
      "WayfinderTrailOpen",
      "WayfinderTrailShow",
      "WayfinderTrailSave",
      "WayfinderTrailSaveAs",
      "WayfinderTrailLoad",
      "WayfinderTrailResume",
      "WayfinderTrailDelete",
      "WayfinderTrailRename",
    },
    keys = {
      { "<leader>Wf", "<cmd>Wayfinder<cr>", desc = "Wayfinder: explore" },
      { "<leader>Wn", "<cmd>WayfinderTrailNext<cr>", desc = "Wayfinder: next Trail item" },
      { "<leader>Wp", "<cmd>WayfinderTrailPrev<cr>", desc = "Wayfinder: previous Trail item" },
      { "<leader>Wo", "<cmd>WayfinderTrailOpen<cr>", desc = "Wayfinder: open Trail item" },
      { "<leader>Ws", "<cmd>WayfinderTrailShow<cr>", desc = "Wayfinder: show Trail" },
    },
    opts = {},
  },

  -- MARKS
  -- Adds signs, navigation, previews, lists, and session-local bookmark groups
  -- on top of Neovim's native lowercase/uppercase marks.
  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    cmd = {
      "MarksToggleSigns",
      "MarksListBuf",
      "MarksListGlobal",
      "MarksListAll",
      "MarksQFListBuf",
      "MarksQFListGlobal",
      "MarksQFListAll",
      "BookmarksList",
      "BookmarksListAll",
      "BookmarksQFList",
      "BookmarksQFListAll",
    },
    opts = {
      default_mappings = true,
      builtin_marks = { ".", "<", ">", "^" },
      signs = true,
      cyclic = true,
      force_write_shada = false,
      refresh_interval = 250,
    },
  },

  -- SYNTAX HIGHLIGHTING

  -- Treesitter: Advanced syntax highlighting using real parsers (not regex)
  -- Provides: accurate highlighting, code folding, text objects, and more
  -- Much better than Vim's traditional regex-based syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- The Neovim 0.12 rewrite does not support lazy-loading.
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("configs.treesitter").setup()
    end,
  },

  -- Auto-close and rename HTML/JSX/TSX tags
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
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
    keys = {
      {
        "<leader>mr",
        "<cmd>RenderMarkdown buf_toggle<cr>",
        ft = "markdown",
        desc = "Markdown: toggle rendering",
      },
    },
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
        -- Cmd+\ → open in vertical split (encoded by WezTerm)
        vim.keymap.set(
          "n",
          "<M-C-\\>",
          api.node.open.vertical,
          vim.tbl_extend("force", opts, { desc = "Open: Vertical Split" })
        )
        -- Cmd+- → open in horizontal split (encoded by WezTerm)
        vim.keymap.set(
          "n",
          "<M-C-_>",
          api.node.open.horizontal,
          vim.tbl_extend("force", opts, { desc = "Open: Horizontal Split" })
        )
      end
      return {
        on_attach = on_attach,
        filters = {
          dotfiles = false,
          custom = { [[^\.DS_Store$]], [[^\.git$]] },
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
          ignore_dirs = function(path)
            local name = vim.fs.basename(path)
            return name == ".next" or name == "node_modules" or name == ".git"
          end,
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
      "nvim-lua/plenary.nvim", -- Required
      "sindrets/diffview.nvim", -- For diff integration
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
        kind = "tab", -- Open commit editor in new tab
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
      enhanced_diff_hl = true, -- Better diff highlighting

      -- FILE PANEL (left sidebar)
      file_panel = {
        listing_style = "tree", -- "list" or "tree"
        tree_options = {
          flatten_dirs = true, -- Flatten single-child directories
          folder_statuses = "only_folded", -- Show status on folders
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
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
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
      { "<leader>gf", "<cmd>CodeDiff file HEAD<cr>", desc = "Diff file vs HEAD" },
      -- View file history (commits that touched this file)
      { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "File history" },
    },
    opts = {},
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
