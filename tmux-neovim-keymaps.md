# Tmux + Neovim Keymaps Cheat Sheet

This file combines:

- your actual local `tmux.conf` bindings
- your actual local Neovim mappings from `nvim/`
- documented default keybindings for every plugin in your current Neovim plugin set

Notes:

- tmux prefix: `Ctrl-s`
- Neovim leader: `Space`
- `n`, `i`, `v`, `x`, `s` mean normal, insert, visual, visual-select, and select mode
- plugin-default sections are taken from upstream docs/README at the versions pinned in `nvim/lazy-lock.json` when practical; `distant.nvim` used current official docs; local plugins were read directly from `watchdiff.nvim/` and `claude.nvim/`
- `Comment.nvim` is intentionally omitted because it is not in the current plugin set

## Tmux

### Local tmux bindings from `tmux.conf`

| Key | Action | Notes |
|---|---|---|
| `Ctrl-s` | tmux prefix | Replaces default `Ctrl-b` |
| `prefix Ctrl-s` | Send literal tmux prefix | Useful for nested tmux |
| `prefix |` | Split pane left/right | `split-window -h -c "#{pane_current_path}"` |
| `prefix -` | Split pane top/bottom | `split-window -v -c "#{pane_current_path}"` |
| `prefix c` | New window in current pane cwd | Overrides default `c` to preserve cwd |
| `prefix r` | Reload `~/.tmux.conf` | Overrides tmux default redraw binding |
| `prefix h` | Resize pane left by 5 | Repeatable |
| `prefix j` | Resize pane down by 5 | Repeatable |
| `prefix k` | Resize pane up by 5 | Repeatable |
| `prefix l` | Resize pane right by 5 | Repeatable; overrides default last-window |
| `prefix m` | Toggle zoom for current pane | Overrides default mark-pane |
| `prefix Ctrl-j` | Open `tmux-fzf` session switcher | `scripts/session.sh switch` |
| `prefix Ctrl-g` | Repair pane after broken fullscreen/mouse state | Sends escape sequences plus `stty sane` |
| `prefix [` | Enter copy mode | tmux default, still active |
| `copy-mode-vi v` | Begin selection | Explicitly set |
| `copy-mode-vi y` | Copy selection | Explicitly set |

Behavior changes:

- mouse support is on
- copy mode uses `vi` keys (`set-window-option -g mode-keys vi`)
- `MouseDragEnd1Pane` is unbound in `copy-mode-vi`, so mouse drag selection does not auto-exit copy mode

### Important tmux defaults still available

#### Sessions

| Key | Action |
|---|---|
| `prefix d` | Detach session |
| `prefix s` | List sessions |
| `prefix $` | Rename session |
| `prefix (` | Previous session |
| `prefix )` | Next session |
| `prefix L` | Last session |

#### Windows

| Key | Action |
|---|---|
| `prefix n` | Next window |
| `prefix p` | Previous window |
| `prefix 0-9` | Go to window by number |
| `prefix w` | Window list |
| `prefix ,` | Rename window |
| `prefix &` | Kill window |

#### Panes

| Key | Action |
|---|---|
| `prefix o` | Cycle panes |
| `prefix ;` | Toggle last two panes |
| `prefix q` | Show pane numbers |
| `prefix x` | Kill pane |
| `prefix !` | Break pane into new window |
| `prefix {` | Move pane left |
| `prefix }` | Move pane right |
| `prefix Space` | Cycle pane layouts |

#### Copy mode / misc

| Key | Action |
|---|---|
| `prefix [` | Enter copy mode |
| `copy-mode-vi h/j/k/l` | Move in copy mode |
| `copy-mode-vi Ctrl-u` | Half-page up |
| `copy-mode-vi Ctrl-d` | Half-page down |
| `copy-mode-vi /` | Search forward |
| `copy-mode-vi ?` | Search backward |
| `copy-mode-vi q` | Exit copy mode |
| `prefix ?` | List keybindings |
| `prefix :` | Command prompt |

### tmux defaults explicitly overridden or removed

| Default key | Default action | Local state |
|---|---|---|
| `Ctrl-b` | tmux prefix | Removed |
| `prefix Ctrl-b` | Send literal prefix | Replaced by `prefix Ctrl-s` |
| `prefix %` | Split left/right | Replaced by `prefix |` |
| `prefix "` | Split top/bottom | Replaced by `prefix -` |
| `prefix r` | Redraw client | Replaced by reload config |
| `prefix l` | Last window | Replaced by resize right |
| `prefix m` | Mark pane | Replaced by zoom toggle |

### tmux plugin defaults

#### `tmux-plugins/tpm`

| Key | Action |
|---|---|
| `prefix I` | Install plugins |
| `prefix U` | Update plugins |
| `prefix Alt-u` | Remove plugins not in config |

#### `sainnhe/tmux-fzf`

| Key | Action |
|---|---|
| `prefix F` | Open `tmux-fzf` |
| `Tab` | Multi-select inside `fzf` |
| `Shift-Tab` | Reverse multi-select inside `fzf` |

#### `christoomey/vim-tmux-navigator`

These work without the tmux prefix and are meant to feel identical in tmux and Neovim:

