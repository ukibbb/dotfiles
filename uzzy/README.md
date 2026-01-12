# Uzzy

A Terminal User Interface (TUI) application for managing tmux sessions and quickly launching development environments for your git projects.

## What It Does

Uzzy simplifies the workflow of navigating between projects and initializing configured tmux development environments. With a single hotkey, you can:

1. **Discover Projects** - Automatically finds all git repositories across your configured directories
2. **Select Interactively** - Use a fuzzy-filterable list to pick your project
3. **Choose a Layout** - Select from predefined tmux layouts (or create your own)
4. **Launch Instantly** - Creates or attaches to a tmux session with your configured environment

## Installation

### Prerequisites

- **Go 1.24+** - For building from source
- **tmux** - Terminal multiplexer (required)
- **fd** (optional) - Faster alternative to `find` for project discovery

### Build from Source

```bash
# Clone the repository
git clone https://github.com/uki/uzzy.git
cd uzzy

# Build and install to ~/.local/bin
make install

# Or just build
make build
```

### Initialize Configuration

```bash
# Create default config and layout scripts
uzzy --init
```

This creates:
- `~/.config/uzzy/config.yaml` - Configuration file
- `~/.config/uzzy/layouts/` - Directory with default layout scripts

## Usage

### Basic Usage

```bash
# Launch the interactive TUI
uzzy

# Skip project selection (use specific path)
uzzy --path /path/to/project

# Skip layout selection (use specific layout)
uzzy --layout nvim-claude

# Skip both selections
uzzy --path /path/to/project --layout nvim-claude
```

### CLI Options

| Flag | Description |
|------|-------------|
| `--init` | Initialize default config and layouts |
| `--list-layouts` | List available layout scripts |
| `--path <path>` | Skip project selection, use this path |
| `--layout <name>` | Skip layout selection, use this layout |

### Keyboard Shortcuts (TUI)

| Key | Action |
|-----|--------|
| `j` / `Down` | Move down |
| `k` / `Up` | Move up |
| `/` | Start filtering |
| `Enter` | Confirm selection |
| `Esc` / `Ctrl+C` | Quit |

## Configuration

Configuration is stored in `~/.config/uzzy/config.yaml`:

```yaml
# Directories to scan for git projects
scan_paths:
  - /Users/username

# Directories to skip during scanning
exclude_patterns:
  - Library
  - Applications
  - .Trash
  - .cache
  - node_modules
  - .git
  - dist
  - build
  - vendor
  - .venv

# Default layout when none specified
default_layout: nvim-claude

# Directory containing layout scripts
layouts_dir: /Users/username/.config/uzzy/layouts

# Tmux settings
tmux:
  attach_command: tmux attach -t
```

## Layouts

Layouts are executable shell scripts that configure tmux sessions. They receive three arguments:

```bash
$1 = PROJECT_PATH    # Full path to the project directory
$2 = SESSION_NAME    # Slugified session name (e.g., "my-project")
$3 = PROJECT_NAME    # Directory name (e.g., "my-project")
```

### Built-in Layouts

#### nvim-claude (default)
Two windows: Neovim editor + Claude Code assistant
```
Window 1 (editor): nvim
Window 2 (claude): claude
```

#### nvim-only
Single window with Neovim
```
Window 1 (editor): nvim
```

#### split-dev
Side-by-side layout: editor (70%) | terminal (30%)
```
+------------------+--------+
|                  |        |
|      nvim        | shell  |
|                  |        |
+------------------+--------+
```

#### terminal
Plain terminal session, no editor launched

### Creating Custom Layouts

Create an executable script in `~/.config/uzzy/layouts/`:

```bash
#!/usr/bin/env bash
# Layout: my-custom-layout
# Description of what this layout does

set -euo pipefail

PROJECT_PATH="$1"
SESSION_NAME="$2"

# Create session with first window
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_PATH" -n main

# Add your customizations here...

# Example: Create a second window
tmux new-window -t "$SESSION_NAME" -n logs -c "$PROJECT_PATH"

# Select starting window
tmux select-window -t "$SESSION_NAME:main"
```

Make it executable:
```bash
chmod +x ~/.config/uzzy/layouts/my-custom-layout
```

## Hammerspoon Integration (macOS)

Add to your `~/.hammerspoon/init.lua` for a global hotkey:

```lua
-- Cmd+Shift+U to launch uzzy in Ghostty
hs.hotkey.bind({"cmd", "shift"}, "U", function()
    hs.execute("/usr/local/bin/ghostty -e uzzy", true)
end)
```

## Project Structure

```
uzzy/
├── cmd/uzzy/
│   └── main.go              # Application entry point
├── internal/
│   ├── config/
│   │   └── config.go        # Configuration management
│   ├── finder/
│   │   └── finder.go        # Git project discovery
│   ├── layout/
│   │   └── layout.go        # Tmux layout management
│   ├── tmux/
│   │   ├── session.go       # Tmux session operations
│   │   └── slugify.go       # Session name generation
│   └── ui/
│       ├── model.go         # BubbleTea TUI model
│       └── styles.go        # UI styling
├── build/                   # Build output
├── Makefile                 # Build automation
├── go.mod                   # Go module definition
└── README.md                # This file
```

## Dependencies

- [charmbracelet/bubbletea](https://github.com/charmbracelet/bubbletea) - TUI framework
- [charmbracelet/bubbles](https://github.com/charmbracelet/bubbles) - TUI components
- [charmbracelet/lipgloss](https://github.com/charmbracelet/lipgloss) - Terminal styling
- [gopkg.in/yaml.v3](https://github.com/go-yaml/yaml) - YAML parsing

## How It Works

```
User launches uzzy (or presses hotkey)
         │
         ▼
┌─────────────────────────┐
│  Check tmux installed   │
│  Load configuration     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Discover git projects  │
│  (using fd or find)     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  User selects project   │
│  (fuzzy filterable)     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  User selects layout    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Create tmux session    │
│  (run layout script)    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Attach to session      │
│  (exec replaces uzzy)   │
└─────────────────────────┘
```

## License

MIT
