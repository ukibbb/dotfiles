// Package tmux handles all tmux session operations.
// This file contains utilities for converting paths to valid tmux session names.
package tmux

import (
	"path/filepath" // filepath: Path manipulation
	"regexp"        // regexp: Regular expression pattern matching
	"strings"       // strings: String manipulation
)

// Slugify converts a project path to a valid tmux session name.
// Tmux session names have restrictions - they must be alphanumeric with hyphens.
// This function transforms any path into a compliant session name.
//
// Rules applied:
//  1. Extract directory name from path
//  2. Convert to lowercase
//  3. Replace dots with hyphens
//  4. Replace all non-alphanumeric characters with hyphens
//  5. Collapse multiple consecutive hyphens into one
//  6. Remove leading and trailing hyphens
//  7. Return "session" if result is empty
//
// Examples:
//   - "/home/user/MyProject" -> "myproject"
//   - "/home/user/my.cool.project" -> "my-cool-project"
//   - "/home/user/My Project (v2)" -> "my-project-v2"
//
// Parameters:
//   - projectPath: Full path to the project directory
//
// Returns a valid tmux session name.
func Slugify(projectPath string) string {
	// Step 1: Extract just the directory name from the full path
	// e.g., "/home/user/projects/my-app" -> "my-app"
	dirName := filepath.Base(projectPath)

	// Step 2: Convert to lowercase for consistency
	// Tmux session names are case-insensitive, so we normalize to lowercase
	slug := strings.ToLower(dirName)

	// Step 3: Replace dots with hyphens
	// Dots are commonly used in project names (e.g., "my.project")
	// but we convert them to hyphens for cleaner session names
	slug = strings.ReplaceAll(slug, ".", "-")

	// Step 4: Replace any remaining non-alphanumeric characters with hyphens
	// This catches spaces, underscores, parentheses, etc.
	// Only a-z, 0-9, and - are allowed
	re := regexp.MustCompile(`[^a-z0-9-]`)
	slug = re.ReplaceAllString(slug, "-")

	// Step 5: Collapse multiple consecutive hyphens into a single hyphen
	// This cleans up cases like "my--project" -> "my-project"
	re = regexp.MustCompile(`-+`)
	slug = re.ReplaceAllString(slug, "-")

	// Step 6: Remove leading and trailing hyphens
	// Clean up edges: "-my-project-" -> "my-project"
	slug = strings.Trim(slug, "-")

	// Step 7: Handle empty result
	// If the directory name was all special characters, use a default
	if slug == "" {
		slug = "session"
	}

	return slug
}