| Key | Action |
|---|---|
| `Ctrl-h` | Move left |
| `Ctrl-j` | Move down |
| `Ctrl-k` | Move up |
| `Ctrl-l` | Move right |
| `Ctrl-\` | Previous split/pane |

## Neovim

### Global facts

- leader: `Space`
- lazy.nvim plugin list: `nvim/lua/plugins/init.lua`
- hand-written global mappings: `nvim/lua/mappings.lua`
- LSP buffer-local mappings: `nvim/lua/configs/lspconfig.lua`
- special buffer mappings and Claude dev helpers: `nvim/lua/autocmds.lua`

### Local Neovim mappings from your config

#### Insert mode

| Key | Action |
|---|---|
| `jk` | Exit insert mode |
| `Ctrl-b` | Move to first non-blank character of line |
| `Ctrl-e` | Move to line end |
| `Ctrl-h` | Left |
| `Ctrl-l` | Right |
| `Ctrl-j` | Down |
| `Ctrl-k` | Up |

#### Window / split helpers

These are the actual keycodes Neovim sees after your Karabiner setup:

| Mode | Key | Action |
|---|---|---|
| `n` | `<M-C-\>` | Vertical split |
| `n` | `<M-C-_>` | Horizontal split |

#### General normal-mode helpers

| Key | Action |
|---|---|
| `Esc` | Clear search highlighting |
| `;` | Enter command-line mode (`:`) |
| `Ctrl-c` | Copy whole file to system clipboard |
| `Ctrl-a` | Select whole file |
| `J` | Join lines and keep cursor position |
| `Ctrl-d` | Half-page down and center cursor |
| `Ctrl-u` | Half-page up and center cursor |
| `n` | Next search result, centered |
| `N` | Previous search result, centered |

#### Visual / select mode helpers

| Mode | Key | Action |
|---|---|---|
| `v` | `J` | Move selected lines down |
| `v` | `K` | Move selected lines up |
| `x` | `p` | Paste without yanking replaced text |

#### Toggles / utility leader mappings

| Key | Action |
|---|---|
| `<leader>n` | Toggle absolute line numbers |
| `<leader>rn` | Toggle relative numbers |
| `<leader>w` | Toggle wrap |
| `<leader>y` | Copy whole file to system clipboard |

#### Formatting, diagnostics, quickfix

| Mode | Key | Action |
|---|---|---|
| `n,x` | `<leader>fm` | Format with `conform.nvim` (`lsp_fallback = true`) |
| `n` | `<leader>ds` | Put diagnostics in loclist |
| `n` | `[d` | Previous diagnostic |
| `n` | `]d` | Next diagnostic |
| `n` | `<leader>d` | Diagnostic float |
| `n` | `<leader>q` | Diagnostics loclist |
| `n` | `[q` | Previous quickfix item and center |
| `n` | `]q` | Next quickfix item and center |

#### Bufferline / tabufline helpers

These only load if `require("nvconfig").ui.tabufline.enabled` is true.

| Key | Action |
|---|---|
| `<leader>b` | New empty buffer |
| `<M-C-H>` | Previous buffer |
| `<M-C-L>` | Next buffer |
| `<M-C-Q>` | Close current buffer |

#### Telescope launchers from your config

| Key | Action |
|---|---|
| `<leader>fw` | `Telescope live_grep` |
| `<leader>fb` | `Telescope buffers` |
| `<leader>fh` | `Telescope help_tags` |
| `<leader>ma` | `Telescope marks` |
| `<leader>fo` | `Telescope oldfiles` |
| `<leader>fz` | `Telescope current_buffer_fuzzy_find` |
| `<leader>cm` | `Telescope git_commits` |
| `<leader>gt` | `Telescope git_status` |
| `<leader>th` | NvChad theme picker |
| `<leader>ff` | `Telescope find_files` |
| `<leader>fa` | `Telescope find_files follow=true no_ignore=true hidden=true` |

#### File tree / git / diff / remote launchers from your config

| Key | Action |
|---|---|
| `<leader>e` | Toggle `nvim-tree` |
| `<leader>E` | Reveal current file in `nvim-tree` |
| `<leader>gd` | Toggle `unified.nvim` |
| `<leader>gg` | Open `Neogit` |
| `<leader>gc` | Open `Neogit commit` popup |
| `<leader>gp` | Open `Neogit push` popup |
| `<leader>gP` | Open `Neogit pull` popup |
| `<leader>gb` | Open `Neogit branch` popup |
| `<leader>gv` | `DiffviewOpen` |
| `<leader>gm` | `DiffviewOpen origin/main...HEAD` |
| `<leader>gl` | `DiffviewFileHistory %` |
| `<leader>gL` | `DiffviewFileHistory` |
| `<leader>gq` | `DiffviewClose` |
| `<leader>gD` | Open `codediff.nvim` explorer |
| `<leader>gf` | Diff current file vs `HEAD` |
| `<leader>gh` | `CodeDiff history` |
| `<leader>rl` | Prompt and run `DistantLaunch` |
| `<leader>ro` | Start `:DistantOpen` command-line |
| `<leader>rs` | `DistantShell` |
| `<leader>rx` | Start `:DistantSpawn` command-line |
| `<leader>rp` | Launch Distant to `ssh://ukibbb@192.168.101.7` |

