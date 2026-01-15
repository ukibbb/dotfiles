# Keybindings Reference

Quick reference for Neovim keybindings.

For tmux keybindings and concepts, see [tmux.md](tmux.md).

---

# Neovim Keybindings

## Quick Start

**Key Prefixes:**
- `<leader>` = Space
- `<C-...>` = Ctrl + key
- `<S-...>` = Shift + key
- `<D-...>` = Cmd + key (macOS)
- `<M-...>` = Alt/Option + key

---

## Core Keybindings

### General Utilities
| Key | Mode | Action |
|-----|------|--------|
| `jk` | Insert | Exit insert mode |
| `;` | Normal | Enter command mode (instead of Shift+:) |
| `<Esc>` | Normal | Clear search highlights |
| `<C-s>` | Normal/Insert | Save file |
| `<C-c>` | Normal | Copy entire file to clipboard |
| `<C-a>` | Normal | Select all text |

### Insert Mode Navigation
| Key | Action |
|-----|--------|
| `jk` | Exit insert mode |
| `<C-b>` | Move to beginning of line |
| `<C-e>` | Move to end of line |
| `<C-h>` | Move left |
| `<C-l>` | Move right |
| `<C-j>` | Move down |
| `<C-k>` | Move up |

### Window Navigation
| Key | Action |
|-----|--------|
| `<C-h>` | Switch to left window |
| `<C-l>` | Switch to right window |
| `<C-j>` | Switch to down window |
| `<C-k>` | Switch to up window |

### Window Splits
| Key | Action |
|-----|--------|
| `<Cmd-\>` | Create vertical split (right) |
| `<Cmd-->` | Create horizontal split (below) |

### Buffer Management
| Key | Action |
|-----|--------|
| `<leader>b` | Create new empty buffer |
| `<Cmd-h>` | Go to next buffer |
| `<Cmd-l>` | Go to previous buffer |
| `<Cmd-q>` | Close current buffer |

### Line Manipulation
| Key | Mode | Action |
|-----|------|--------|
| `J` | Visual | Move selection down |
| `K` | Visual | Move selection up |
| `J` | Normal | Join lines (keep cursor) |
| `p` | Visual | Paste without yanking replaced text |

### Scrolling (Centered)
| Key | Action |
|-----|--------|
| `<C-d>` | Page down + center cursor |
| `<C-u>` | Page up + center cursor |
| `n` | Next search result (centered) |
| `N` | Previous search result (centered) |

---

## Leader Key Mappings (`<leader>` = Space)

### Toggle/UI Settings
| Key | Action |
|-----|--------|
| `<leader>n` | Toggle line numbers |
| `<leader>rn` | Toggle relative line numbers |
| `<leader>w` | Toggle word wrap |
| `<leader>y` | Copy entire file to clipboard |
| `<leader>ch` | Open NvChad cheatsheet |
| `<leader>th` | Open theme picker |

### Formatting & Comments
| Key | Mode | Action |
|-----|------|--------|
| `<leader>fm` | Normal/Visual | Format file |
| `<leader>/` | Normal | Toggle comment on line |
| `<leader>/` | Visual | Toggle comment on selection |

### File Manager (Yazi)
| Key | Action |
|-----|--------|
| `<leader>i` | Open yazi at current file |
| `<leader>iw` | Open yazi in working directory |
| `<leader>is` | Resume last yazi session |

### Telescope (Fuzzy Finder)
| Key | Action |
|-----|--------|
| `<leader>ff` | Find files in project (respects .gitignore) |
| `<leader>fa` | Find all files (including hidden/ignored) |
| `<leader>fw` | Live grep (search text across project) |
| `<leader>fb` | Find in open buffers |
| `<leader>fh` | Search help documentation |
| `<leader>fo` | Find recently opened files |
| `<leader>fz` | Fuzzy find in current buffer |
| `<leader>ma` | List and jump to marks |

### Git Integration
| Key | Action |
|-----|--------|
| `<leader>cm` | Browse git commits |
| `<leader>gt` | Show git status |

### LSP - Diagnostics
| Key | Action |
|-----|--------|
| `[d` | Jump to previous diagnostic |
| `]d` | Jump to next diagnostic |
| `<leader>d` | Show diagnostic in floating window |
| `<leader>ds` | Show all diagnostics (location list) |
| `<leader>q` | Open diagnostics list |

### LSP - Navigation & Code Intelligence
*These keybindings are available when an LSP server is attached to the buffer*

| Key | Action |
|-----|--------|
| `gD` | Go to declaration |
| `gd` | Go to definition |
| `<leader>D` | Go to type definition |
| `<leader>ra` | Rename symbol (NvChad renamer) |

### LSP - Workspace Management
| Key | Action |
|-----|--------|
| `<leader>wa` | Add workspace folder |
| `<leader>wr` | Remove workspace folder |
| `<leader>wl` | List workspace folders |

### Quickfix Navigation
| Key | Action |
|-----|--------|
| `[q` | Go to previous quickfix item |
| `]q` | Go to next quickfix item |

