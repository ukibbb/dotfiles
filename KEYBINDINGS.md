# Keybindings Reference

Quick reference for keybindings across the terminal stack.

For tmux keybindings and concepts, see [tmux.md](tmux.md).

---

## Keybinding Flow

Keyboard input flows through four layers:

```
Keyboard → Karabiner (remaps Cmd keys) → Ghostty (terminal) → tmux (if running) → Neovim
```

| Layer | Purpose |
|-------|---------|
| Karabiner | Remaps `Cmd+...` to `Ctrl+Alt+...` in Ghostty |
| Ghostty | Terminal emulator, sends escape sequences to apps |
| tmux | Terminal multiplexer (prefix: `Ctrl+s`) |
| Neovim | Editor (leader: `Space`) |

### Karabiner Key Remapping

In Ghostty, Karabiner intercepts these macOS shortcuts and remaps them:

| You Press | Karabiner Sends | Neovim Sees | Action |
|-----------|-----------------|-------------|--------|
| `Cmd+h` | `Ctrl+Alt+h` | `<M-C-H>` | Previous buffer |
| `Cmd+l` | `Ctrl+Alt+l` | `<M-C-L>` | Next buffer |
| `Cmd+q` | `Ctrl+Alt+q` | `<M-C-Q>` | Close buffer |
| `Cmd+\` | `Ctrl+Alt+\` | `<M-C-\>` | Vertical split |
| `Cmd+-` | `Ctrl+Alt+-` | `<M-C-_>` | Horizontal split |

### Ghostty Direct Keybindings

These are sent directly by Ghostty (no Karabiner remapping):

| You Press | Neovim Sees | Action |
|-----------|-------------|--------|
| `Cmd+n` | Escape sequence | (available for mapping) |
| `Cmd+j` | Escape sequence | Telescope: next result |
| `Cmd+k` | Escape sequence | Telescope: previous result |

### Unified Navigation

`Ctrl+h/j/k/l` works seamlessly across tmux panes and Neovim splits via vim-tmux-navigator.

---

# Neovim Keybindings

## Quick Start

**Key Prefixes:**
- `<leader>` = Space
- `<C-...>` = Ctrl + key
- `<S-...>` = Shift + key
- `<M-...>` = Alt/Option + key
- `<M-C-...>` = Alt/Option + Ctrl + key

---

## Core Keybindings

### General Utilities
| Key | Mode | Action |
|-----|------|--------|
| `jk` | Insert | Exit insert mode |
| `;` | Normal | Enter command mode (instead of Shift+:) |
| `<Esc>` | Normal | Clear search highlights |
| `:w` | Normal | Save file (command mode) |
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
| You Press | Neovim Key | Action |
|-----------|------------|--------|
| `Cmd+\` | `<M-C-\>` | Create vertical split (right) |
| `Cmd+-` | `<M-C-_>` | Create horizontal split (below) |

### Buffer Management
| You Press | Neovim Key | Action |
|-----------|------------|--------|
| — | `<leader>b` | Create new empty buffer |
| `Cmd+h` | `<M-C-H>` | Go to previous buffer |
| `Cmd+l` | `<M-C-L>` | Go to next buffer |
| `Cmd+q` | `<M-C-Q>` | Close current buffer |

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
| `<leader>ch` | Open NvChad cheatsheet *(built-in NvChad mapping)* |
| `<leader>th` | Open theme picker |

### Formatting & Comments
| Key | Mode | Action |
|-----|------|--------|
| `<leader>fm` | Normal/Visual | Format file |
| `<leader>/` | Normal | Toggle comment on line |
| `<leader>/` | Visual | Toggle comment on selection |

### File Explorer (Oil.nvim)
| Key | Action |
|-----|--------|
| `-` | Open parent directory (with auto-preview) |

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
| `<leader>gd` | Toggle inline diff (Unified.nvim) |
| `<leader>gg` | Open Lazygit |

### Claude Code Integration
| Key | Mode | Action |
|-----|------|--------|
| `<leader>sc` | Visual | Add Claude-generated comments to selected code |

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

### Oil.nvim (File Explorer)
Edit your filesystem like a buffer with automatic preview.

**Opening Oil:**
- `-` - Open parent directory (auto-opens preview)

**Inside Oil:**
| Key | Action |
|-----|--------|
| `j`/`k` | Navigate files (preview auto-updates) |
| `Enter` | Open file/directory |
| `-` | Go to parent directory |
| `_` | Open current working directory |
| `Ctrl-p` | Toggle preview |
| `Ctrl-s` | Open in vertical split |
| `Ctrl-h` | Open in horizontal split |
| `Ctrl-t` | Open in new tab |
| `Ctrl-l` | Refresh |
| `g.` | Toggle hidden files |
| `gs` | Change sort order |
| `gx` | Open with external app |
| `g?` | Show help |
| `q` | Close Oil |

**File operations:** Edit buffer like normal text, then `:w` to apply:
- Rename: change the filename text
- Delete: `dd` to delete line
- Move: yank line, paste in another directory
- Create: add new line with filename (end with `/` for directory)

### Telescope
Used for fuzzy finding files, text, and more.
- **Group:** `<leader>f` (find)
- See "Telescope" section above for all keymaps

**Inside Telescope (Insert mode):**
| You Press | Neovim Key | Action |
|-----------|------------|--------|
| `Cmd+j` or `Alt+j` | `<M-j>` | Navigate to next result |
| `Cmd+k` or `Alt+k` | `<M-k>` | Navigate to previous result |
| `Enter` | `<CR>` | Open selected file |
| `Ctrl+x` | `<C-x>` | Open in horizontal split |
| `Ctrl+v` | `<C-v>` | Open in vertical split |
| `Ctrl+t` | `<C-t>` | Open in new tab |
| `Ctrl+u` | `<C-u>` | Scroll preview up |
| `Ctrl+d` | `<C-d>` | Scroll preview down |
| `Esc` | `<Esc>` | Enter normal mode |

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

**Note:** `<C-Space>` in insert mode triggers completion. There's no conflict with tmux since the tmux prefix (`Ctrl+s`) is different.

### nvim-autopairs
Automatically inserts closing brackets, quotes, and parentheses.
- Automatically pairs: `()`, `[]`, `{}`, `""`, `''`, etc.
- `<M-e>` (Alt+e) - Fast wrap: wrap selected text with pairs

### render-markdown.nvim
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

### Git Signs
Git integration for modified lines and hunks.
- Line indicators show git changes
- Configured in `lua/configs/gitsigns.lua`

### Lazygit
Terminal UI for Git.
- `<leader>gg` - Open Lazygit

### Unified.nvim
Inline git diff viewer.
- `<leader>gd` - Toggle inline diff

### distant.nvim (Remote Development)
Edit files, run programs, and use LSP on remote machines (e.g., Raspberry Pi).
- **Group:** `<leader>r` (remote)

**Keybindings:**
| Key | Action |
|-----|--------|
| `<leader>rl` | Launch distant server and connect (prompts for ssh://user@host) |
| `<leader>rp` | Quick connect to Raspberry Pi (192.168.101.7) |
| `<leader>ro` | Open remote file or directory (enter path) |
| `<leader>rs` | Open interactive shell on remote machine |
| `<leader>rx` | Spawn/run command on remote (enter command) |

**Available Commands:**
| Command | Action |
|---------|--------|
| `:DistantLaunch ssh://user@host` | SSH to remote, start server, and connect |
| `:DistantConnect ssh://user@host` | Connect to already running distant server |
| `:DistantOpen /path/` | Open a remote file or directory |
| `:DistantShell` | Open interactive shell on remote |
| `:DistantSpawn <command>` | Run a command on remote machine |
| `:checkhealth distant` | Check installation status |