#### Completion popup mappings from your local `nvim-cmp` config

These are not plugin defaults; they are your configured completion-menu bindings in `nvim/lua/configs/cmp.lua`.

| Mode | Key | Action |
|---|---|---|
| `i,s` | `Ctrl-p` | Previous completion item |
| `i,s` | `Alt-k` | Previous completion item |
| `i,s` | `Ctrl-n` | Next completion item |
| `i,s` | `Alt-j` | Next completion item |
| `i,s` | `Ctrl-d` | Scroll docs up |
| `i,s` | `Ctrl-f` | Scroll docs down |
| `i,s` | `Ctrl-Space` | Open completion menu |
| `i,s` | `Ctrl-e` | Close completion menu |
| `i,s` | `Enter` | Confirm completion |
| `i,s` | `Tab` | Next completion item, or expand/jump snippet, or fallback |
| `i,s` | `Shift-Tab` | Previous completion item, or snippet jump back, or fallback |

### Buffer-local / contextual mappings from your config

#### LSP buffer-local mappings from `configs/lspconfig.lua`

These exist only after an LSP client attaches.

| Key | Action |
|---|---|
| `gD` | Go to declaration |
| `gd` | Go to definition |
| `<leader>wa` | Add workspace folder |
| `<leader>wr` | Remove workspace folder |
| `<leader>wl` | Print workspace folders |
| `<leader>D` | Go to type definition |
| `<leader>ra` | NvChad LSP renamer |

#### Special buffers closed with `q` from `autocmds.lua`

For these filetypes, `q` closes the window and the buffer is unlisted:

- `help`
- `qf`
- `lspinfo`
- `man`
- `notify`
- `spectre_panel`
- `startuptime`
- `checkhealth`

#### `nvim-tree` extra buffer-local mappings from your config

Your `on_attach` first installs all `nvim-tree` defaults, then adds:

| Key | Action |
|---|---|
| `<M-C-\>` | Open node in vertical split |
| `<M-C-_>` | Open node in horizontal split |

#### `claude.nvim` dev helpers auto-loaded by your config

When you first enter a file matching `*/claude.nvim/lua/*.lua`, `autocmds.lua` runs `require("claude.dev").setup()` once for that Neovim session.

| Key | Action |
|---|---|
| `<leader>rr` | Reload `claude.nvim` |
| `<leader>rt` | Reload and open popup |
| `<leader>rd` | Show debug info |

## Neovim plugin defaults appendix

The sections below cover every plugin in the current Lazy plugin list.

### `nvim-lua/plenary.nvim`

- No documented default keybindings.
- Command: `:PlenaryBustedDirectory`
- Note: docs mention `<Plug>PlenaryTestFile`, but no default user key is assigned.

### `nvim-tree/nvim-web-devicons`

- No documented default keybindings.
- Command: `:NvimWebDeviconsHiTest`

### `nvchad/base46`

- No documented default keybindings.

### `nvchad/ui`

- No documented default keybindings.
- Command: `:MasonInstallAll`

### `nvzone/volt`

- No documented default keybindings.

### `nvzone/menu`

Documented default menu UI keys:

| Key | Action |
|---|---|
| `h` | Move to previous window/column |
| `l` | Move to next window/column |
| `q` | Close menu |
| `Enter` | Execute selected item |

### `nvzone/minty`

- No documented default keybindings.
- Commands: `:Shades`, `:Huefy`

### `lukas-reineke/indent-blankline.nvim`

- No documented default keybindings.
- Commands: `:IBLEnable`, `:IBLDisable`, `:IBLToggle`, `:IBLEnableScope`, `:IBLDisableScope`, `:IBLToggleScope`

### `stevearc/conform.nvim`

- No documented default keybindings.

### `mfussenegger/nvim-lint`

- No documented default keybindings.

### `neovim/nvim-lspconfig`

`nvim-lspconfig` itself does not install a custom key layer; upstream docs point to Neovim 0.11 LSP and diagnostic defaults.

Built-in LSP defaults:

| Mode | Key | Action |
|---|---|---|
| `n` | `grn` | Rename |
| `n` | `grr` | References |
| `n` | `gri` | Implementation |
| `n` | `grt` | Type definition |
| `n` | `gO` | Document symbols |
| `n` | `K` | Hover |
| `n,v` | `gra` | Code action |
| `i` | `Ctrl-s` | Signature help |

Built-in diagnostic defaults:

| Mode | Key | Action |
|---|---|---|
| `n` | `]d` | Next diagnostic |
| `n` | `[d` | Previous diagnostic |
| `n` | `]D` | Last diagnostic |
| `n` | `[D` | First diagnostic |
| `n` | `Ctrl-w d` | Diagnostic float |

### `lewis6991/gitsigns.nvim`

- No documented default keybindings.
- Documented commands: `:Gitsigns stage_hunk`, `reset_hunk`, `preview_hunk_inline`, `preview_hunk`, `nav_hunk next|prev`, `blame`, `blame_line`, `toggle_current_line_blame`, `change_base`, `diffthis`, `toggle_word_diff`, `setqflist`, `setloclist`, `show`

