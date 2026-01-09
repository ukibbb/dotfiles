-- NvChad Key Mappings Configuration
-- This file defines all keyboard shortcuts for efficient navigation and editing

-- Create an alias for vim.keymap.set to reduce typing
-- map(mode, key, action, options) - the standard way to create keymaps in Lua
local map = vim.keymap.set

-- INSERT MODE NAVIGATION
-- These mappings let you navigate without leaving insert mode (Emacs-style)
-- Using Ctrl as a modifier keeps your fingers on the home row

-- jk: Quick escape from insert mode to normal mode
-- Classic Vim trick - your fingers never leave home row!
-- Typing "jk" quickly acts as Escape. If you need literal "jk", type slowly.
map("i", "jk", "<ESC>", { desc = "exit insert mode" })

-- Ctrl+b: Jump to beginning of line (like ^ in normal mode)
-- <ESC>^i = exit insert mode, go to first non-blank char, re-enter insert mode
map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })

-- Ctrl+e: Jump to end of line
-- <End> is the End key which moves cursor to line end
map("i", "<C-e>", "<End>", { desc = "move end of line" })

-- Ctrl+h/j/k/l: Arrow key equivalents in insert mode
-- These mirror the normal mode movement keys (h=left, j=down, k=up, l=right)
-- Avoids reaching for arrow keys while typing
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

-- WINDOW NAVIGATION (NORMAL MODE)
-- Quick switching between split windows using Ctrl+h/j/k/l
-- Much faster than Ctrl+w followed by direction key

-- Ctrl+h: Move to the window on the left
-- <C-w>h is the native Vim command for "move to left window"
map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })

-- Ctrl+l: Move to the window on the right
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })

-- Ctrl+j: Move to the window below
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })

-- Ctrl+k: Move to the window above
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

-- GENERAL UTILITIES
-- Common operations made accessible with simple key combinations

-- Escape: Clear search highlighting
-- After searching with /, the matches stay highlighted. This clears them.
-- :noh = :nohlsearch command
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

-- Semicolon: Enter command mode faster (instead of Shift+:)
-- Saves a keypress! ; is easier to hit than Shift+;
-- You lose the original ; (repeat last f/t motion), but ',' still works
map("n", ";", ":", { desc = "enter command mode" })

-- Ctrl+s: Save the current file (works in both normal and insert mode)
-- Muscle memory from other editors (VS Code, etc.)
-- <cmd>...<CR> is faster than : because it doesn't change modes
map({ "n", "i" }, "<C-s>", "<cmd>w<CR>", { desc = "general save file" })

-- Ctrl+c: Copy entire file to clipboard
-- %y+ = select all lines (%) and yank to system clipboard (+)
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

-- Ctrl+a: Select all text in the file
-- gg = go to first line, V = enter visual line mode, G = go to last line
map("n", "<C-a>", "ggVG", { desc = "general select all" })

-- LINE MANIPULATION
-- Moving and editing lines efficiently

-- J (visual mode): Move selected lines DOWN
-- :m '>+1 = move to line after selection end
-- <CR> = press Enter
-- gv = reselect the same text (so you can keep moving)
-- = = auto-indent the moved lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "move selection down" })

-- K (visual mode): Move selected lines UP
-- :m '<-2 = move to line before selection start (-2 because of how ranges work)
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "move selection up" })

-- J (normal mode): Join lines but keep cursor position
-- Default J joins lines but moves cursor. This version keeps cursor in place.
-- mz = set mark 'z' at current position
-- J = join lines
-- `z = jump back to mark 'z'
map("n", "J", "mzJ`z", { desc = "join lines (keep cursor)" })

-- SCROLLING (CENTERED)
-- Keep cursor in the center of screen while scrolling for better visibility

-- Ctrl+d: Page down + center cursor
-- <C-d> = scroll down half page
-- zz = center cursor on screen
map("n", "<C-d>", "<C-d>zz", { desc = "page down (centered)" })

-- Ctrl+u: Page up + center cursor
map("n", "<C-u>", "<C-u>zz", { desc = "page up (centered)" })

