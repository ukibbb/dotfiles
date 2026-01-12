// Package layout manages tmux layout scripts.
// Layouts are executable shell scripts that create tmux sessions
// with predefined window and pane configurations.
// Built-in layouts include: nvim-claude, nvim-only, split-dev, terminal.
package layout

import (
	"fmt"          // fmt: Formatted I/O and error messages
	"os"           // os: File operations and permissions
	"path/filepath" // filepath: Cross-platform path manipulation
)

// Layout represents a tmux layout script.
// Each layout is an executable shell script that sets up
// a specific tmux session configuration.
type Layout struct {
	// Name: The layout name (filename without path)
	Name string
	// Path: Full absolute path to the layout script
	Path string
}

// Manager handles layout discovery and initialization.
// It manages the layouts directory and provides access to layout scripts.
type Manager struct {
	// layoutsDir: Path to the directory containing layout scripts
	// Default: ~/.config/uzzy/layouts
	layoutsDir string
}

// NewManager creates a new layout Manager.
// Parameters:
//   - layoutsDir: Path to the directory containing layout scripts
//
// Returns a Manager ready to list and retrieve layouts.
func NewManager(layoutsDir string) *Manager {
	return &Manager{layoutsDir: layoutsDir}
}

// ListLayouts returns all available layout scripts in the layouts directory.
// A valid layout is a file with executable permissions.
// Directories are skipped.
// Returns an empty slice if the layouts directory doesn't exist.
func (m *Manager) ListLayouts() ([]Layout, error) {
	var layouts []Layout

	// Read all entries in the layouts directory
	entries, err := os.ReadDir(m.layoutsDir)
	if err != nil {
		// If directory doesn't exist, return empty list (not an error)
		if os.IsNotExist(err) {
			return layouts, nil
		}
		return nil, err
	}

	// Iterate through all entries in the directory
	for _, entry := range entries {
		// Skip directories - layouts must be files
		if entry.IsDir() {
			continue
		}

		// Get file info to check permissions
		info, err := entry.Info()
		if err != nil {
			// Skip files we can't read info for
			continue
		}

		// Check if the file has any executable permission (owner, group, or other)
		// 0111 is the bitmask for executable bits: --x--x--x
		if info.Mode()&0111 != 0 {
			// This file is executable, add it as a layout
			layouts = append(layouts, Layout{
				Name: entry.Name(),                               // Just the filename
				Path: filepath.Join(m.layoutsDir, entry.Name()), // Full path
			})
		}
	}

	return layouts, nil
}

// GetLayout returns a specific layout by name.
// It validates that the layout exists and is executable.
// Parameters:
//   - name: The layout name (filename in the layouts directory)
//
// Returns the Layout or an error if not found/invalid.
func (m *Manager) GetLayout(name string) (*Layout, error) {
	// Build the full path to the layout script
	path := filepath.Join(m.layoutsDir, name)

	// Check if the file exists and get its info
	info, err := os.Stat(path)
	if err != nil {
		// File doesn't exist
		return nil, fmt.Errorf("layout '%s' not found", name)
	}

	// Layouts must be files, not directories
	if info.IsDir() {
		return nil, fmt.Errorf("'%s' is a directory, not a layout script", name)
	}

	// Layouts must be executable
	if info.Mode()&0111 == 0 {
		return nil, fmt.Errorf("layout '%s' is not executable", name)
	}

	// Return the validated layout
	return &Layout{
		Name: name,
		Path: path,
	}, nil
}

