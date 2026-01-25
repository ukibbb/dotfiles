# Tmux Guide

Complete guide to tmux configuration and keybindings.

**Table of Contents:**
- [Tmux Concepts](#tmux-concepts)
- [Session Management](#session-management)
- [Window Management](#window-management)
- [Pane Management](#pane-management)
- [Copy Mode](#copy-mode-vi-style)
- [Configuration](#configuration)
- [Most Frequent Commands](#most-frequent-commands)

---

## Tmux Concepts

### What is Tmux?

Tmux (Terminal Multiplexer) is a tool that lets you run multiple terminal sessions inside a single terminal window. Think of it as a window manager for your terminal that persists even when you disconnect.

**Key Benefits:**
- Keep programs running after closing your terminal
- Split your screen into multiple panes for multitasking
- Detach and reattach to sessions from anywhere
- Organize work into separate sessions (one per project)

### Understanding the Hierarchy

Tmux has three levels of organization:

```
Server (tmux instance)
  └─ Sessions (independent workspaces)
      └─ Windows (like browser tabs)
          └─ Panes (split views within a window)
```

#### Sessions
**What they are:** Independent workspaces that persist in the background.

**When to use:**
- One session per project or context (e.g., "frontend", "backend", "dotfiles")
- Sessions keep running even when you detach or close your terminal
- Switch between sessions to change contexts

**Example workflow:**
```bash
tmux new -s work      # Create "work" session
# ... do some work ...
prefix + d            # Detach (session keeps running)
tmux new -s personal  # Create "personal" session
tmux attach -t work   # Return to "work" session
```

#### Windows
**What they are:** Like tabs in a browser - multiple full-screen terminal views within a session.

**When to use:**
- Different tasks within the same project
- Keep related work in one session but separate terminal contexts
- Example: one window for editing, one for running servers, one for git commands

**Visual analogy:**
```
Session: "myproject"
  Window 1: nvim (editing code)
  Window 2: npm run dev (dev server)
  Window 3: git status (version control)
```

#### Panes
**What they are:** Split views within a single window - multiple terminals visible at once.

**When to use:**
- Need to see multiple things simultaneously
- Compare files side-by-side
- Monitor logs while running commands
- Quick reference while working

**Visual example:**
```
┌─────────────────────────┐
│ Window 1: "editor"      │
├───────────┬─────────────┤
│           │             │
│  nvim     │  terminal   │
│  (edit)   │  (test)     │
│           │             │
├───────────┴─────────────┤
│  npm run dev (logs)     │
└─────────────────────────┘
```

### Choosing Between Sessions, Windows, and Panes

**Use Sessions when:**
- Switching between completely different projects/contexts
- You want work to persist independently
- Example: separate sessions for different codebases

**Use Windows when:**
- Different tasks within the same project
- You need full-screen terminal views
- You want to keep related work grouped together

**Use Panes when:**
- You need to see multiple things at the same time
- Quick side-by-side comparisons
- Monitoring while working (logs + editor)

**Rule of thumb:** Sessions = projects, Windows = tasks, Panes = simultaneous views

---

## Tmux Prefix Key

**Prefix:** `Ctrl+s` (changed from default `Ctrl+b`)

All tmux commands below require pressing the prefix key first, unless otherwise noted. The prefix doesn't conflict with Neovim since `Ctrl+s` is mapped to save file in Neovim (normal/insert mode).

**Nested tmux:** Press `prefix + Ctrl-s` to send the prefix to a nested tmux session (e.g., when SSH'd into a remote machine running tmux).

---

## Session Management

### Creating and Attaching to Sessions

**From terminal (outside tmux):**
```bash
tmux                          # Create new session with default name
tmux new -s mysession         # Create new session named "mysession"
tmux ls                       # List all sessions
tmux attach                   # Attach to last session
tmux attach -t mysession      # Attach to specific session
tmux kill-session -t mysession # Kill specific session
tmux kill-server              # Kill all sessions
```

### Creating Sessions from Inside Tmux

**Method 1: Create in background (recommended)**
```bash
# Press prefix + : to enter command mode, then type:
new-session -d -s newsession    # Creates session in background
switch-client -t newsession     # Switch to it
```

**Method 2: Detach and create**
```bash
prefix + d                      # Detach from current session
tmux new -s newsession          # Create new named session from terminal
```

**Practical example:**
```bash
# Start with one session
tmux new -s frontend

# Create more sessions in background (from inside tmux)
prefix + :
new-session -d -s backend
switch-client -t backend

# Or detach and create from terminal
prefix + d
tmux new -s database
```

### Switching Between Sessions

| Key | Action |
|-----|--------|
| `prefix + Ctrl-j` | Open session switcher (fzf fuzzy finder) |
| `prefix + d` | Detach from current session |
| `prefix + $` | Rename current session |
| `prefix + s` | List and switch sessions (interactive) |
| `prefix + (` | Switch to previous session |
| `prefix + )` | Switch to next session |
| `prefix + L` | Switch to last used session |

**Workflow Tips:**
- Create named sessions for different projects: `tmux new -s frontend`, `tmux new -s backend`
- Use `prefix + Ctrl-j` for quick fuzzy search between sessions
- Detach with `prefix + d` and reattach later with `tmux attach -t sessionname`
- Keep sessions running in background - they persist even after closing terminal
- Always name your sessions with `-s name` for easy identification

---

## Window Management

### Creating and Managing Windows

| Key | Action |
|-----|--------|
| `prefix + c` | Create new window |
| `prefix + ,` | Rename current window |
| `prefix + &` | Kill current window |

### Switching Between Windows

**Sequential navigation:**
| Key | Action |
|-----|--------|
| `prefix + n` | Go to next window |
| `prefix + p` | Go to previous window |

**Direct navigation:**
| Key | Action |
|-----|--------|
| `prefix + 0-9` | Switch to window by number |
| `prefix + w` | List and switch windows (interactive) |
| `prefix + l` | *(default overridden - see Pane Resizing)* |

**Window Tips:**
- Windows are shown in the status bar at the bottom with numbers and names
- Example: `0:bash 1:nvim 2:logs*` (the `*` indicates your current window)
- Rename windows with `prefix + ,` to identify what's running in each

**Practical example:**
```bash
# Start tmux
tmux new -s myproject

# You're in window 0
prefix + c          # Create window 1
prefix + c          # Create window 2

prefix + ,          # Rename window 2 to "logs"
prefix + 0          # Jump back to window 0
prefix + n          # Go to next window (1)
prefix + w          # See list of all windows
```

---

## Pane Management

### Creating Panes

| Key | Action |
|-----|--------|
| `prefix + \|` | Split pane vertically (side-by-side) |
| `prefix + -` | Split pane horizontally (top-bottom) |

**Visual reminder:**
- `|` looks like a vertical line → creates side-by-side panes
- `-` looks like a horizontal line → creates stacked panes

**Note on tmux terminology:**
- The tmux `-h` flag means "horizontal split" but creates vertical/side-by-side panes
- The tmux `-v` flag means "vertical split" but creates horizontal/stacked panes
- The flag names refer to the split line direction, not the resulting layout
- This config uses intuitive symbols (`|` and `-`) that visually match what you get

### Navigating Panes

**Primary method (vim-style, no prefix needed):**
| Key | Action |
|-----|--------|
| `Ctrl+h` | Move to left pane |
| `Ctrl+j` | Move to pane below |
| `Ctrl+k` | Move to pane above |
| `Ctrl+l` | Move to right pane |

**Note:** `Ctrl+h/j/k/l` navigation works seamlessly between tmux panes and vim splits thanks to vim-tmux-navigator plugin. This is the fastest and most intuitive method since it matches vim movement keys.

**Important:** Don't confuse `Ctrl+j` (pane navigation, no prefix) with `prefix + Ctrl-j` (fzf session switcher).

**Alternative methods (using prefix):**
| Key | Action |
|-----|--------|
| `prefix + o` | Cycle through panes |
| `prefix + ;` | Toggle between last two panes |
| `prefix + q` | Show pane numbers (press number to jump) |

### Resizing Panes

| Key | Action |
|-----|--------|
| `prefix + h` | Resize pane left by 5 cells (repeatable) |
| `prefix + j` | Resize pane down by 5 cells (repeatable) |
| `prefix + k` | Resize pane up by 5 cells (repeatable) |
| `prefix + l` | Resize pane right by 5 cells (repeatable) |
| `prefix + m` | Toggle pane zoom (maximize/restore) |

**Note:** These are repeatable bindings - you can hold the key without re-pressing prefix.

### Pane Actions

| Key | Action |
|-----|--------|
| `prefix + x` | Kill current pane |
| `prefix + !` | Break pane into new window |
| `prefix + {` | Move pane left |
| `prefix + }` | Move pane right |
| `prefix + Space` | Cycle through pane layouts |

---

## Copy Mode (Vi-style)

| Key | Action |
|-----|--------|
| `prefix + [` | Enter copy mode |
| `v` | Begin selection (in copy mode) |
| `y` | Copy selection (in copy mode) |
| `q` | Exit copy mode |
| `h/j/k/l` | Navigate (vim-style) |
| `Ctrl+u` | Scroll up half page |
| `Ctrl+d` | Scroll down half page |
| `/` | Search forward |
| `?` | Search backward |

**Note:** Mouse support is enabled, so you can also scroll and select with the mouse.

---

## Configuration

| Key | Action |
|-----|--------|
| `prefix + r` | Reload tmux configuration |
| `prefix + ?` | List all keybindings |
| `prefix + :` | Enter command mode |

### Tmux Plugins

| Plugin | Description |
|--------|-------------|
| TPM | Tmux Plugin Manager |
| tmux-fzf | Fuzzy finder integration |
| vim-tmux-navigator | Seamless vim/tmux navigation |

**Configuration file:** `~/.tmux.conf`

---

## Most Frequent Commands

Quick reference for the most commonly used tmux commands:

| Action | Keybinding |
|--------|-----------|
| Switch session | `prefix + Ctrl-j` |
| Create window | `prefix + c` |
| Next window | `prefix + n` |
| Vertical split | `prefix + \|` |
| Horizontal split | `prefix + -` |
| Navigate panes | `Ctrl+h/j/k/l` |
| Resize panes | `prefix + h/j/k/l` |
| Zoom pane | `prefix + m` |
| Reload config | `prefix + r` |

---

## Quick Start Workflow

```bash
# Create a new named session
tmux new -s myproject

# Create windows for different tasks
prefix + c          # Create window for server
prefix + ,          # Rename it to "server"
prefix + c          # Create window for git
prefix + ,          # Rename it to "git"
prefix + 0          # Go back to first window

# Split into panes for multitasking
prefix + |          # Split vertically (editor | terminal)
prefix + -          # Split bottom pane horizontally

# Navigate with vim keys
Ctrl+h/j/k/l        # Move between panes

# Resize if needed
prefix + h/j/k/l    # Resize current pane

# Zoom to focus on one pane
prefix + m          # Maximize/restore pane

# Detach when done (session keeps running)
prefix + d

# Reattach later
tmux attach -t myproject

# Switch between multiple sessions
prefix + Ctrl-j     # Fuzzy search sessions
```