-- n/N: Keep search results centered on screen
-- n = go to next search result
-- zz = center on screen
-- zv = open folds if result is in a fold
map("n", "n", "nzzzv", { desc = "next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "prev search result (centered)" })

-- BETTER VISUAL MODE PASTE
-- Paste without losing your yanked text

-- p (visual mode): Paste over selection without yanking replaced text
-- By default, if you select "foo" and paste "bar", "foo" goes to register
-- This keeps your original yanked text in the register
-- "_d = delete to black hole register (discard)
-- P = paste before cursor
map("x", "p", '"_dP', { desc = "paste without yanking replaced text" })

-- LEADER KEY MAPPINGS
-- Leader key is typically Space or \. These are "command" style shortcuts.

-- Leader+n: Toggle line numbers on/off
-- :set nu! = toggle the 'number' option (! means toggle)
map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })

-- Leader+rn: Toggle relative line numbers
-- Relative numbers show distance from cursor line (useful for j/k motions)
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })

-- Leader+w: Toggle word wrap on/off
-- Wrap makes long lines wrap to the next line instead of extending off screen
map("n", "<leader>w", "<cmd>set wrap!<CR>", { desc = "toggle word wrap" })

-- Leader+y: Copy entire file to system clipboard
-- gg = go to first line
-- "+ = use system clipboard register
-- yG = yank to last line
map("n", "<leader>y", 'gg"+yG', { desc = "copy entire file to clipboard" })

-- Leader+ch: Open NvChad's built-in cheatsheet
-- Shows all keybindings in a searchable popup
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

-- FORMATTING
-- Code formatting using conform.nvim plugin

-- Leader+fm: Format the current file
-- Works in both normal mode (n) and visual mode (x) for selection formatting
-- require("conform").format() = calls the conform plugin's format function
-- lsp_fallback = true means use LSP formatter if no conform formatter is configured
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })

-- LSP DIAGNOSTICS
-- Language Server Protocol - provides code intelligence (errors, warnings)

-- Leader+ds: Show all diagnostics in the location list
-- Location list is a window-local list of positions (like quickfix but per-window)
-- Useful for seeing all errors/warnings in the current file
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-- [d: Jump to previous diagnostic (error, warning, hint)
-- vim.diagnostic.goto_prev() is the Lua API for navigating diagnostics
map("n", "[d", vim.diagnostic.goto_prev, { desc = "LSP previous diagnostic" })

-- ]d: Jump to next diagnostic
map("n", "]d", vim.diagnostic.goto_next, { desc = "LSP next diagnostic" })

-- Leader+d: Show diagnostic in floating window
-- vim.diagnostic.open_float() shows details for diagnostic under cursor
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "LSP show diagnostic" })

-- Leader+q: Open diagnostics list in location list
-- vim.diagnostic.setloclist() populates the location list with diagnostics
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "LSP diagnostics list" })

-- QUICKFIX NAVIGATION
-- Quickfix list = list of locations (errors, search results, etc.)
-- Many tools populate the quickfix list (grep, make, LSP diagnostics)

-- [q: Navigate to previous quickfix item
-- :cprev = go to previous quickfix item
-- zz = center cursor on screen
map("n", "[q", "<cmd>cprev<CR>zz", { desc = "quickfix previous item" })

-- ]q: Navigate to next quickfix item
-- :cnext = go to next quickfix item
map("n", "]q", "<cmd>cnext<CR>zz", { desc = "quickfix next item" })

-- BUFFER NAVIGATION (TABUFLINE)
-- Tabufline is NvChad's buffer line at the top of the screen
-- Only enabled if tabufline is configured in nvconfig

-- Check if tabufline is enabled before creating these mappings
if require("nvconfig").ui.tabufline.enabled then
  -- Leader+b: Create a new empty buffer
  -- :enew = edit new (creates empty unnamed buffer)
  map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

  -- Tab: Go to next buffer
  -- Calls NvChad's tabufline module to cycle through open buffers
  map("n", "<tab>", function()
    require("nvchad.tabufline").next()
  end, { desc = "buffer goto next" })

  -- Shift+Tab: Go to previous buffer
  map("n", "<S-tab>", function()
    require("nvchad.tabufline").prev()
  end, { desc = "buffer goto prev" })

  -- Leader+x: Close the current buffer
  -- Uses NvChad's smart close that handles edge cases (last buffer, etc.)
  map("n", "<leader>x", function()
    require("nvchad.tabufline").close_buffer()
  end, { desc = "buffer close" })
end

-- COMMENTING
-- Toggle comments on lines or selections using Comment.nvim plugin

