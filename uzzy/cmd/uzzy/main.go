// Package main is the entry point for the uzzy application.
// Uzzy is a Terminal User Interface (TUI) for managing tmux sessions
// and quickly launching development environments for git projects.
package main

import (
	"flag"    // flag: Command-line argument parsing
	"fmt"     // fmt: Formatted I/O operations
	"os"      // os: Operating system functionality (exit codes, stderr)

	tea "github.com/charmbracelet/bubbletea" // bubbletea: Elm-inspired TUI framework for Go
	"github.com/uki/uzzy/internal/config"    // config: Configuration loading and management
	"github.com/uki/uzzy/internal/layout"    // layout: Tmux layout script management
	"github.com/uki/uzzy/internal/tmux"      // tmux: Tmux session operations
	"github.com/uki/uzzy/internal/ui"        // ui: BubbleTea TUI model and views
)

// main is the application entry point.
// It handles CLI flags, initializes configuration, and runs the TUI.
// Flow: Parse flags -> Check tmux -> Load config -> Run TUI -> Create/attach session
func main() {
	// ========================================================================
	// CLI Flag Definitions
	// ========================================================================
	// --path: Bypass project selection by providing a path directly
	projectPath := flag.String("path", "", "Skip project selection, use this path")
	// --layout: Bypass layout selection by providing a layout name directly
	layoutName := flag.String("layout", "", "Skip layout selection, use this layout")
	// --init: Initialize default config file and layout scripts
	initCmd := flag.Bool("init", false, "Initialize default config and layouts")
	// --list-layouts: Display all available layout scripts
	listLayouts := flag.Bool("list-layouts", false, "List available layouts")
	// Parse all command-line flags
	flag.Parse()

	// ========================================================================
	// Prerequisite Check: Ensure tmux is installed
	// ========================================================================
	// Without tmux, the application cannot function
	if !tmux.IsTmuxInstalled() {
		fmt.Fprintln(os.Stderr, "Error: tmux is not installed")
		os.Exit(1) // Exit code 1 indicates an error
	}

	// ========================================================================
	// Load Configuration
	// ========================================================================
	// Load config from ~/.config/uzzy/config.yaml (or use defaults if not found)
	cfg := config.Load()

	// ========================================================================
	// Handle --init Command
	// ========================================================================
	// Creates default configuration and layout scripts in ~/.config/uzzy/
	if *initCmd {
		if err := initialize(cfg); err != nil {
			fmt.Fprintf(os.Stderr, "Error initializing: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Initialized uzzy configuration at ~/.config/uzzy/")
		return // Exit after initialization
	}

	// ========================================================================
	// Handle --list-layouts Command
	// ========================================================================
	// Display all available tmux layout scripts
	if *listLayouts {
		// Create a layout manager to scan the layouts directory
		lm := layout.NewManager(cfg.LayoutsDir)
		layouts, err := lm.ListLayouts()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error listing layouts: %v\n", err)
			os.Exit(1)
		}
		// If no layouts found, suggest running --init
		if len(layouts) == 0 {
			fmt.Println("No layouts found. Run 'uzzy --init' to create default layouts.")
			return
		}
		// Print each available layout name
		fmt.Println("Available layouts:")
		for _, l := range layouts {
			fmt.Printf("  %s\n", l.Name)
		}
		return // Exit after listing
	}

	// ========================================================================
	// Create and Run the TUI Application
	// ========================================================================
	// Initialize the BubbleTea model with config and any preselected values
	model := ui.NewModel(cfg, *projectPath, *layoutName)
	// Create a new BubbleTea program with alternate screen mode (fullscreen TUI)
	p := tea.NewProgram(model, tea.WithAltScreen())

	// Run the TUI and wait for it to complete
	finalModel, err := p.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Type assert the final model back to our Model type
	m := finalModel.(ui.Model)

	// ========================================================================
	// Handle TUI Exit
	// ========================================================================
	// If user pressed Ctrl+C or Escape, exit without creating a session
	if m.Quitting() {
		return
	}

	// ========================================================================
	// Create/Attach to Tmux Session
	// ========================================================================
	// If user made valid selections, launch the tmux session
	if m.ShouldAttach() {
		if err := launchSession(cfg, m.SelectedPath(), m.SelectedLayout()); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	}
}

// initialize creates the default configuration and layout scripts.
// It saves the current config to disk and creates default tmux layouts.
// Returns an error if file operations fail.
func initialize(cfg *config.Config) error {
	// Save the default configuration to ~/.config/uzzy/config.yaml
	if err := cfg.Save(); err != nil {
		return err
	}

	// Create the layouts directory and populate with default layout scripts
	lm := layout.NewManager(cfg.LayoutsDir)
	return lm.InitializeDefaults()
}

// launchSession creates a new tmux session (if needed) and attaches to it.
// Parameters:
//   - cfg: Application configuration
//   - projectPath: Full path to the project directory
//   - layoutName: Name of the layout script to use
//
// Flow:
//  1. Get the layout script by name
//  2. Generate a valid tmux session name from the project path
//  3. Create a new session if one doesn't exist (using the layout script)
//  4. Attach to the session (replaces current process)
func launchSession(cfg *config.Config, projectPath, layoutName string) error {
	// Create managers for layouts and tmux operations
	lm := layout.NewManager(cfg.LayoutsDir)
	tm := tmux.NewManager(cfg.Tmux.AttachCommand)

	// Get the layout script by name
	l, err := lm.GetLayout(layoutName)
	if err != nil {
		return err
	}

	// Generate a valid tmux session name (lowercase, alphanumeric, hyphens)
	sessionName := tmux.Slugify(projectPath)
	// Get just the directory name for display purposes
	projectName := tmux.GetProjectName(projectPath)

	// Check if a session with this name already exists
	if !tm.SessionExists(sessionName) {
		// Create a new session by running the layout script
		// The script receives: projectPath, sessionName, projectName
		if err := tm.CreateSession(l.Path, projectPath, sessionName, projectName); err != nil {
			return fmt.Errorf("failed to create session: %w", err)
		}
	}

	// Attach to the session (this replaces the current process via syscall.Exec)
	// If already inside tmux, it uses switch-client instead
	return tm.AttachToSession(sessionName)
}
