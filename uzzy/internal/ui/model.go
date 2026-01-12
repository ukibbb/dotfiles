// Package ui implements the Terminal User Interface (TUI) for uzzy.
// It uses the BubbleTea framework (Elm architecture) to provide an interactive
// project and layout selector with fuzzy filtering capabilities.
package ui

import (
	"strings" // strings: String manipulation for path display

	"github.com/charmbracelet/bubbles/list"      // list: Interactive list component
	"github.com/charmbracelet/bubbles/spinner"   // spinner: Loading animation
	"github.com/charmbracelet/bubbles/textinput" // textinput: Text input component
	tea "github.com/charmbracelet/bubbletea"     // bubbletea: TUI framework (Elm architecture)
	"github.com/charmbracelet/lipgloss"          // lipgloss: Terminal styling
	"github.com/uki/uzzy/internal/config"        // config: Application configuration
	"github.com/uki/uzzy/internal/finder"        // finder: Project discovery
	"github.com/uki/uzzy/internal/layout"        // layout: Tmux layout management
	"github.com/uki/uzzy/internal/tmux"          // tmux: Session name utilities
)

// ============================================================================
// Step: Application State Machine
// ============================================================================

// Step represents the current stage in the UI flow.
// The application progresses through these steps sequentially.
type Step int

const (
	// StepLoading: Initial state, loading projects or layouts
	// Shows a spinner while data is being fetched
	StepLoading Step = iota

	// StepSelectProject: User is selecting a project from the list
	// Projects are displayed with fuzzy filter support
	StepSelectProject

	// StepSelectLayout: User is selecting a tmux layout
	// Shown after project selection
	StepSelectLayout

	// StepDone: Selection complete, ready to create/attach session
	// Application will exit after this step
	StepDone
)

// ============================================================================
// Item: List Item Implementation
// ============================================================================

// Item represents a selectable item in a list.
// Implements the list.Item interface for BubbleTea lists.
type Item struct {
	// title: Display text shown in the list
	title string
	// desc: Additional data (e.g., full path for projects)
	desc string
}

// Title returns the display title for the list item.
// This is what users see in the list.
func (i Item) Title() string { return i.title }

// Description returns the description (used for storing full path).
// Not displayed by default when ShowDescription is false.
func (i Item) Description() string { return i.desc }

// FilterValue returns the string used for fuzzy filtering.
// Users can type to filter items based on this value.
func (i Item) FilterValue() string { return i.title }

// ============================================================================
// Messages: BubbleTea Message Types
// ============================================================================
// Messages are the communication mechanism in BubbleTea.
// Components send messages to trigger state updates.

// projectsLoadedMsg is sent when project discovery completes.
// Contains the list of discovered project paths.
type projectsLoadedMsg struct {
	projects []string
}

// layoutsLoadedMsg is sent when layout loading completes.
// Contains the list of available tmux layouts.
type layoutsLoadedMsg struct {
	layouts []layout.Layout
}

// errMsg is sent when an error occurs during async operations.
// Will cause the application to display an error and exit.
type errMsg struct {
	err error
}

// ============================================================================
// Model: Main TUI State
// ============================================================================

// Model is the main BubbleTea model holding all application state.
// It implements tea.Model interface (Init, Update, View).
type Model struct {
	// cfg: Application configuration (scan paths, layouts dir, etc.)
	cfg *config.Config

	// step: Current step in the UI flow (loading, select project, select layout, done)
	step Step

	// projectList: BubbleTea list component for project selection
	projectList list.Model

	// layoutList: BubbleTea list component for layout selection
	layoutList list.Model

	// spinner: Loading spinner shown during async operations
	spinner spinner.Model

	// textInput: Text input component (for potential future use)
	textInput textinput.Model

	// selectedPath: The project path chosen by the user
	selectedPath string

	// selectedLayout: The layout name chosen by the user
	selectedLayout string

	// projects: List of discovered project paths
	projects []string

	// layouts: List of available tmux layouts
	layouts []layout.Layout

	// err: Any error that occurred during operation
	err error

	// quitting: True if user is exiting without selection (Ctrl+C/Esc)
	quitting bool

	// width, height: Terminal dimensions for responsive layout
	width  int
	height int
}

// NewModel creates a new Model with initial configuration.
// Parameters:
//   - cfg: Application configuration
//   - preselectedPath: Optional path to skip project selection (from --path flag)
//   - preselectedLayout: Optional layout to skip layout selection (from --layout flag)
//
// Returns a configured Model ready for BubbleTea.
func NewModel(cfg *config.Config, preselectedPath, preselectedLayout string) Model {
	// Initialize the loading spinner
	s := spinner.New()
	s.Spinner = spinner.Dot // Use dot animation style
	s.Style = spinnerStyle  // Apply purple color from styles.go

	// Initialize text input (for future filter functionality)
	ti := textinput.New()
	ti.Placeholder = "Search..."
	ti.Focus() // Focus on text input by default

	// Create the initial model
	m := Model{
		cfg:            cfg,
		step:           StepLoading,      // Start with loading
		spinner:        s,
		textInput:      ti,
		selectedPath:   preselectedPath,  // May be empty
		selectedLayout: preselectedLayout, // May be empty
		width:          80,               // Default terminal width
		height:         24,               // Default terminal height
	}

	// Handle preselection scenarios
	// If both path and layout are provided, skip directly to done
	if preselectedPath != "" && preselectedLayout != "" {
		m.step = StepDone
	} else if preselectedPath != "" {
		// If only path is provided, skip to layout loading
		m.step = StepLoading // Will load layouts instead of projects
	}

	return m
}