// InitializeDefaults creates the layouts directory and default layout scripts.
// This is called when the user runs 'uzzy --init'.
// It creates four built-in layouts:
//   - nvim-claude: Neovim editor + Claude Code assistant windows
//   - nvim-only: Single window with Neovim
//   - split-dev: Editor (70%) + terminal (30%) side by side
//   - terminal: Plain terminal session
//
// Existing layouts are not overwritten.
func (m *Manager) InitializeDefaults() error {
	// Create the layouts directory if it doesn't exist
	// 0755 = rwxr-xr-x (owner can write, all can read/execute)
	if err := os.MkdirAll(m.layoutsDir, 0755); err != nil {
		return err
	}

	// Map of layout names to their script content
	defaultLayouts := map[string]string{
		"nvim-claude": nvimClaudeLayout, // Two windows: nvim + claude
		"nvim-only":   nvimOnlyLayout,   // Single window: nvim
		"split-dev":   splitDevLayout,   // Side-by-side: nvim | terminal
		"terminal":    terminalLayout,   // Plain terminal
	}

	// Create each default layout script
	for name, content := range defaultLayouts {
		path := filepath.Join(m.layoutsDir, name)

		// Only create if it doesn't already exist (don't overwrite user customizations)
		if _, err := os.Stat(path); os.IsNotExist(err) {
			// Write the script with executable permissions (0755)
			if err := os.WriteFile(path, []byte(content), 0755); err != nil {
				return err
			}
		}
	}

	return nil
}

// ============================================================================
// Built-in Layout Scripts
// ============================================================================
// Each layout is a bash script that receives three arguments:
//   $1 = PROJECT_PATH: Full path to the project directory
//   $2 = SESSION_NAME: The tmux session name (slugified project name)
//   $3 = PROJECT_NAME: The human-readable project name (not always used)
// ============================================================================

// nvimClaudeLayout creates a tmux session with two windows:
//   - Window 1 "editor": Opens Neovim in the project directory
//   - Window 2 "claude": Opens Claude Code CLI for AI assistance
//
// This is the default layout, ideal for AI-assisted development.
const nvimClaudeLayout = `#!/usr/bin/env bash
# Layout: nvim-claude
# Creates a tmux session with two windows: neovim and claude-code

set -euo pipefail

PROJECT_PATH="$1"
SESSION_NAME="$2"

# Create session with first window named "editor"
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_PATH" -n editor

# Send nvim command to editor window
tmux send-keys -t "$SESSION_NAME:editor" 'nvim' C-m

# Create second window for claude-code
tmux new-window -t "$SESSION_NAME" -n claude -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:claude" 'claude' C-m

# Select the editor window (user starts there)
tmux select-window -t "$SESSION_NAME:editor"
`

// nvimOnlyLayout creates a simple tmux session with a single Neovim window.
// Minimal setup for focused coding without additional tools.
const nvimOnlyLayout = `#!/usr/bin/env bash
# Layout: nvim-only
# Single window with neovim

set -euo pipefail

PROJECT_PATH="$1"
SESSION_NAME="$2"

tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_PATH" -n editor
tmux send-keys -t "$SESSION_NAME:editor" 'nvim' C-m
`

// splitDevLayout creates a tmux session with a split window:
//   - Left pane (70%): Neovim editor
//   - Right pane (30%): Terminal for running commands
//
// Great for development workflows that need both editing and shell access.
const splitDevLayout = `#!/usr/bin/env bash
# Layout: split-dev
# Editor on left (70%), terminal on right (30%)

set -euo pipefail

PROJECT_PATH="$1"
SESSION_NAME="$2"

tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_PATH" -n dev
tmux send-keys -t "$SESSION_NAME:dev" 'nvim' C-m

# Split vertically (side-by-side), right pane gets 30%
tmux split-window -h -t "$SESSION_NAME:dev" -c "$PROJECT_PATH" -p 30

# Focus back on left pane (nvim)
tmux select-pane -t "$SESSION_NAME:dev.0"
`

// terminalLayout creates a plain tmux session with just a terminal.
// No editor is launched - useful for projects that don't need one
// or when you want to start fresh.
const terminalLayout = `#!/usr/bin/env bash
# Layout: terminal
# Plain terminal, no editor

set -euo pipefail

PROJECT_PATH="$1"
SESSION_NAME="$2"

tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_PATH"
`
