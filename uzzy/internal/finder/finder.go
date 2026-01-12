// Package finder discovers git repositories across the filesystem.
// It scans configured directories for .git folders to identify project locations.
// Uses 'fd' command if available (faster), otherwise falls back to 'find'.
package finder

import (
	"os/exec"       // exec: Running external commands (fd, find)
	"path/filepath" // filepath: Cross-platform path manipulation
	"strings"       // strings: String manipulation
)

// Finder discovers git repositories in the filesystem.
// It wraps external tools (fd or find) to locate .git directories
// and returns the parent directories as project paths.
type Finder struct {
	// scanPaths: List of root directories to search for projects
	scanPaths []string
	// excludePatterns: Directory names to skip during search
	excludePatterns []string
}

// New creates a new Finder with the specified scan paths and exclusion patterns.
// Parameters:
//   - scanPaths: Directories to search for git projects (e.g., ["/home/user"])
//   - excludePatterns: Directory names to skip (e.g., ["node_modules", ".git"])
//
// Returns a configured Finder ready to search for projects.
func New(scanPaths, excludePatterns []string) *Finder {
	return &Finder{
		scanPaths:       scanPaths,
		excludePatterns: excludePatterns,
	}
}

// FindProjects returns a list of project directories (directories containing .git).
// It automatically selects the best available search tool:
//   - Uses 'fd' if installed (much faster, written in Rust)
//   - Falls back to 'find' (available on all Unix systems)
//
// Returns a slice of absolute paths to project directories.
func (f *Finder) FindProjects() ([]string, error) {
	// Check if 'fd' is available in PATH
	// fd is a faster alternative to find, written in Rust
	if _, err := exec.LookPath("fd"); err == nil {
		return f.findWithFd()
	}
	// Fall back to the standard 'find' command
	return f.findWithFind()
}

// findWithFd uses the 'fd' command to find git repositories.
// fd is significantly faster than find, especially on large directories.
// Command equivalent: fd --type d --hidden --absolute-path --max-depth 6 ^.git$ --exclude <patterns> <path>
func (f *Finder) findWithFd() ([]string, error) {
	// Collect all projects from all scan paths
	var allProjects []string

	// Search each configured scan path
	for _, scanPath := range f.scanPaths {
		// Build fd command arguments
		args := []string{
			"--type", "d",         // Search for directories only
			"--hidden",            // Include hidden directories (.git)
			"--absolute-path",     // Return full absolute paths
			"--max-depth", "6",    // Limit search depth to 6 levels
			"^.git$",              // Match directories named exactly ".git"
		}

		// Add exclusion patterns to avoid searching in unwanted directories
		for _, pattern := range f.excludePatterns {
			args = append(args, "--exclude", pattern)
		}

		// Add the directory to search as the last argument
		args = append(args, scanPath)

		// Execute the fd command
		cmd := exec.Command("fd", args...)
		output, err := cmd.Output()
		if err != nil {
			// If fd fails for this path, continue with other paths
			continue
		}

		// Process the output: split by newlines
		lines := strings.Split(strings.TrimSpace(string(output)), "\n")
		for _, line := range lines {
			// Skip empty lines
			if line == "" {
				continue
			}
			// fd returns .git directory paths, we want the parent (project) directory
			// e.g., /home/user/projects/myapp/.git -> /home/user/projects/myapp
			projectDir := filepath.Dir(line)
			allProjects = append(allProjects, projectDir)
		}
	}

	return allProjects, nil
}

// findWithFind uses the standard Unix 'find' command to locate git repositories.
// This is slower than fd but available on all Unix systems.
// Command equivalent: find <path> -type d -name .git -maxdepth 7 -not -path "*pattern*"
func (f *Finder) findWithFind() ([]string, error) {
	// Collect all projects from all scan paths
	var allProjects []string

	// Search each configured scan path
	for _, scanPath := range f.scanPaths {
		// Build find command arguments
		// Note: maxdepth is 7 (one more than fd) because find counts from the root
		args := []string{scanPath, "-type", "d", "-name", ".git", "-maxdepth", "7"}

		// Add exclusion patterns using -not -path
		// Each pattern becomes: -not -path "*pattern*"
		for _, pattern := range f.excludePatterns {
			args = append(args, "-not", "-path", "*"+pattern+"*")
		}

		// Execute the find command
		cmd := exec.Command("find", args...)
		output, err := cmd.Output()
		if err != nil {
			// If find fails for this path, continue with other paths
			continue
		}

		// Process the output: split by newlines
		lines := strings.Split(strings.TrimSpace(string(output)), "\n")
		for _, line := range lines {
			// Skip empty lines
			if line == "" {
				continue
			}
			// find returns .git directory paths, we want the parent (project) directory
			// e.g., /home/user/projects/myapp/.git -> /home/user/projects/myapp
			projectDir := filepath.Dir(line)
			allProjects = append(allProjects, projectDir)
		}
	}

	return allProjects, nil
}