// ============================================================================
// BubbleTea Interface Implementation
// ============================================================================

// Init is called once when the program starts.
// It returns initial commands to execute (loading data, starting spinner).
func (m Model) Init() tea.Cmd {
	// If we already have selections, just quit immediately
	if m.step == StepDone {
		return tea.Quit
	}

	// If project was preselected, skip to loading layouts
	if m.selectedPath != "" {
		// Start spinner animation and load layouts concurrently
		return tea.Batch(m.spinner.Tick, m.loadLayouts())
	}

	// Default: Start spinner and load projects
	return tea.Batch(m.spinner.Tick, m.loadProjects())
}

// Update handles all incoming messages and updates the model.
// This is the core of the Elm architecture - all state changes happen here.
// Parameters:
//   - msg: The message to process (key press, window resize, async result, etc.)
//
// Returns the updated model and any commands to execute.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {

	// Handle terminal resize events
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	// Handle key presses (global handlers)
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "esc":
			// User wants to quit without making a selection
			m.quitting = true
			return m, tea.Quit
		}

	// Handle spinner animation ticks
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	// Handle project loading completion
	case projectsLoadedMsg:
		m.projects = msg.projects
		m.projectList = m.createProjectList(msg.projects)
		m.step = StepSelectProject // Move to project selection step
		return m, nil

	// Handle layout loading completion
	case layoutsLoadedMsg:
		m.layouts = msg.layouts
		m.layoutList = m.createLayoutList(msg.layouts)
		m.step = StepSelectLayout // Move to layout selection step
		return m, nil

	// Handle errors from async operations
	case errMsg:
		m.err = msg.err
		return m, tea.Quit
	}

	// Handle step-specific updates (delegate to helper functions)
	switch m.step {
	case StepSelectProject:
		return m.updateProjectPicker(msg)
	case StepSelectLayout:
		return m.updateLayoutPicker(msg)
	}

	return m, nil
}

// View renders the current UI state to a string.
// BubbleTea calls this after every Update to refresh the display.
// Returns a string that will be printed to the terminal.
func (m Model) View() string {
	// If quitting, return empty string (clean exit)
	if m.quitting {
		return ""
	}

	// If there's an error, display it
	if m.err != nil {
		return errorStyle.Render("Error: " + m.err.Error())
	}

	// Render based on current step
	switch m.step {
	case StepLoading:
		return m.loadingView()
	case StepSelectProject:
		return m.projectPickerView()
	case StepSelectLayout:
		return m.layoutPickerView()
	case StepDone:
		return "" // No view needed, we're exiting
	}

	return ""
}

// ============================================================================
// View Helpers: Render Different Steps
// ============================================================================

// loadingView renders the loading spinner view.
// Shown while projects or layouts are being discovered.
func (m Model) loadingView() string {
	return lipgloss.JoinVertical(lipgloss.Left,
		titleStyle.Render("uzzy"),           // Application title
		m.spinner.View()+" Loading...",      // Animated spinner + text
	)
}

// ============================================================================
// Project Picker Step
// ============================================================================

// updateProjectPicker handles input during project selection.
// Processes Enter key to confirm selection and delegates other keys to the list.
func (m *Model) updateProjectPicker(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			// User pressed Enter, confirm selection
			if item, ok := m.projectList.SelectedItem().(Item); ok {
				m.selectedPath = item.desc // desc contains the full path
				m.step = StepLoading       // Move to loading layouts
				return m, m.loadLayouts()  // Start loading layouts
			}
		}
	}

	// Delegate all other input to the list component
	// This handles arrow keys, filtering, etc.
	var cmd tea.Cmd
	m.projectList, cmd = m.projectList.Update(msg)
	return m, cmd
}

// projectPickerView renders the project selection UI.
// Shows a title, subtitle, and the filterable project list.
func (m Model) projectPickerView() string {
	return lipgloss.JoinVertical(lipgloss.Left,
		titleStyle.Render("uzzy"),             // Application title
		subtitleStyle.Render("Select a project"), // Instruction
		m.projectList.View(),                  // Interactive list
	)
}

// ============================================================================
// Layout Picker Step
// ============================================================================

