# Keybindings & Configuration Reference

Complete reference for all keybindings, mappings, and shortcuts in Neovim and tmux configurations.

**Leader Key:** `Space`

---

## Table of Contents

- [Neovim Keybindings](#neovim-keybindings)
  - [Insert Mode](#insert-mode)
  - [Normal Mode](#normal-mode)
  - [Visual Mode](#visual-mode)
  - [Terminal Mode](#terminal-mode)
  - [LSP (Language Server Protocol)](#lsp-language-server-protocol)
  - [Completion (nvim-cmp)](#completion-nvim-cmp)
  - [Telescope (Fuzzy Finder)](#telescope-fuzzy-finder)
  - [File Management](#file-management)
  - [Git Integration](#git-integration)
- [Tmux Keybindings](#tmux-keybindings)
- [Automatic Behaviors](#automatic-behaviors)

---

## Neovim Keybindings

### Insert Mode

| Key | Action | Description |
|-----|--------|-------------|
| `jk` | Exit insert mode | Quick escape to normal mode (alternative to ESC) |
| `Ctrl+b` | Move to beginning of line | Jump to first non-blank character |
| `Ctrl+e` | Move to end of line | Jump to line end |
| `Ctrl+h` | Move left | Arrow key equivalent |
| `Ctrl+l` | Move right | Arrow key equivalent |
| `Ctrl+j` | Move down | Arrow key equivalent |
| `Ctrl+k` | Move up | Arrow key equivalent |
| `Ctrl+s` | Save file | Save current file (works in both normal and insert) |

### Normal Mode

#### Window Navigation
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+h` | Move to left window | Navigate to window on the left |
| `Ctrl+l` | Move to right window | Navigate to window on the right |
| `Ctrl+j` | Move to window below | Navigate to window below |
| `Ctrl+k` | Move to window above | Navigate to window above |

#### General Utilities
| Key | Action | Description |
|-----|--------|-------------|
| `Esc` | Clear search highlights | Remove search highlighting |
| `;` | Enter command mode | Faster than `Shift+:` |
| `Ctrl+s` | Save file | Save current file |
| `Ctrl+c` | Copy entire file | Copy whole file to system clipboard |
| `Ctrl+a` | Select all | Select all text in file |

#### Line Manipulation
| Key | Action | Description |
|-----|--------|-------------|
| `J` | Join lines (keep cursor) | Join lines without moving cursor |

#### Scrolling (Centered)
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+d` | Page down (centered) | Scroll half page down, center cursor |
| `Ctrl+u` | Page up (centered) | Scroll half page up, center cursor |
| `n` | Next search result (centered) | Go to next search match, centered |
| `N` | Previous search result (centered) | Go to previous search match, centered |

#### Leader Key Mappings
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>n` | Toggle line numbers | Toggle line numbers on/off |
| `<leader>rn` | Toggle relative numbers | Toggle relative line numbers |
| `<leader>w` | Toggle word wrap | Toggle line wrapping |
| `<leader>y` | Copy file to clipboard | Copy entire file to system clipboard |
| `<leader>ch` | Show cheatsheet | Open NvChad's keybinding cheatsheet |
| `<leader>fm` | Format file | Format current file or selection |

#### Diagnostics & Lists
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ds` | Show diagnostics in location list | List all diagnostics for buffer |
| `[d` | Previous diagnostic | Jump to previous error/warning |
| `]d` | Next diagnostic | Jump to next error/warning |
| `<leader>d` | Show diagnostic | Show diagnostic in floating window |
| `<leader>q` | Diagnostics list | Open diagnostics in location list |
| `[q` | Previous quickfix item | Navigate to previous quickfix entry |
| `]q` | Next quickfix item | Navigate to next quickfix entry |

#### Buffer Management
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>b` | New buffer | Create new empty buffer |
| `Tab` | Next buffer | Go to next buffer |
| `Shift+Tab` | Previous buffer | Go to previous buffer |
| `<leader>x` | Close buffer | Close current buffer |

#### Commenting
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>/` | Toggle comment | Toggle comment on current line |

#### Terminal
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>h` | New horizontal terminal | Open terminal in horizontal split |
| `<leader>v` | New vertical terminal | Open terminal in vertical split |
| `Alt+h` | Toggle horizontal terminal | Toggle persistent horizontal terminal |
| `Alt+v` | Toggle vertical terminal | Toggle persistent vertical terminal |
| `Alt+i` | Toggle floating terminal | Toggle floating terminal window |

#### WhichKey
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>wK` | Show all keymaps | Display all available keybindings |
| `<leader>wk` | Query keymap | Search for specific keymap prefix |

### Visual Mode

| Key | Action | Description |
|-----|--------|-------------|
| `J` | Move selection down | Move selected lines down |
| `K` | Move selection up | Move selected lines up |
| `p` | Paste without yank | Paste over selection without losing yank |
| `<leader>/` | Toggle comment | Toggle comment on selection |

### Terminal Mode

| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+x` | Exit terminal mode | Return to normal mode |
| `Ctrl+h` | Move to left split | Navigate to window on the left |
| `Ctrl+j` | Move to split below | Navigate to window below |
| `Ctrl+k` | Move to split above | Navigate to window above |
| `Ctrl+l` | Move to right split | Navigate to window on the right |

### LSP (Language Server Protocol)

#### Navigation
| Key | Action | Description |
|-----|--------|-------------|
| `gD` | Go to declaration | Jump to where symbol is declared |
| `gd` | Go to definition | Jump to where symbol is defined |
| `<leader>D` | Go to type definition | Jump to type definition |

#### Workspace Management
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>wa` | Add workspace folder | Add folder to LSP workspace |
| `<leader>wr` | Remove workspace folder | Remove folder from LSP workspace |
| `<leader>wl` | List workspace folders | Show all workspace folders |

#### Code Actions
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ra` | Rename symbol | Rename symbol across project |

### Completion (nvim-cmp)

#### In Completion Menu
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+p` | Previous item | Select previous completion |
| `Ctrl+n` | Next item | Select next completion |
| `Ctrl+d` | Scroll docs down | Scroll documentation down |
| `Ctrl+f` | Scroll docs up | Scroll documentation up |
| `Ctrl+Space` | Trigger completion | Manually show completion menu |
| `Ctrl+e` | Close menu | Close completion menu |
| `Enter` | Confirm | Accept selected completion |
| `Tab` | Smart tab | Next item / expand snippet / regular tab |
| `Shift+Tab` | Smart shift-tab | Previous item / previous snippet position |

### Telescope (Fuzzy Finder)

#### File & Text Search
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ff` | Find files | Search files (respects .gitignore) |
| `<leader>fa` | Find all files | Search all files (including hidden) |
| `<leader>fw` | Live grep | Search text across all files |
| `<leader>fz` | Current buffer search | Fuzzy search in current buffer |
| `<leader>fb` | Find buffers | Search through open buffers |
| `<leader>fo` | Old files | Search recently opened files |
| `<leader>fh` | Help tags | Search Neovim help documentation |
| `<leader>ma` | Marks | List and jump to marks |
| `<leader>pt` | Pick terminal | Pick from hidden terminal sessions |

#### Git
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>cm` | Git commits | Browse git commits |
| `<leader>gt` | Git status | Show git status (modified files) |

#### Theme
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>th` | Theme picker | Open NvChad theme picker |

#### Within Telescope Window
| Key | Action | Description |
|-----|--------|-------------|
| `q` (normal mode) | Close telescope | Quit telescope |
| `Ctrl+n` / `Down` | Next result | Navigate to next result |
| `Ctrl+p` / `Up` | Previous result | Navigate to previous result |
| `Enter` | Open file | Open selected file |
| `Ctrl+x` | Horizontal split | Open in horizontal split |
| `Ctrl+v` | Vertical split | Open in vertical split |
| `Ctrl+t` | New tab | Open in new tab |
| `Ctrl+u` / `Ctrl+d` | Scroll preview | Scroll preview window |

### File Management

#### Nvim-Tree
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+n` | Toggle file tree | Open/close file explorer |
| `<leader>e` | Focus file tree | Focus file explorer (opens if closed) |

#### Yazi
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>-` | Open yazi | Open yazi file manager at current file |
| `<leader>cw` | Open yazi in cwd | Open yazi in working directory |
| `Ctrl+Up` | Toggle yazi | Resume last yazi session |
| `F1` (in yazi) | Show help | Display yazi help |

### Git Integration

Git signs and hunks are managed by gitsigns.nvim (no custom keybindings in config, uses defaults).

---

## Tmux Keybindings

**Prefix Key:** `Ctrl+a` (changed from default `Ctrl+b`)

### Basic Operations
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+a Ctrl+a` | Send prefix | Send Ctrl+a to application inside tmux |
| `Ctrl+a r` | Reload config | Reload tmux.conf without restarting |

### Pane Management

#### Creating Panes
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+a \|` | Vertical split | Create new pane side-by-side (pipe symbol) |
| `Ctrl+a -` | Horizontal split | Create new pane stacked (minus symbol) |

#### Resizing Panes
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+a h` | Resize left | Resize pane left by 5 cells (repeatable) |
| `Ctrl+a j` | Resize down | Resize pane down by 5 cells (repeatable) |
| `Ctrl+a k` | Resize up | Resize pane up by 5 cells (repeatable) |
| `Ctrl+a l` | Resize right | Resize pane right by 5 cells (repeatable) |
| `Ctrl+a m` | Toggle zoom | Maximize/restore current pane (repeatable) |

#### Navigation
**Note:** Navigation between tmux panes and vim splits is seamless via `vim-tmux-navigator` plugin.
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+h` | Navigate left | Move to pane/vim split on left |
| `Ctrl+j` | Navigate down | Move to pane/vim split below |
| `Ctrl+k` | Navigate up | Move to pane/vim split above |
| `Ctrl+l` | Navigate right | Move to pane/vim split on right |

### Copy Mode (Vi Mode)

| Key | Action | Description |
|-----|--------|-------------|
| `[` (after prefix) | Enter copy mode | Enter scrollback/copy mode |
| `v` (in copy mode) | Begin selection | Start visual selection |
| `y` (in copy mode) | Yank/copy | Copy selected text |
| `h/j/k/l` (in copy mode) | Navigate | Vi-style navigation |

### Session Management
| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+a Ctrl+j` | Session switcher | Fuzzy find and switch sessions |

### Plugins
- **TPM (Tmux Plugin Manager):** Manages all tmux plugins
- **tmux-fzf:** Fuzzy finding for sessions, windows, and commands
- **vim-tmux-navigator:** Seamless navigation between vim and tmux

---

## Automatic Behaviors

These are automatic actions that occur on specific events (not triggered by keybindings):

### Visual Feedback
- **Yank Highlight:** Text flashes briefly (200ms) when yanked/copied
- **Spell Check:** Automatically enabled for markdown, text, and git commit files

### File Management
- **Auto-create Directories:** When saving a file, parent directories are created automatically
- **Restore Cursor Position:** When reopening a file, cursor returns to last position
- **Check External Changes:** Prompts to reload if file changed outside Neovim

### Code Quality
- **Remove Trailing Whitespace:** Automatically trimmed on save
- **Auto-resize Splits:** Splits become equal size when window is resized

### Terminal Behavior
- **Auto Insert Mode:** Terminal buffers automatically enter insert mode
- **No Line Numbers:** Line numbers hidden in terminal buffers

### Special Buffers
- **Close with 'q':** Help, quickfix, lspinfo, man pages, and other special buffers can be closed with just `q`
- **Not in Buffer List:** Special buffers don't appear in buffer list

### Filetype-Specific Settings
- **Markdown/Text:** Word wrap and spell check enabled
- **Go:** Uses tabs (4-width) instead of spaces
- **Python:** 4-space indentation (PEP 8 style)

---

## Plugin Commands

### LSP & Mason
- `:Mason` - Open Mason package manager UI
- `:MasonInstall <package>` - Install LSP server, formatter, or linter
- `:MasonUpdate` - Update all installed packages

### Telescope
- `:Telescope` - Open Telescope picker menu

### Formatting
- `:ConformInfo` - Show formatting configuration for current buffer

### Treesitter
- `:TSInstall <language>` - Install treesitter parser
- `:TSUpdate` - Update all parsers
- `:TSModuleInfo` - Show treesitter module information

### Git
- `:Gitsigns` - Git signs commands (hunks, blame, etc.)

### Theme
- `:Telescope themes` - NvChad theme picker

### File Explorer
- `:NvimTreeToggle` - Toggle nvim-tree
- `:NvimTreeFocus` - Focus nvim-tree
- `:Yazi` - Open yazi file manager

---

## Configuration Files

- **Neovim Entry:** `nvim/init.lua`
- **Keybindings:** `nvim/lua/mappings.lua`
- **LSP Config:** `nvim/lua/configs/lspconfig.lua`
- **Completion:** `nvim/lua/configs/cmp.lua`
- **Telescope:** `nvim/lua/configs/telescope.lua`
- **Plugins:** `nvim/lua/plugins/init.lua`
- **Autocommands:** `nvim/lua/autocmds.lua`
- **Options:** `nvim/lua/options.lua`
- **Tmux:** `tmux.conf`

---

## Notes

### Neovim
- **Leader Key** is `Space` (set in `init.lua`)
- Most plugins are **lazy-loaded** for faster startup
- **Base46** provides theming (NvChad's theme engine)
- **LSP** provides code intelligence (completions, diagnostics, go-to-definition)
- **Treesitter** provides accurate syntax highlighting

### Tmux
- **Prefix Key** is `Ctrl+a` (changed from default `Ctrl+b`)
- **Mouse support** is enabled
- **Vi mode** is enabled in copy mode
- **256 color support** for proper color rendering
- **Seamless vim/tmux navigation** via vim-tmux-navigator plugin

---

**Generated:** Documentation for dotfiles configuration  
**Last Updated:** January 11, 2026
