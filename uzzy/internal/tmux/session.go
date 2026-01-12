// Package tmux handles all tmux session operations.
// It provides functionality to check, create, and attach to tmux sessions.
// This package is the core interface between uzzy and the tmux multiplexer.
package tmux

import (
	"os"           // os: Environment variables and process info
	"os/exec"      // exec: Running external tmux commands
	"path/filepath" // filepath: Path manipulation for project names
	"syscall"      // syscall: Low-level process replacement (exec)
)

// Manager handles tmux session operations.
// It wraps tmux commands to provide session management functionality.
type Manager struct {
	// attachCommand: The command used to attach to sessions
	// Stored for potential customization, though currently uses syscall.Exec directly
	attachCommand string
}

// NewManager creates a new tmux Manager.
// Parameters:
//   - attachCommand: The attach command (e.g., "tmux attach -t")
//
// Returns a Manager ready to perform tmux operations.
func NewManager(attachCommand string) *Manager {
	return &Manager{attachCommand: attachCommand}
}

// SessionExists checks if a tmux session with the given name already exists.
// Uses 'tmux has-session -t <name>' which returns exit code 0 if session exists.
// Parameters:
//   - sessionName: The name of the session to check
//
// Returns true if the session exists, false otherwise.
func (m *Manager) SessionExists(sessionName string) bool {
	// Run: tmux has-session -t <sessionName>
	// Exit code 0 = session exists
	// Exit code 1 = session does not exist
	cmd := exec.Command("tmux", "has-session", "-t", sessionName)
	return cmd.Run() == nil
}

// CreateSession runs a layout script to create a new tmux session.
// The layout script is responsible for creating windows, panes, and running commands.
// Parameters:
//   - layoutPath: Full path to the layout script to execute
//   - projectPath: Path to the project directory (passed to script as $1)
//   - sessionName: Name for the new tmux session (passed to script as $2)
//   - projectName: Human-readable project name (passed to script as $3)
//
// Returns an error if the layout script fails.
func (m *Manager) CreateSession(layoutPath, projectPath, sessionName, projectName string) error {
	// Execute the layout script with arguments:
	// $1 = projectPath (working directory for the session)
	// $2 = sessionName (tmux session name)
	// $3 = projectName (for display purposes)
	cmd := exec.Command(layoutPath, projectPath, sessionName, projectName)

	// Connect script's stdout/stderr to our stdout/stderr
	// This allows users to see any output or errors from the layout script
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Set the working directory to the project path
	// This ensures any relative paths in the script work correctly
	cmd.Dir = projectPath

	// Run the script and return any error
	return cmd.Run()
}

// AttachToSession attaches to an existing tmux session.
// IMPORTANT: This function replaces the current process (does not return on success).
// It uses syscall.Exec to replace the Go process with tmux, which is cleaner
// than spawning a child process and allows proper terminal handling.
//
// Parameters:
//   - sessionName: The name of the session to attach to
//
// Behavior:
//   - If already inside tmux ($TMUX is set): Uses 'tmux switch-client'
//   - If outside tmux: Uses 'tmux attach'
//
// Returns an error only if tmux is not found or exec fails.
func (m *Manager) AttachToSession(sessionName string) error {
	// Find the full path to the tmux binary
	// This is required by syscall.Exec
	tmuxPath, err := exec.LookPath("tmux")
	if err != nil {
		return err
	}

	// Check if we're already inside a tmux session
	// The TMUX environment variable is set when inside tmux
	if os.Getenv("TMUX") != "" {
		// Inside tmux: Use switch-client to change sessions without leaving tmux
		// This is more seamless than detaching and reattaching
		// syscall.Exec replaces current process with tmux switch-client
		return syscall.Exec(tmuxPath, []string{"tmux", "switch-client", "-t", sessionName}, os.Environ())
	}

	// Outside tmux: Use attach to connect to the session
	// syscall.Exec replaces current process with tmux attach
	// After this call, the Go program no longer exists - tmux takes over
	return syscall.Exec(tmuxPath, []string{"tmux", "attach", "-t", sessionName}, os.Environ())
}

// IsTmuxInstalled checks if tmux is available on the system.
// Looks for 'tmux' in the system PATH.
// Returns true if tmux is installed and accessible.
func IsTmuxInstalled() bool {
	// exec.LookPath searches for tmux in PATH
	_, err := exec.LookPath("tmux")
	return err == nil
}

// GetProjectName extracts the directory name from a full path.
// This is used for display purposes (showing project name in UI).
// Example: "/home/user/projects/myapp" -> "myapp"
func GetProjectName(projectPath string) string {
	// filepath.Base returns the last element of the path
	return filepath.Base(projectPath)
}