### `axkirillov/unified.nvim`

Documented default file-tree UI keys:

| Key | Action |
|---|---|
| `j` / `Down` | Move down |
| `k` / `Up` | Move up |
| `l` | Open file diff |
| `q` | Close tree |
| `R` | Refresh |
| `?` | Help |

Your config also adds the global launcher `<leader>gd`.

### `mason-org/mason.nvim`

Documented `:Mason` UI keys:

| Key | Action |
|---|---|
| `Enter` | Expand package / show install log |
| `i` | Install package |
| `u` | Update package |
| `c` | Check package version |
| `U` | Update all |
| `C` | Check outdated |
| `X` | Uninstall |
| `Ctrl-c` | Cancel installation |
| `Ctrl-f` | Language filter |
| `g?` | Help |

### `hrsh7th/nvim-cmp`

- No documented default keybindings.
- Upstream docs present configurable mapping presets, not shipped active defaults.
- Your active completion keys are listed earlier in the local mappings section.

### `L3MON4D3/LuaSnip`

- No documented default keybindings.
- Upstream docs show example mappings and `<Plug>` targets, but no default active keys.

### `rafamadriz/friendly-snippets`

- No documented default keybindings.

### `windwp/nvim-autopairs`

Documented default mappings/behaviors:

| Mode / context | Key | Action |
|---|---|---|
| `i` | `Enter` | Smart newline / pair handling |
| `i` | `Backspace` | Pair-aware backspace |
| `i` | `Alt-e` | FastWrap trigger |

Documented but disabled by default:

| Key | Action |
|---|---|
| `Ctrl-h` | Delete previous pair char |
| `Ctrl-w` | Delete pair by word |

Your config enables `fast_wrap`, so the documented default `Alt-e` FastWrap trigger is relevant.

### `saadparwaiz1/cmp_luasnip`

- No documented default keybindings.

### `hrsh7th/cmp-nvim-lua`

- No documented default keybindings.

### `hrsh7th/cmp-nvim-lsp`

- No documented default keybindings.

### `hrsh7th/cmp-buffer`

- No documented default keybindings.

### `FelipeLema/cmp-async-path`

- No documented default keybindings.

### `nvim-telescope/telescope.nvim`

Documented default picker mappings:

#### Common picker keys

| Mode | Key | Action |
|---|---|---|
| `i` | `Ctrl-n` / `Down` | Next item |
| `i` | `Ctrl-p` / `Up` | Previous item |
| `i` | `Enter` | Confirm selection |
| `i` | `Ctrl-x` | Open in horizontal split |
| `i` | `Ctrl-v` | Open in vertical split |
| `i` | `Ctrl-t` | Open in tab |
| `i` | `Ctrl-u` | Preview scroll up |
| `i` | `Ctrl-d` | Preview scroll down |
| `i` | `Ctrl-f` | Preview scroll left |
| `i` | `Ctrl-k` | Preview scroll right |
| `i` | `Alt-f` | Results scroll left |
| `i` | `Alt-k` | Results scroll right |
| `i` | `Tab` | Toggle selection and move next |
| `i` | `Shift-Tab` | Toggle selection and move previous |
| `i` | `Ctrl-q` | Send all items to quickfix |
| `i` | `Alt-q` | Send selected items to quickfix |
| `n` | `j` | Next item |
| `n` | `k` | Previous item |
| `n` | `H` | Move selection to top |
| `n` | `M` | Move selection to middle |
| `n` | `L` | Move selection to bottom |
| `n` | `gg` | First item |
| `n` | `G` | Last item |
| `n` | `Enter` | Confirm selection |
| `n` | `Ctrl-x` | Open in horizontal split |
| `n` | `Ctrl-v` | Open in vertical split |
| `n` | `Ctrl-t` | Open in tab |
| `n` | `Ctrl-u` | Preview scroll up |
| `n` | `Ctrl-d` | Preview scroll down |
| `n` | `Tab` | Toggle selection and move next |
| `n` | `Shift-Tab` | Toggle selection and move previous |
| `n` | `Ctrl-q` | Send all items to quickfix |
| `n` | `Alt-q` | Send selected items to quickfix |

#### Extra insert-mode defaults

| Key | Action |
|---|---|
| `Ctrl-/` | Show picker mappings |
| `Ctrl-c` | Close picker |
| `Ctrl-r Ctrl-w` | Insert current word |
| `Ctrl-r Ctrl-a` | Insert current WORD |
| `Ctrl-r Ctrl-f` | Insert current filename |
| `Ctrl-r Ctrl-l` | Insert current line |

#### Extra normal-mode defaults

| Key | Action |
|---|---|
| `?` | Show picker mappings |
| `Esc` | Close picker |

#### Picker-specific documented defaults

`git_commits` picker:

| Key | Action |
|---|---|
| `Ctrl-r m` | Checkout commit |
| `Ctrl-r s` | Reset mixed to commit |
| `Ctrl-r h` | Reset hard to commit |

`git_branches` picker:

| Key | Action |
|---|---|
| `Enter` | Checkout selected branch |
| `Ctrl-t` | Track selected branch |
| `Ctrl-r` | Rebase selected branch |
| `Ctrl-a` | Create branch from selected branch |
| `Ctrl-s` | Switch branch |
| `Ctrl-d` | Delete selected branch |
| `Ctrl-y` | Merge selected branch |

Your config also adds or overrides:

- insert mode: `Alt-j` / `Alt-k` move selection
- normal mode: `q` closes Telescope

### `nvim-treesitter/nvim-treesitter`

Documented default keys only for the optional `incremental_selection` module.

| Mode | Key | Action |
|---|---|---|
| `n` | `gnn` | Init selection |
| `x` | `grn` | Expand to next node |
| `x` | `grc` | Expand to next scope |
| `x` | `grm` | Shrink selection |

Your current `treesitter` config does not enable `incremental_selection`, so these are documented defaults, not active runtime bindings.

### `MeanderingProgrammer/render-markdown.nvim`

- No documented default keybindings.
- Commands: `:RenderMarkdown`, `:RenderMarkdown enable`, `:RenderMarkdown buf_enable`, `:RenderMarkdown disable`, `:RenderMarkdown buf_disable`, `:RenderMarkdown toggle`, `:RenderMarkdown buf_toggle`, `:RenderMarkdown get`, `:RenderMarkdown set [bool?]`, `:RenderMarkdown set_buf [bool?]`, `:RenderMarkdown preview`, `:RenderMarkdown log`, `:RenderMarkdown expand`, `:RenderMarkdown contract`, `:RenderMarkdown debug`, `:RenderMarkdown config`

### `chipsenkbeil/distant.nvim`

Documented default keys:

#### File buffer

| Key | Action |
|---|---|
| `-` | Open parent directory |

#### Directory buffer

| Key | Action |
|---|---|
| `Enter` | Open selected entry |
| `-` | Open parent directory |
| `Shift-K` | Create directory |
| `Shift-N` | Create file |
| `Shift-R` | Rename |
| `Shift-D` | Remove |
| `Shift-M` | Metadata |
| `Shift-C` | Copy |
| `Ctrl-t` | Open in new tab |

#### Distant UI

| Key | Action |
|---|---|
| `q` | Exit UI |
| `Esc` | Exit UI |
| `1` | Connections tab |
| `2` | System-info tab |
| `?` | Help |
| `R` | Refresh |
| `K` | Kill connection |
| `I` | Toggle connection info |

Note: official docs currently disagree in one place about directory-open defaults, but the navigation docs describe `Enter` as the default open key.

### `christoomey/vim-tmux-navigator`

Documented default keys:

