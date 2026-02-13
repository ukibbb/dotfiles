# PostToolUse Hook Command Explanation

This document explains the Claude Code hook that notifies Neovim instances when files are edited.

## Full Command

```bash
fp=$(cat | jq -r '.tool_input.file_path'); for s in /tmp/nvim*.sock; do [ -S "$s" ] && nvim --server "$s" --remote-expr "bufloaded('$fp')" 2>/dev/null | grep -q 1 && nvim --server "$s" --remote-expr "execute('checktime')" 2>/dev/null; done; true
```

## Line-by-Line Breakdown

### Part 1: Extract File Path

```bash
fp=$(cat | jq -r '.tool_input.file_path')
```

| Component | Description |
|-----------|-------------|
| `fp=` | Assign result to variable `fp` |
| `$(...)` | Command substitution - run command and capture output |
| `cat` | Read JSON from stdin (Claude sends hook data via stdin) |
| `\|` | Pipe output to next command |
| `jq` | JSON processor tool |
| `-r` | Raw output (no quotes around strings) |
| `'.tool_input.file_path'` | jq filter - extract `file_path` from `tool_input` object |

**Input example:**
```json
{
  "tool_input": {
    "file_path": "/Users/lukasz/project/foo.lua",
    "old_string": "...",
    "new_string": "..."
  }
}
```

**Result:** `fp="/Users/lukasz/project/foo.lua"`

---

### Part 2: Loop Through Sockets

```bash
for s in /tmp/nvim*.sock; do
```

| Component | Description |
|-----------|-------------|
| `for s in` | Loop variable `s` iterates over list |
| `/tmp/nvim*.sock` | Glob pattern matching all nvim socket files |
| `*` | Wildcard - matches any characters |
| `do` | Begin loop body |

**Socket naming** (from `.zshrc` nvim function):
- `/tmp/nvim_Users_lukasz_project.sock` - first instance in `/Users/lukasz/project`
- `/tmp/nvim_Users_lukasz_project_1.sock` - second instance in same directory

**Note:** If no sockets match the glob, the loop body runs once with the literal
pattern string. The `[ -S "$s" ]` check fails immediately, so nothing happens.

---

### Part 3: Validate Socket

```bash
[ -S "$s" ]
```

| Component | Description |
|-----------|-------------|
| `[` | Test command (same as `test`) |
| `-S` | Check if file is a socket |
| `"$s"` | Socket path (quoted for spaces) |
| `]` | End test command |

**Returns:** Exit code 0 (true) if socket exists, 1 (false) otherwise

---

### Part 4: Check If File Is Loaded

```bash
nvim --server "$s" --remote-expr "bufloaded('$fp')" 2>/dev/null | grep -q 1
```

#### Neovim Part

| Component | Description |
|-----------|-------------|
| `nvim` | Neovim executable |
| `--server "$s"` | Connect to Neovim instance at socket `$s` |
| `--remote-expr` | Evaluate Vimscript expression in remote instance |
| `"bufloaded('$fp')"` | Vimscript function call |
| `bufloaded()` | Returns 1 if buffer is loaded, 0 if not |
| `'$fp'` | File path (shell expands `$fp` before sending) |
| `2>/dev/null` | Redirect stderr to null (hide connection errors) |

#### Grep Part

| Component | Description |
|-----------|-------------|
| `\|` | Pipe nvim output to grep |
| `grep` | Search for pattern |
| `-q` | Quiet mode (no output, just exit code) |
| `1` | Pattern to match (bufloaded returns "1" or "0") |

**Combined result:** Exit code 0 if buffer is loaded, 1 if not

---

### Part 5: Trigger Reload via Expression

```bash
nvim --server "$s" --remote-expr "execute('checktime')" 2>/dev/null
```

| Component | Description |
|-----------|-------------|
| `nvim` | Neovim executable |
| `--server "$s"` | Connect to same socket |
| `--remote-expr` | Evaluate Vimscript expression (synchronous) |
| `"execute('checktime')"` | Run `:checktime` and return its output |
| `2>/dev/null` | Suppress stderr (connection errors, empty output) |

