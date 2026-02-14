# watchdiff.nvim — Design Document

## Problem

AI coding tools (Claude Code, Codex, Cursor, etc.) edit files on disk outside Neovim.
Users need to see what changed without manually running diffs. Gitsigns shows git diffs,
but not "what changed since I last looked."

## Solution

A Neovim plugin that watches the filesystem, detects external changes, and highlights
them inline with green (added/changed) and red virtual lines (deleted). Highlights
accumulate until the user reviews and clears them.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Repo | Standalone GitHub repo | Proper open-source plugin |
| Name | watchdiff.nvim | Descriptive — watches files and shows diffs |
| Structure | Single file (`lua/watchdiff.lua`) | ~600 lines, linear flow, educational comments |
| Comments | Keep educational style | Makes codebase a learning resource |
| Config | Minimal | Highlight colors, debounce_ms, ignore_patterns, keymap |

## Repo Structure

```
watchdiff.nvim/
├── lua/
│   └── watchdiff.lua       -- The plugin
├── README.md
├── LICENSE
└── doc/
    └── watchdiff.txt       -- Vim help (optional, later)
```

## API

```lua
require("watchdiff").setup({
  highlights = {
    add = { bg = "#2d4f2d" },
    delete = { bg = "#4f2d2d" },
  },
  debounce_ms = 200,
  ignore_patterns = { "^%.git/", "%.swp$", "~$", "%.DS_Store$", "^4913$" },
  keys = {
    clear = "<leader>ch",  -- set to false to disable
  },
})
```

All options are optional. Defaults shown above.

## Architecture

### Core Flow

1. `setup()` called → creates highlight groups, starts fs_event watcher on CWD
2. File changes on disk → libuv `fs_event` fires → debounce 200ms
3. After debounce, compare buffer content against "acknowledged baseline"
4. Apply green extmarks (added/changed) and red virtual lines (deleted)
5. User presses `<leader>ch` → highlights cleared, baseline updated

### State

- `acknowledged_content[bufnr]` — what the user last saw/saved (the diff baseline)
- `watcher_handle` — the libuv fs_event handle watching CWD
- `debounce_timers[path]` — per-file debounce timers

### Baseline Updates

The acknowledged baseline updates when:
- User opens a file (BufReadPost)
- User saves a file (BufWritePost)
- User clears highlights (keymap)

It does NOT update on external edits — this is how highlights accumulate.

### Edge Cases Handled

- **Unsaved buffer edits**: Warns user, does not reload (protects work)
- **File not open in buffer**: Uses git HEAD as baseline, loads buffer silently
- **Own saves detected**: Skips when buffer matches disk (no false positives)
- **Large files (>5000 lines)**: Skips inline diff, suggests `:diff`
- **CWD changes**: Restarts watcher on new directory
- **Multiple Neovim instances**: Each has its own watcher, no conflicts

### Changes From Current Code

- Wrapped in `M.setup(opts)` — no side effects until setup is called
- Sets `autoread` automatically inside setup
- Config merged with defaults via `vim.tbl_deep_extend`
- All state is module-local
- Highlight groups, debounce delay, keymap, and ignore patterns are configurable

## lazy.nvim Usage

```lua
{
  "lukasz/watchdiff.nvim",
  event = "VeryLazy",
  opts = {},
}
```