| Key | Action |
|---|---|
| `Ctrl-h` | Move left |
| `Ctrl-j` | Move down |
| `Ctrl-k` | Move up |
| `Ctrl-l` | Move right |
| `Ctrl-\` | Previous split |

These are the same keys you also use on the tmux side.

### `nvim-tree/nvim-tree.lua`

#### Documented global launchers from your config

| Key | Action |
|---|---|
| `<leader>e` | Toggle tree |
| `<leader>E` | Find current file in tree |

#### Documented default tree-buffer mappings

| Key | Action |
|---|---|
| `Ctrl-]` | Change root to node |
| `Ctrl-e` | Open in place |
| `Ctrl-k` | Show node info |
| `Ctrl-r` | Rename without filename |
| `Ctrl-t` | Open in new tab |
| `Ctrl-v` | Open in vertical split |
| `Ctrl-x` | Open in horizontal split |
| `Backspace` | Close directory |
| `Enter` | Open |
| `Del` | Delete |
| `Tab` | Preview |
| `>` | Next sibling |
| `<` | Previous sibling |
| `.` | Run command |
| `-` | Up |
| `a` | Create |
| `bd` | Delete bookmarked |
| `bt` | Trash bookmarked |
| `bmv` | Move bookmarked |
| `B` | Toggle no-buffer filter |
| `c` | Copy |
| `C` | Toggle git-clean filter |
| `[c` | Previous git item |
| `]c` | Next git item |
| `d` | Delete |
| `D` | Trash |
| `E` | Expand all |
| `e` | Rename basename |
| `[e` | Previous diagnostic |
| `]e` | Next diagnostic |
| `F` | Clear live filter |
| `f` | Start live filter |
| `g?` | Help |
| `gy` | Copy absolute path |
| `ge` | Copy basename |
| `H` | Toggle dotfiles |
| `I` | Toggle gitignore |
| `J` | Last sibling |
| `K` | First sibling |
| `L` | Toggle group-empty |
| `M` | Toggle no-bookmark filter |
| `m` | Toggle bookmark |
| `o` | Open |
| `O` | Open without window picker |
| `p` | Paste |
| `P` | Parent directory |
| `q` | Close tree |
| `r` | Rename |
| `R` | Refresh |
| `s` | Run system command |
| `S` | Search |
| `u` | Rename full path |
| `U` | Toggle hidden filter |
| `W` | Collapse all |
| `x` | Cut |
| `y` | Copy node name |
| `Y` | Copy relative path |

Mouse defaults:

| Mouse | Action |
|---|---|
| `2-LeftMouse` | Open |
| `2-RightMouse` | Change root to node |

Your config also adds these extra tree-buffer keys after installing defaults:

| Key | Action |
|---|---|
| `<M-C-\>` | Open in vertical split |
| `<M-C-_>` | Open in horizontal split |

### `NeogitOrg/neogit`

#### Global launchers from your config

| Key | Action |
|---|---|
| `<leader>gg` | Open Neogit |
| `<leader>gc` | Commit popup |
| `<leader>gp` | Push popup |
| `<leader>gP` | Pull popup |
| `<leader>gb` | Branch popup |

#### Commit editor defaults

| Key | Action |
|---|---|
| `q` | Close |
| `Ctrl-c Ctrl-c` | Submit commit |
| `Ctrl-c Ctrl-k` | Abort |
| `Alt-p` | Previous commit message/history item |
| `Alt-n` | Next commit message/history item |
| `Alt-r` | Reset/refresh editor state |

Insert mode in commit editor:

| Key | Action |
|---|---|
| `Ctrl-c Ctrl-c` | Submit commit |
| `Ctrl-c Ctrl-k` | Abort |

#### Rebase editor defaults

| Key | Action |
|---|---|
| `p` | Pick |
| `r` | Reword |
| `e` | Edit |
| `s` | Squash |
| `f` | Fixup |
| `x` | Execute |
| `d` | Drop |
| `b` | Break |
| `q` | Quit |
| `Enter` | Open / confirm item |
| `gk` | Move up |
| `gj` | Move down |
| `Ctrl-c Ctrl-c` | Confirm rebase plan |
| `Ctrl-c Ctrl-k` | Abort rebase edit |
| `[c` | Previous conflict/change |
| `]c` | Next conflict/change |

Insert mode in rebase editor:

| Key | Action |
|---|---|
| `Ctrl-c Ctrl-c` | Confirm rebase plan |
| `Ctrl-c Ctrl-k` | Abort rebase edit |

#### Finder defaults

| Key | Action |
|---|---|
| `Enter` | Confirm selection |
| `Ctrl-c` | Close |
| `Esc` | Close |
| `Ctrl-n` | Next |
| `Ctrl-p` | Previous |
| `Down` | Next |
| `Up` | Previous |
| `Tab` | Toggle selection |
| `Ctrl-y` | Confirm multiple / yank-like selection action |
| `Space` | Toggle selection |
| `Shift-Space` | Toggle selection backward |
| `Ctrl-j` | Move down |
| `ScrollWheelDown` | Scroll down |
| `ScrollWheelUp` | Scroll up |
| `ScrollWheelLeft` | Scroll left |
| `ScrollWheelRight` | Scroll right |
| `LeftMouse` | Select |
| `2-LeftMouse` | Confirm/open |

#### Popup defaults

| Key | Action |
|---|---|
| `?` | Help |
| `A` | Cherry-pick / apply action group |
| `d` | Diff popup |
| `M` | Remote popup |
| `P` | Push popup |
| `X` | Reset popup |
| `Z` | Stash popup |
| `i` | Ignore popup |
| `t` | Tag popup |
| `b` | Branch popup |
| `B` | Bisect popup |
| `w` | Worktree popup |
| `c` | Commit popup |
| `f` | Fetch popup |
| `l` | Log popup |
| `m` | Merge popup |
| `p` | Pull popup |
| `r` | Rebase popup |
| `v` | Revert popup |

#### Status buffer defaults

| Key | Action |
|---|---|
| `j` | Next item |
| `k` | Previous item |
| `o` | Open item |
| `q` | Close |
| `I` | Initialize repo / related status action |
| `1` | Section 1 |
| `2` | Section 2 |
| `3` | Section 3 |
| `4` | Section 4 |
| `Q` | Command / quick action |
| `Tab` | Toggle section |
| `za` | Toggle fold |
| `zo` | Open fold |
| `x` | Discard |
| `s` | Stage |
| `S` | Stage all |
| `Ctrl-s` | Stage toggle / alternate stage action |
| `u` | Unstage |
| `K` | Untrack / checkout / alternate reverse action |
| `U` | Unstage all |
| `y` | Show/yank item info |
| `$` | Command / shell action |
| `Y` | Alternate yank/copy action |
| `gp` | Go to patch / popup action |
| `Ctrl-r` | Refresh |
| `Enter` | Visit/open item |
| `Shift-Enter` | Alternate open |
| `Ctrl-v` | Open in vertical split |
| `Ctrl-x` | Open in horizontal split |
| `Ctrl-t` | Open in tab |
| `{` | Previous section |
| `}` | Next section |
| `[c` | Previous change/conflict |
| `]c` | Next change/conflict |
| `Ctrl-k` | Move up / alternate previous |
| `Ctrl-j` | Move down / alternate next |
| `Ctrl-n` | Next |
| `Ctrl-p` | Previous |

### `sindrets/diffview.nvim`

#### Global launchers from your config

| Key | Action |
|---|---|
| `<leader>gv` | Open Diffview |
| `<leader>gm` | Compare `origin/main...HEAD` |
| `<leader>gl` | File history for current file |
| `<leader>gL` | Repo history |
| `<leader>gq` | Close Diffview |

#### Documented default keys: view

| Key | Action |
|---|---|
| `Tab` | Focus file panel |
| `Shift-Tab` | Focus opposite panel |
| `[F` | Previous file |
| `]F` | Next file |
| `gf` | Open file under cursor |
| `Ctrl-w Ctrl-f` | Open file in split |
| `Ctrl-w g f` | Open file in tab |
| `<leader>e` | Focus files panel |
| `<leader>b` | Toggle file panel |
| `g Ctrl-x` | Open conflict in split |
| `[x` | Previous conflict |
| `]x` | Next conflict |
| `<leader>co` | Choose ours |
| `<leader>ct` | Choose theirs |
| `<leader>cb` | Choose base |
| `<leader>ca` | Choose all |
| `dx` | Delete conflict selection |
| `<leader>cO` | Choose ours for whole file |
| `<leader>cT` | Choose theirs for whole file |
| `<leader>cB` | Choose base for whole file |
| `<leader>cA` | Choose all for whole file |
| `dX` | Delete all conflicts |

#### Documented default keys: diff layouts

`diff1` / `diff2`:

| Key | Action |
|---|---|
| `g?` | Help |

`diff3`:

| Key | Action |
|---|---|
| `2do` | Get change from side 2 |
| `3do` | Get change from side 3 |
| `g?` | Help |

`diff4`:

| Key | Action |
|---|---|
| `1do` | Get change from side 1 |
| `2do` | Get change from side 2 |
| `3do` | Get change from side 3 |
| `g?` | Help |

#### Documented default keys: file panel

| Key | Action |
|---|---|
| `j` / `Down` | Move down |
| `k` / `Up` | Move up |
| `Enter` / `o` / `l` / `2-LeftMouse` | Open diff |
| `-` | Stage/unstage entry depending on context |
| `s` | Stage file |
| `S` | Stage all |
| `U` | Unstage all |
| `X` | Restore file |
| `L` | Open commit log |
| `zo` | Open fold |
| `h` | Close parent fold |
| `zc` | Close fold |
| `za` | Toggle fold |
| `zR` | Open all folds |
| `zM` | Close all folds |
| `Ctrl-b` | Scroll up |
| `Ctrl-f` | Scroll down |
| `Tab` | Focus main view |
| `Shift-Tab` | Focus opposite panel |
| `[F` | Previous file |
| `]F` | Next file |
| `gf` | Open file under cursor |
| `Ctrl-w Ctrl-f` | Open file in split |
| `Ctrl-w g f` | Open file in tab |
| `i` | Toggle ignored files |
| `f` | Toggle folders |
| `R` | Refresh |
| `<leader>e` | Focus files panel |
| `<leader>b` | Toggle file panel |
| `g Ctrl-x` | Open conflict in split |
| `[x` | Previous conflict |
| `]x` | Next conflict |
| `g?` | Help |
| `<leader>cO` | Choose ours for whole file |
| `<leader>cT` | Choose theirs for whole file |
| `<leader>cB` | Choose base for whole file |
| `<leader>cA` | Choose all for whole file |
| `dX` | Delete all conflicts |

#### Documented default keys: file-history panel

| Key | Action |
|---|---|
| `g!` | Toggle options |
| `Ctrl-Alt-d` | Open diff for selected commit |
| `y` | Copy hash/reference |
| `L` | Open commit log details |
| `X` | Restore file/version action |
| `zo` | Open fold |
| `zc` | Close fold |
| `h` | Close parent fold |
| `za` | Toggle fold |
| `zR` | Open all folds |
| `zM` | Close all folds |
| `j` / `Down` | Move down |
| `k` / `Up` | Move up |
| `Enter` / `o` / `l` / `2-LeftMouse` | Open selection |
| `Ctrl-b` | Scroll up |
| `Ctrl-f` | Scroll down |
| `Tab` | Focus main view |
| `Shift-Tab` | Focus opposite panel |
| `[F` | Previous file |
| `]F` | Next file |
| `gf` | Open file under cursor |
| `Ctrl-w Ctrl-f` | Open file in split |
| `Ctrl-w g f` | Open file in tab |
| `<leader>e` | Focus files panel |
| `<leader>b` | Toggle file panel |
| `g Ctrl-x` | Open conflict in split |
| `g?` | Help |

#### Documented default keys: option/help panels

| Context | Key | Action |
|---|---|---|
| option panel | `Tab` | Move/focus next control |
| option panel | `q` | Close option panel |
| option panel | `g?` | Help |
| help panel | `q` | Close help |
| help panel | `Esc` | Close help |

Your local Diffview config also explicitly sets these extra/custom keys:

- view: `Tab` focus files, `q` close
- file panel: `j`, `k`, `Enter`, `q`, `s`, `-`, `S`, `u`, `U`
- file-history panel: `q`

### `esmuellert/codediff.nvim`

#### Global launchers from your config

| Key | Action |
|---|---|
| `<leader>gD` | Open CodeDiff explorer |
| `<leader>gf` | Diff current file vs `HEAD` |
| `<leader>gh` | File history |

#### Documented default keys: diff view

| Key | Action |
|---|---|
| `q` | Close diff |
| `<leader>b` | Toggle explorer/sidebar |
| `]c` | Next change |
| `[c` | Previous change |
| `]f` | Next file |
| `[f` | Previous file |
| `do` | Accept ours |
| `dp` | Accept previous/theirs, depending on view |
| `gf` | Open file |
| `-` | Stage/unstage style action |

#### Explorer defaults

| Key | Action |
|---|---|
| `Enter` | Open selection |
| `K` | Show details |
| `R` | Refresh |
| `i` | Toggle ignored files |
| `S` | Stage |
| `U` | Unstage |
| `X` | Restore |

#### History defaults

| Key | Action |
|---|---|
| `Enter` | Open selection |
| `i` | Toggle ignored/info mode |

#### Conflict-view defaults

| Key | Action |
|---|---|
| `<leader>ct` | Choose theirs |
| `<leader>co` | Choose ours |
| `<leader>cb` | Choose base |
| `<leader>cx` | Delete conflict |
| `]x` | Next conflict |
| `[x` | Previous conflict |
| `2do` | Get diff from side 2 |
| `3do` | Get diff from side 3 |

### `watchdiff.nvim` (local plugin)

Documented default keys from `watchdiff.nvim/README.md` and `lua/watchdiff.lua`:

| Context | Key | Action |
|---|---|---|
| global | `<leader>ch` | Clear external-change highlights and update baseline |
| global | `keys.history` | Optional history mapping; default is `false`, so no active key by default |
| history scratch buffer | `q` | Close history window |

Documented command:

- `:WatchDiffHistory`

### `claude.nvim` (local plugin)

#### Global defaults from `claude.nvim`

| Mode | Key | Action |
|---|---|---|
| `n` | `<leader>ac` | Open Claude popup |
| `v` | `<leader>ac` | Open Claude popup with visual selection |
| `n` | `<leader>aC` | Open Claude in comment-now mode |
| `v` | `<leader>aC` | Open Claude in comment-now mode with visual selection |

Commands:

- `:Claude`
- `:ClaudeCommentNow`
- `:ClaudeComment`

#### Input popup defaults

| Mode | Key | Action |
|---|---|---|
| `i` | `Enter` | Submit request |
| `n` | `Enter` | Submit request |
| `i` | `Ctrl-j` | Insert newline |
| `n` | `q` | Close popup |
| `n` | `Esc` | Close popup |
| `i` | `Esc` | Close popup |
| `i` | `Ctrl-c` | Cancel in-flight request |
| `i` | `Ctrl-l` | Clear input buffer |
| `i` | `Tab` | Cycle model |
| `n` | `Tab` | Cycle model |
| `i` | `F2` | Toggle answer/comment-now mode |
| `n` | `F2` | Toggle answer/comment-now mode |

#### Drawer body defaults

| Key | Action |
|---|---|
| `q` | Close drawer |
| `Esc` | Close drawer |
| `I` | Insert last answer as comments |
| `y` | Copy answer text |
| `Y` | Copy comment-ready block |
| `o` | Open full scratch answer buffer |
| `Tab` | Next tab |
| `Shift-Tab` | Previous tab |
| `1` | Answer tab |
| `2` | Question tab |
| `3` | Files tab |
| `Enter` | Open selected consulted file in split |

#### Drawer shell buffer defaults

| Key | Action |
|---|---|
| `q` | Close drawer |
| `Esc` | Close drawer |
| `1` | Answer tab |
| `2` | Question tab |
| `3` | Files tab |
| `y` | Copy answer text |
| `Y` | Copy comment-ready block |

#### Scratch answer buffer defaults

| Key | Action |
|---|---|
| `q` | Close buffer |
| `I` | Insert answer as comments |
| `y` | Copy answer |
| `Y` | Copy comment block |

#### Development helper defaults

These are plugin-provided, but they only become active in your setup when `autocmds.lua` loads `claude.dev` while editing the plugin itself.

| Key | Action |
|---|---|
| `<leader>rr` | Reload `claude.nvim` |
| `<leader>rt` | Reload and open popup |
| `<leader>rd` | Show debug info |

### `MunifTanjim/nui.nvim`

- No documented default keybindings.

## Quick grab list

If you only want the keys you are most likely to use every day:

### tmux

| Key | Action |
|---|---|
| `Ctrl-s` | Prefix |
| `prefix Ctrl-j` | Session switcher |
| `prefix c` | New window |
| `prefix |` | Vertical split |
| `prefix -` | Horizontal split |
| `Ctrl-h/j/k/l` | Move between tmux panes / Neovim splits |
| `prefix h/j/k/l` | Resize pane |
| `prefix m` | Zoom pane |
| `prefix r` | Reload config |

### Neovim

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fa` | Find all files |
| `<leader>fw` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>e` | Toggle file tree |
| `<leader>gg` | Open Neogit |
| `<leader>gv` | Open Diffview |
| `<leader>gD` | Open CodeDiff |
| `<leader>fm` | Format file |
| `<leader>d` | Diagnostic float |
| `[d` / `]d` | Previous / next diagnostic |
| `gd` / `gD` | Definition / declaration |
| `<leader>ac` | Open Claude popup |
| `<leader>aC` | Claude comment-now |
| `<leader>ch` | Clear watchdiff highlights |
