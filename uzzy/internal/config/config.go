// Package config handles loading and saving application configuration.
// Configuration is stored in YAML format at ~/.config/uzzy/config.yaml
// and includes settings for project scanning, exclusion patterns, and tmux behavior.
package config

import (
	"os"           // os: File operations and environment access
	"path/filepath" // filepath: Cross-platform path manipulation

	"gopkg.in/yaml.v3" // yaml: YAML parsing and serialization
)

// Config holds all application configuration settings.
// It is loaded from ~/.config/uzzy/config.yaml on startup.
type Config struct {
	// ScanPaths: List of directories to search for git projects
	// Default: user's home directory
	ScanPaths []string `yaml:"scan_paths"`

	// ExcludePatterns: Directory names to skip during project scanning
	// Helps avoid searching in node_modules, build directories, etc.
	ExcludePatterns []string `yaml:"exclude_patterns"`

	// DefaultLayout: The layout to use when none is specified
	// Default: "nvim-claude"
	DefaultLayout string `yaml:"default_layout"`

	// LayoutsDir: Path to directory containing layout scripts
	// Default: ~/.config/uzzy/layouts
	LayoutsDir string `yaml:"layouts_dir"`

	// Tmux: Tmux-specific configuration settings
	Tmux TmuxConfig `yaml:"tmux"`
}

// TmuxConfig holds tmux-specific settings.
type TmuxConfig struct {
	// AttachCommand: The command used to attach to tmux sessions
	// Default: "tmux attach -t"
	AttachCommand string `yaml:"attach_command"`
}

// DefaultConfig creates a new Config with sensible default values.
// Returns a config that:
//   - Scans the user's home directory for projects
//   - Excludes common non-project directories (node_modules, .git, etc.)
//   - Uses nvim-claude as the default layout
//   - Stores layouts in ~/.config/uzzy/layouts
func DefaultConfig() *Config {
	// Get user's home directory for path defaults
	home, _ := os.UserHomeDir()

	return &Config{
		// By default, scan the entire home directory for git repos
		ScanPaths: []string{home},

		// Directories to skip when scanning for projects
		// These are commonly large or irrelevant directories
		ExcludePatterns: []string{
			"Library",       // macOS system library
			"Applications",  // macOS applications folder
			".Trash",        // macOS trash folder
			".cache",        // Cache directories
			".npm",          // npm cache
			".yarn",         // Yarn cache
			"node_modules",  // JavaScript dependencies
			".git",          // Git internals (we look for .git dirs, not inside them)
			".svn",          // Subversion directories
			"dist",          // Build output directories
			"build",         // Build output directories
			"target",        // Rust/Java build output
			"vendor",        // Go/PHP dependencies
			".venv",         // Python virtual environments
			"__pycache__",   // Python bytecode cache
		},

		// Default layout: neovim editor + claude-code assistant
		DefaultLayout: "nvim-claude",

		// Store layout scripts in the config directory
		LayoutsDir: filepath.Join(home, ".config", "uzzy", "layouts"),

		// Default tmux attach command
		Tmux: TmuxConfig{
			AttachCommand: "tmux attach -t",
		},
	}
}

// Load reads configuration from disk or returns defaults.
// It attempts to load from ~/.config/uzzy/config.yaml.
// If the file doesn't exist or is invalid, default values are used.
// Any values present in the file override the defaults.
func Load() *Config {
	// Start with default configuration
	cfg := DefaultConfig()

	// Build path to config file: ~/.config/uzzy/config.yaml
	home, _ := os.UserHomeDir()
	configPath := filepath.Join(home, ".config", "uzzy", "config.yaml")

	// Try to read the config file
	data, err := os.ReadFile(configPath)
	if err == nil {
		// File exists, unmarshal YAML into our config struct
		// Note: yaml.Unmarshal will only override fields present in the file
		yaml.Unmarshal(data, cfg)
	}
	// If file doesn't exist or can't be read, we just use defaults

	return cfg
}

// ConfigDir returns the path to the configuration directory.
// Returns: ~/.config/uzzy
// This is where config.yaml and the layouts/ directory are stored.
func ConfigDir() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".config", "uzzy")
}

// Save writes the current configuration to disk.
// Creates the config directory if it doesn't exist.
// Returns an error if the directory can't be created or file can't be written.
func (c *Config) Save() error {
	// Ensure the config directory exists
	// os.MkdirAll creates all parent directories as needed
	configDir := ConfigDir()
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return err
	}

	// Marshal the config struct to YAML format
	data, err := yaml.Marshal(c)
	if err != nil {
		return err
	}

	// Write the YAML data to config.yaml
	// File permissions: owner can read/write, others can read (0644)
	return os.WriteFile(filepath.Join(configDir, "config.yaml"), data, 0644)
}
