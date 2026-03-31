# watchdiff.nvim

See what changed in your files since you last looked. Watches the filesystem for external changes (from AI tools, other editors, scripts, etc.) and highlights added/changed lines in green and deleted lines in red. Highlights accumulate until you review and clear them.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "lukasz/watchdiff.nvim",
  event = "VeryLazy",
  opts = {},
}
```

### Local development

```lua
{
  dir = "~/path/to/watchdiff.nvim",
  event = "VeryLazy",
  opts = {},
}
```

## Configuration

All options are optional. Defaults shown below:

```lua
require("watchdiff").setup({
  -- Highlight colors for changes
  highlights = {
    add = { bg = "#2d4f2d" },     -- Green for added/changed lines
    delete = { bg = "#4f2d2d" },  -- Red for deleted lines (virtual text)
  },

  -- Milliseconds to wait after last fs event before processing
  debounce_ms = 200,

  -- File patterns to ignore (Lua patterns, not globs)
  ignore_patterns = { "^%.git/", "%.swp$", "~$", "%.DS_Store$", "^4913$" },

  -- Track files that changed externally even when not open in a loaded buffer
  -- (can be noisy in large repos; default false)
  track_unopened_files = false,

  -- Number of recent change-history entries kept per file
  history_limit = 50,

  -- Keymaps (set to false to disable)
  keys = {
    clear = "<leader>ch",
    history = false,
  },
})
```

## How it works

1. **Watch** — Uses libuv's `fs_event` to watch the current working directory recursively. This is the same mechanism Node.js uses, backed by efficient OS-level APIs (FSEvents on macOS, inotify on Linux).

2. **Debounce** — When a file changes, waits for rapid saves to settle (200ms by default) before processing.

3. **Diff** — Compares the file against an "acknowledged baseline" (what you last saw or saved). Uses `vim.diff` with the histogram algorithm.

4. **Highlight** — Adds green extmark highlights for added/changed lines. Shows deleted lines as red virtual text above the deletion point.

5. **Accumulate** — Highlights stack up across multiple external edits. If two different tools each edit a file, you see all changes combined.

6. **Clear** — Press `<leader>ch` to dismiss highlights and update the baseline. Future changes diff against this new baseline.

7. **Remember** — Recent change metadata is stored per file, so you can later inspect who changed a file and when via `:WatchDiffHistory`.

### Baseline updates

The acknowledged baseline updates when you:
- **Open** a file (you see the content)
- **Save** a file (you know what you saved)
- **Clear** highlights (you've reviewed the changes)

It does **not** update on external edits — this is how highlights accumulate.

## Keymaps

| Key | Action |
|-----|--------|
| `<leader>ch` | Clear change highlights and update baseline |
| `keys.history` | Show recent change history for current file |

## Commands

| Command | Action |
|---------|--------|
| `:WatchDiffHistory` | Open recent recorded change history for the current file |

## Provenance API

Other plugins can annotate the next externally detected file write.

Example:

```lua
require("watchdiff").annotate_next_change({
  path = "/absolute/path/to/file.lua",
  source = "claude.nvim",
  action = "insert_comment",
  summary = "Inserted explanation comments",
})
```

When that write is detected, watchdiff stores the metadata in history and uses it
in the notification. This is how `claude.nvim` can say not only that a file
changed, but that Claude added explanatory comments.

## FAQ

## Validation

Before building features that rely on watchdiff as a review layer, run the
standalone checklist in `VALIDATION.md`.

### How is this different from gitsigns?

Gitsigns shows the diff between your working tree and the git index/HEAD. watchdiff.nvim shows what changed since **you last looked at the file**. If an AI tool makes 5 edits, gitsigns shows the cumulative diff against git. watchdiff.nvim shows exactly what changed since you last reviewed, and lets you clear highlights as you go.

### Does this work with [tool name]?

Yes. watchdiff.nvim is tool-agnostic. It watches the filesystem, so it works with any program that writes to files: Claude Code, Codex, Cursor, vim macros from another terminal, shell scripts, etc.

### What about unsaved buffer edits?

If you have unsaved changes in a buffer and an external tool modifies the same file, watchdiff.nvim will **not** reload the buffer. It notifies you of the conflict and preserves your work. Use `:e!` to manually reload if you want to discard your edits.

### What about large files?

Files over 5000 lines skip inline diff highlighting to avoid freezing Neovim.