**First-Time Setup:**
1. Install distant locally (macOS):
   ```bash
   curl -L https://sh.distant.dev | sh
   ```
2. Install distant on your Raspberry Pi:
   ```bash
   ssh user@pi 'curl -L https://sh.distant.dev | sh'
   ```
3. Add all SSH host keys (required for distant's SSH library):
   ```bash
   ssh-keyscan <pi-ip> >> ~/.ssh/known_hosts
   ```

**Workflow (after restart):**
```
1. Open Neovim
2. <leader>rp              → Connects to Pi at 192.168.101.7
   (or <leader>rl          → Enter custom ssh://user@host)
3. <leader>ro /home/ukibbb/ → Browse remote files
4. Edit files normally, :w saves to Pi
5. <leader>rx python main.py → Run script on Pi
6. <leader>rs              → Open shell for interactive work
7. Close Neovim when done (server shuts down automatically)
```

**If Pi IP changes:** Run `find_rasp.sh` to discover new IP, then update
`nvim/lua/configs/distant.lua` or use `<leader>rl` with the new IP.

**Configuration:** `nvim/lua/configs/distant.lua`

---

## Most Frequent Commands

| Action | You Press | Neovim Key |
|--------|-----------|------------|
| Find file | `Space ff` | `<leader>ff` |
| Toggle comment | `Space /` | `<leader>/` |
| Open file explorer | `-` | `-` |
| Previous buffer | `Cmd+h` | `<M-C-H>` |
| Next buffer | `Cmd+l` | `<M-C-L>` |
| Close buffer | `Cmd+q` | `<M-C-Q>` |
| Vertical split | `Cmd+\` | `<M-C-\>` |
| Horizontal split | `Cmd+-` | `<M-C-_>` |
| Go to definition | `gd` | `gd` |
| Rename symbol | `Space ra` | `<leader>ra` |
| Open Lazygit | `Space gg` | `<leader>gg` |
| Toggle inline diff | `Space gd` | `<leader>gd` |
