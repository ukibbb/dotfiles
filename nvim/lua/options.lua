-- vim.opt = Vim options (set command equivalent)
-- vim.o   = Same as vim.opt but returns raw value (not Option object)
-- vim.g   = Global variables (g:variable in Vimscript)

-- Create shortcuts for cleaner code
local opt = vim.opt  -- vim.opt provides a Lua-friendly way to set options
local o = vim.o      -- vim.o is a direct interface to options (slightly faster)
local g = vim.g      -- vim.g accesses global Vimscript variables

-- SECTION 1: USER INTERFACE

-- laststatus = 3 means ONE global statusline at the bottom (not per-window)
-- Values: 0 = never, 1 = only if 2+ windows, 2 = always (per window), 3 = global
-- Global statusline looks cleaner with splits
o.laststatus = 3

-- showmode = false hides "--INSERT--", "--VISUAL--" etc. at the bottom
-- We'll use a statusline plugin (lualine) that shows this info prettier
o.showmode = false

-- splitkeep = "screen" keeps text on screen stable when opening/closing splits
-- Without this, text can "jump" when you open a new split
o.splitkeep = "screen"

-- termguicolors = true enables 24-bit RGB colors in the terminal
-- Required for modern colorschemes to look correct
-- Your terminal must support true color (most modern terminals do)
opt.termguicolors = true

-- cursorline = true highlights the line where the cursor is
-- Makes it easier to find your cursor in large files
o.cursorline = true

-- cursorlineopt = "number" only highlights the LINE NUMBER, not the whole line
-- Less distracting than highlighting the entire line
-- Options: "line", "number", "both", "screenline"
o.cursorlineopt = "number"

-- guicursor sets cursor shape per mode
-- Insert mode: block cursor with slow blink (like visual mode, but blinking)
-- n-v-c = normal, visual, command: solid block
-- i = insert: block with blink (700ms wait, 400ms on, 400ms off)
-- r-cr = replace: horizontal bar
opt.guicursor = "n-v-c:block,i:block-blinkwait700-blinkon400-blinkoff400,r-cr:hor20,o:hor50"

-- signcolumn = "yes" always shows the sign column (left gutter)
-- This prevents the editor from "shifting" when signs appear (git, diagnostics)
o.signcolumn = "yes"

-- fillchars.eob = " " replaces the ~ on empty lines with spaces
-- By default Neovim shows ~ on lines after end of file (Vim tradition)
-- Setting to space makes it cleaner/less distracting
opt.fillchars = { eob = " " }

-- ============================================================================
-- SECTION 2: LINE NUMBERS
-- ============================================================================

-- number = true shows absolute line numbers in the gutter
o.number = true

-- relativenumber = true shows RELATIVE line numbers (distance from cursor)
-- Combined with number=true: current line shows absolute, others show relative
-- This makes motions like 5j (jump 5 lines down) much easier!
o.relativenumber = true

-- numberwidth = 2 sets minimum width of the number column
-- Default is 4, but 2 saves horizontal space for small files
o.numberwidth = 2

-- ruler = false hides the line:column indicator in bottom right
-- We'll show this in our statusline instead
o.ruler = false

-- ============================================================================
-- SECTION 3: INDENTATION
-- ============================================================================

-- expandtab = true converts Tab key press to spaces
-- Most modern codebases prefer spaces over tabs for consistency
o.expandtab = true

-- shiftwidth = 2 sets how many spaces to use for each indent level
-- Used by >> (indent), << (unindent), and auto-indent
o.shiftwidth = 2

-- tabstop = 2 sets how many spaces a Tab character DISPLAYS as
-- If you open a file with real tabs, they'll appear as 2 spaces wide
o.tabstop = 2

-- softtabstop = 2 sets how many spaces Tab/Backspace move in insert mode
-- Makes Tab and Backspace feel consistent with your indentation
o.softtabstop = 2