-- Leader+/: Toggle comment in normal mode
-- gcc is the default mapping from Comment.nvim to toggle line comment
-- remap = true is needed because we're mapping to another mapping (gcc)
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })

-- Leader+/: Toggle comment in visual mode
-- gc is the Comment.nvim mapping for toggling comment on selection
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- FILE EXPLORER (NVIM-TREE)
-- nvim-tree.lua is a file explorer sidebar plugin

-- Ctrl+n: Toggle the file tree window open/closed
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })

-- Leader+e: Focus the file tree (open it if closed, focus if open)
-- Unlike toggle, this always ends with the tree focused
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- TELESCOPE (FUZZY FINDER)
-- Telescope is a powerful fuzzy finder for files, text, git, and more

-- Leader+fw: Live grep - search for text across all files in the project
-- Uses ripgrep under the hood for fast searching
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })

-- Leader+fb: List and search through open buffers
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })

-- Leader+fh: Search through Neovim help documentation
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })

-- Leader+ma: List and jump to marks (positions you've saved with m{a-z})
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })

-- Leader+fo: List recently opened files (oldfiles)
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })

-- Leader+fz: Fuzzy search within the current buffer only
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })

-- Leader+cm: Browse git commits with preview
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })

-- Leader+gt: Show git status (modified/staged files)
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })

-- Leader+pt: Pick from hidden terminal sessions
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })

-- Leader+th: Open NvChad's theme picker to change colorschemes
map("n", "<leader>th", function()
  require("nvchad.themes").open()
end, { desc = "telescope nvchad themes" })

-- Leader+ff: Find files in the project (respects .gitignore)
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })

-- Leader+fa: Find ALL files including hidden and ignored ones
-- follow=true follows symlinks
-- no_ignore=true ignores .gitignore rules
-- hidden=true shows hidden files (dotfiles)
map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)

-- TERMINAL
-- NvChad's terminal module provides integrated terminal emulator

-- Ctrl+x: Escape from terminal mode back to normal mode
-- <C-\><C-N> is the native Neovim key sequence to exit terminal mode
-- Without this, you'd be stuck in terminal mode
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- Ctrl+h/j/k/l: Navigate from terminal to other splits
-- wincmd h = same as <C-w>h but works in terminal mode
-- Allows you to move between terminal and other windows without exiting terminal mode
map("t", "<C-h>", "<cmd>wincmd h<CR>", { desc = "terminal move to left split" })
map("t", "<C-j>", "<cmd>wincmd j<CR>", { desc = "terminal move to split below" })
map("t", "<C-k>", "<cmd>wincmd k<CR>", { desc = "terminal move to split above" })
map("t", "<C-l>", "<cmd>wincmd l<CR>", { desc = "terminal move to right split" })


-- NEW TERMINAL WINDOWS
-- Create new terminal instances in different split positions

-- Leader+h: Open a new horizontal split terminal (below current window)
-- pos = "sp" means horizontal split (sp = split)
map("n", "<leader>h", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "terminal new horizontal term" })

-- Leader+v: Open a new vertical split terminal (to the right)
-- pos = "vsp" means vertical split
map("n", "<leader>v", function()
  require("nvchad.term").new { pos = "vsp" }
end, { desc = "terminal new vertical term" })

-- TOGGLEABLE TERMINALS
-- These terminals can be shown/hidden and maintain their state
-- The "id" parameter creates named terminals that persist when hidden

-- Alt+v: Toggle a persistent vertical split terminal
-- Works in both normal (n) and terminal (t) modes
-- id = "vtoggleTerm" gives this terminal a unique identifier
map({ "n", "t" }, "<A-v>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "terminal toggleable vertical term" })

-- Alt+h: Toggle a persistent horizontal split terminal
map({ "n", "t" }, "<A-h>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "terminal toggleable horizontal term" })

-- Alt+i: Toggle a floating terminal window
-- pos = "float" creates a centered floating window
map({ "n", "t" }, "<A-i>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

-- WHICH-KEY INTEGRATION
-- which-key.nvim shows available keybindings in a popup

-- Leader+wK: Show ALL available keymaps
-- Opens which-key without any prefix, showing everything
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })
-- Leader+wk: Query a specific keymap prefix
-- Prompts for input, then shows keymaps starting with that prefix
-- Useful for exploring: type "g" to see all g-prefixed commands
map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
end, { desc = "whichkey query lookup" })