**Why `--remote-expr` instead of `--remote-send`:**
- `--remote-send` injects keystrokes into the input queue (fire-and-forget, unreliable)
- `--remote-expr` evaluates synchronously - blocks until Neovim processes the command
- `execute()` runs an Ex command and returns its output as a string

**What `checktime` does:**
1. Compares buffer modification time with file on disk
2. If file is newer, triggers reload via `autoread` or `FileChangedShell` autocmd

---

### Part 6: Chain Operators

```bash
&& ... && ...
```

| Operator | Description |
|----------|-------------|
| `&&` | AND operator - run next command only if previous succeeded (exit 0) |

**Chain logic:**
```
socket exists? → file loaded? → trigger checktime
     ↓ no           ↓ no
   (skip)         (skip)
```

---

### Part 7: End Loop and Ensure Success

```bash
done; true
```

| Component | Description |
|-----------|-------------|
| `done` | End of for loop |
| `;` | Command separator |
| `true` | Command that always exits with 0 |

**Why `true`:** Hook expects exit code 0. Without it, if no sockets match or no buffers loaded, last command's non-zero exit causes hook error.

---

## Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Claude edits file → Hook receives JSON via stdin            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Extract file path with jq                                   │
│ fp="/Users/lukasz/project/foo.lua"                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Find all nvim sockets: /tmp/nvim*.sock                      │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐    ┌──────────┐
        │ Socket 1 │   │ Socket 2 │    │ Socket 3 │
        └──────────┘   └──────────┘    └──────────┘
              │               │               │
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐    ┌──────────┐
        │bufloaded?│   │bufloaded?│    │bufloaded?│
        │   = 1    │   │   = 0    │    │   = 1    │
        └──────────┘   └──────────┘    └──────────┘
              │               │               │
              ▼               ✗               ▼
        ┌──────────┐                   ┌──────────┐
        │checktime │                   │checktime │
        │ (reload) │                   │ (reload) │
        └──────────┘                   └──────────┘
```

## Neovim Side: How Reloads and Diff Highlights Work

When `checktime` detects a file change, Neovim reloads the buffer and shows
a diff of what changed (green for additions, red for deletions).

### The Problem with `autoread`

With `autoread = true`, Neovim may reload the buffer **without** firing
`FileChangedShell`. If we only saved the pre-reload content in that event,
we'd have nothing to diff against — resulting in no highlights.

### Solution: Running Snapshot

Instead of relying solely on `FileChangedShell`, we maintain a running
snapshot of each buffer's content:

```
BufReadPost     → save snapshot (buffer just loaded from disk)
BufWritePost    → save snapshot (buffer just saved, matches disk)
FileChangedShell → save snapshot (freshest content before reload)
```

This guarantees `FileChangedShellPost` always has a baseline to diff against.

### Event Flow

```
checktime detects file changed on disk
        │
        ├─── autoread path ──────────┐
        │    (FileChangedShell       │
        │     may NOT fire)          │
        │                            │
        ├─── non-autoread path ──┐   │
        │    FileChangedShell    │   │
        │    saves snapshot +    │   │
        │    sets fcs_choice     │   │
        │    = "reload"          │   │
        │                        │   │
        ▼                        ▼   ▼
   Buffer reloaded from disk ◄───────┘
        │
        ▼
   FileChangedShellPost fires (always)
        │
        ├─ Get old content from snapshot
        ├─ Get new content from buffer
        ├─ vim.diff() with histogram algorithm
        ├─ Highlight added lines (green extmarks)
        ├─ Show deleted lines (red virtual lines above)
        ├─ Update snapshot to new content
        └─ Force treesitter re-parse (keeps syntax colors)
```

### Clearing Highlights

Press `<leader>ch` to dismiss the diff highlights after reviewing.

## Related Configuration

### Neovim Socket Creation (`.zshrc`)

```bash
nvim() {
    local dir_slug=$(pwd | tr '/' '_')      # /Users/foo → _Users_foo
    local base="/tmp/nvim${dir_slug}"        # /tmp/nvim_Users_foo
    local sock="${base}.sock"                # /tmp/nvim_Users_foo.sock
    # ... finds available socket, starts nvim with --listen
    command nvim --listen "$sock" "$@"
}
```

### Required Neovim Settings

```lua
-- Auto-reload files changed outside of Neovim
vim.opt.autoread = true
```