-- smartindent = true enables smart auto-indentation
-- Neovim guesses indentation based on code structure (after {, etc.)
o.smartindent = true

-- ============================================================================
-- SECTION 4: SEARCH BEHAVIOR
-- ============================================================================

-- ignorecase = true makes search case-insensitive by default
-- Searching for "hello" will match "Hello", "HELLO", "hElLo"
o.ignorecase = true

-- smartcase = true makes search case-SENSITIVE if you use uppercase
-- With ignorecase + smartcase:
--   /hello  → matches "hello", "Hello", "HELLO" (no uppercase in pattern)
--   /Hello  → matches only "Hello" (uppercase in pattern = exact match)
o.smartcase = true

-- ============================================================================
-- SECTION 5: EDITING BEHAVIOR
-- ============================================================================

-- clipboard = "unnamedplus" syncs Neovim clipboard with system clipboard
-- Now y (yank) and p (paste) work with Ctrl+C/Ctrl+V in other apps!
-- "unnamedplus" uses the + register (system clipboard)
-- Note: On some systems you need xclip or xsel installed
o.clipboard = "unnamedplus"

-- mouse = "a" enables mouse in ALL modes (normal, insert, visual, command)
-- You can click to move cursor, scroll, select text, resize splits
-- Useful for new users; some Vim purists disable this
o.mouse = "a"

-- undofile = true saves undo history to a file
-- This means you can undo changes even after closing and reopening a file!
-- Undo files are stored in ~/.local/share/nvim/undo/
o.undofile = true

-- autoread = true automatically re-reads file when changed externally
-- Combined with checktime autocommands, this enables live updates
-- when tools like Claude Code modify files
o.autoread = true

-- swapfile = false disables .swp swap files
-- Swap files are used for crash recovery, but can be annoying
-- Modern systems crash less often, and you probably use git anyway
o.swapfile = false

-- backup = false disables backup files
-- Neovim won't create filename~ backup files before saving
o.backup = false

-- wrap = false disables line wrapping
-- Long lines will extend off screen (scroll horizontally to see)
-- Many developers prefer this; set to true if you prefer wrapping
o.wrap = false

-- ============================================================================
-- SECTION 6: SPLITS
-- ============================================================================

-- splitbelow = true opens horizontal splits BELOW current window
-- Default is above, which feels unnatural to most people
o.splitbelow = true

-- splitright = true opens vertical splits to the RIGHT of current window
-- Default is left, which also feels unnatural
o.splitright = true

-- ============================================================================
-- SECTION 7: TIMING
-- ============================================================================

-- updatetime = 50 sets delay (ms) before CursorHold event fires
-- Fast enough for live reload, stable for plugins
o.updatetime = 50

-- timeoutlen = 400 sets time (ms) to wait for a mapped sequence to complete
-- If you press <leader>, Neovim waits 400ms for the next key
-- Too low = hard to type sequences. Too high = feels sluggish.
o.timeoutlen = 400

-- ============================================================================
-- SECTION 8: MISC
-- ============================================================================

-- shortmess:append "sI" adds flags to shorten certain messages:
--   s = don't show "search hit BOTTOM, continuing at TOP"
--   I = don't show intro message on startup (:intro)
-- This makes the UI feel cleaner
opt.shortmess:append("sI")

-- whichwrap:append "<>[]hl" allows these keys to move across line boundaries:
--   < > = arrow keys in normal/visual mode
--   [ ] = arrow keys in insert/replace mode
--   h l = h and l in normal mode
-- Without this, pressing l at end of line does nothing
opt.whichwrap:append("<>[]hl")

-- ============================================================================
-- SECTION 9: DISABLE UNUSED PROVIDERS
-- ============================================================================
-- Neovim can use external interpreters for plugins (Python, Ruby, etc.)
-- Most modern plugins are pure Lua, so we disable unused providers
-- This speeds up startup and removes "provider not found" warnings

g.loaded_node_provider = 0      -- Disable Node.js provider
g.loaded_python3_provider = 0   -- Disable Python 3 provider
g.loaded_perl_provider = 0      -- Disable Perl provider
g.loaded_ruby_provider = 0      -- Disable Ruby provider