// updateLayoutPicker handles input during layout selection.
// Processes Enter key to confirm and complete the flow.
func (m *Model) updateLayoutPicker(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			// User pressed Enter, confirm layout selection
			if item, ok := m.layoutList.SelectedItem().(Item); ok {
				m.selectedLayout = item.title // title contains the layout name
				m.step = StepDone             // All selections complete
				return m, tea.Quit            // Exit the TUI
			}
		}
	}

	// Delegate all other input to the list component
	var cmd tea.Cmd
	m.layoutList, cmd = m.layoutList.Update(msg)
	return m, cmd
}

// layoutPickerView renders the layout selection UI.
// Shows the selected project name and the layout list.
func (m Model) layoutPickerView() string {
	// Get the project name for display
	projectName := tmux.GetProjectName(m.selectedPath)
	return lipgloss.JoinVertical(lipgloss.Left,
		titleStyle.Render("uzzy"),                     // Application title
		subtitleStyle.Render("Project: "+projectName), // Show selected project
		subtitleStyle.Render("Select a layout"),       // Instruction
		m.layoutList.View(),                           // Interactive list
	)
}

// ============================================================================
// Async Data Loading Commands
// ============================================================================

// loadProjects returns a command that discovers git projects asynchronously.
// Uses the finder package to scan configured directories.
func (m Model) loadProjects() tea.Cmd {
	return func() tea.Msg {
		// Create a finder with configured scan paths and exclusions
		f := finder.New(m.cfg.ScanPaths, m.cfg.ExcludePatterns)

		// Find all git repositories
		projects, err := f.FindProjects()
		if err != nil {
			return errMsg{err: err}
		}

		// Return the results as a message
		return projectsLoadedMsg{projects: projects}
	}
}

// loadLayouts returns a command that loads available layouts asynchronously.
// Uses the layout package to scan the layouts directory.
func (m Model) loadLayouts() tea.Cmd {
	return func() tea.Msg {
		// Create a layout manager for the configured layouts directory
		lm := layout.NewManager(m.cfg.LayoutsDir)

		// List all executable layout scripts
		layouts, err := lm.ListLayouts()
		if err != nil {
			return errMsg{err: err}
		}

		// Return the results as a message
		return layoutsLoadedMsg{layouts: layouts}
	}
}

// ============================================================================
// List Creation Helpers
// ============================================================================

// createProjectList creates a BubbleTea list from project paths.
// Transforms paths into list items with shortened display names.
func (m Model) createProjectList(projects []string) list.Model {
	// Convert paths to list items
	items := make([]list.Item, len(projects))
	for i, p := range projects {
		// Replace home directory with ~ for cleaner display
		// e.g., "/Users/john/projects/app" -> "~/projects/app"
		home := m.cfg.ScanPaths[0]
		displayPath := strings.Replace(p, home, "~", 1)
		items[i] = Item{
			title: displayPath, // Shown in the list
			desc:  p,           // Full path stored for later use
		}
	}

	// Configure the list delegate (item renderer)
	delegate := list.NewDefaultDelegate()
	delegate.ShowDescription = false // Don't show full paths in list

	// Create and configure the list
	l := list.New(items, delegate, m.width, m.height-6)
	l.Title = ""                // We render our own title
	l.SetShowTitle(false)       // Hide built-in title
	l.SetShowStatusBar(true)    // Show item count
	l.SetFilteringEnabled(true) // Enable fuzzy filtering
	l.SetShowHelp(true)         // Show keyboard shortcuts

	return l
}

// createLayoutList creates a BubbleTea list from available layouts.
// Simpler than project list since layouts are just names.
func (m Model) createLayoutList(layouts []layout.Layout) list.Model {
	// Convert layouts to list items
	items := make([]list.Item, len(layouts))
	for i, l := range layouts {
		items[i] = Item{
			title: l.Name, // Layout name
			desc:  l.Path, // Full path (not displayed)
		}
	}

	// Configure the list delegate
	delegate := list.NewDefaultDelegate()
	delegate.ShowDescription = false

	// Create and configure the list
	l := list.New(items, delegate, m.width, m.height-8)
	l.Title = ""
	l.SetShowTitle(false)
	l.SetShowStatusBar(false)   // Fewer items, no need for count
	l.SetFilteringEnabled(true) // Still allow filtering
	l.SetShowHelp(true)

	return l
}

// ============================================================================
// Public Accessors
// ============================================================================
// These methods are used by main.go to retrieve selection results.

// ShouldAttach returns true if the user made valid selections
// and a tmux session should be created/attached.
func (m Model) ShouldAttach() bool {
	return m.step == StepDone && m.selectedPath != "" && m.selectedLayout != ""
}

// SelectedPath returns the project path chosen by the user.
func (m Model) SelectedPath() string {
	return m.selectedPath
}

// SelectedLayout returns the layout name chosen by the user.
func (m Model) SelectedLayout() string {
	return m.selectedLayout
}

// Quitting returns true if the user exited without making selections.
// (Pressed Ctrl+C or Escape)
func (m Model) Quitting() bool {
	return m.quitting
}