---

## Keybindings by Plugin

### Yazi (File Manager)
Fast terminal file manager integration. See [File Manager (Yazi)](#file-manager-yazi) section above for keybindings to open Yazi.

**Inside Yazi:**
- `F1` - Show help
- `hjkl` or arrows - Navigate
- `Enter` - Open file in Neovim
- `Space` - Select file
- `y` - Yank/copy
- `p` - Paste
- `d` - Delete
- `a` - Create file
- `A` - Create directory
- `/` - Search
- `q` - Quit

### Telescope
Used for fuzzy finding files, text, and more.
- **Group:** `<leader>f` (find)
- See "Telescope" section above for all keymaps

**Inside Telescope (Insert mode):**
| Key | Action |
|-----|--------|
| `<C-n>` or `<Down>` | Navigate to next result |
| `<C-p>` or `<Up>` | Navigate to previous result |
| `<CR>` (Enter) | Open selected file |
| `<C-x>` | Open in horizontal split |
| `<C-v>` | Open in vertical split |
| `<C-t>` | Open in new tab |
| `<C-u>` | Scroll preview up |
| `<C-d>` | Scroll preview down |
| `<Esc>` | Enter normal mode |

**Inside Telescope (Normal mode):**
| Key | Action |
|-----|--------|
| `q` | Close telescope |
| `j`/`k` | Navigate results |

### LSP (Language Server)
Code intelligence, diagnostics, and completion.
- Navigation: `gd`, `gD`, `<leader>D`
- Diagnostics: `[d`, `]d`, `<leader>d`, `<leader>ds`, `<leader>q`
- Code actions: `<leader>ra`
- Workspace: `<leader>wa`, `<leader>wr`, `<leader>wl`

### NvChad UI
Theming and UI components.
- `<leader>ch` - Cheatsheet
- `<leader>th` - Theme picker

### Conform
Code formatting with external formatters.
- `<leader>fm` - Format file

### nvim-cmp (Autocompletion)
Keybindings for the completion menu (appears when typing code).

| Key | Mode | Action |
|-----|------|--------|
| `<C-p>` | Insert | Select previous completion item |
| `<C-n>` | Insert | Select next completion item |
| `<Tab>` | Insert | Select next item / Expand or jump in snippet |
| `<S-Tab>` | Insert | Select previous item / Jump back in snippet |
| `<CR>` (Enter) | Insert | Confirm selected completion |
| `<C-Space>` | Insert | Manually trigger completion menu |
| `<C-e>` | Insert | Close completion menu |
| `<C-d>` | Insert | Scroll docs down |
| `<C-f>` | Insert | Scroll docs up |

### nvim-autopairs
Automatically inserts closing brackets, quotes, and parentheses.
- Automatically pairs: `()`, `[]`, `{}`, `""`, `''`, etc.
- `<M-e>` (Alt+e) - Fast wrap: wrap selected text with pairs

### render-markdown.nvim
Enhanced markdown rendering with treesitter-powered formatting.
- Available commands: `:RenderMarkdown enable/disable/toggle`
- See full details in dedicated section below

### Git Signs
Git integration for modified lines and hunks.
- Line indicators show git changes
- Configured in `lua/configs/gitsigns.lua`

### render-markdown.nvim (Full Details)
Enhanced markdown rendering with treesitter-powered formatting.
- Automatically renders markdown files with proper formatting
- Shows heading icons, styled code blocks, and formatted lists
- Renders in all modes (normal, insert, visual, command)

**Available Commands:**
| Command | Action |
|---------|--------|
| `:RenderMarkdown enable` | Enable markdown rendering |
| `:RenderMarkdown disable` | Disable markdown rendering |
| `:RenderMarkdown toggle` | Toggle markdown rendering |

**Features:**
- Heading icons: 󰲡 (H1), 󰲣 (H2), 󰲥 (H3), 󰲧 (H4), 󰲩 (H5), 󰲫 (H6)
- Styled code blocks with language indicators
- Bullet list icons: ●, ○, ◆, ◇ (nested levels)
- Maximum file size: 10MB (prevents lag on huge files)

**Configuration:** `nvim/lua/configs/render-markdown.lua`

**Note:** No custom keybindings are configured. To add a toggle keybinding, you could add to `nvim/lua/mappings.lua`:
```lua
map("n", "<leader>md", "<cmd>RenderMarkdown toggle<CR>", { desc = "toggle markdown rendering" })
```

---

## Most Frequent Commands

| Action | Keybinding |
|--------|-----------|
| Find file | `<leader>ff` |
| Toggle comment | `<leader>/` |
| Open file manager | `<leader>i` |
| Next buffer | `<Cmd-h>` |
| Close buffer | `<Cmd-q>` |
| Vertical split | `<Cmd-\>` |
| Horizontal split | `<Cmd-->` |
| Save file | `<C-s>` |
| Go to definition | `gd` |
| Rename symbol | `<leader>ra` |

---





