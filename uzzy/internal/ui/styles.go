// Package ui implements the Terminal User Interface (TUI) for uzzy.
// This file defines the color scheme and text styles used throughout the UI.
package ui

import (
	"github.com/charmbracelet/lipgloss" // lipgloss: Terminal styling library
)

// ============================================================================
// Color Palette
// ============================================================================
// Define the application's color scheme as lipgloss.Color values.
// Colors are specified as hex strings for precise control.

var (
	// primaryColor: Main brand color used for titles and emphasis
	// Purple (#7C3AED) - a vibrant, modern purple
	primaryColor = lipgloss.Color("#7C3AED")

	// secondaryColor: Accent color for selected items and success states
	// Green (#10B981) - a calm, positive green
	secondaryColor = lipgloss.Color("#10B981")

	// mutedColor: De-emphasized text like subtitles and help text
	// Gray (#6B7280) - neutral, unobtrusive gray
	mutedColor = lipgloss.Color("#6B7280")

	// errorColor: Error messages and warnings
	// Red (#EF4444) - attention-grabbing red
	errorColor = lipgloss.Color("#EF4444")
)

// ============================================================================
// Text Styles
// ============================================================================
// Predefined lipgloss styles for consistent text formatting.
// Each style combines color, weight, and spacing properties.

var (
	// titleStyle: Main application title ("uzzy")
	// Bold purple text with bottom margin for visual separation
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(primaryColor).
			MarginBottom(1)

	// subtitleStyle: Secondary headings and instructions
	// Gray text with bottom margin, provides context without demanding attention
	subtitleStyle = lipgloss.NewStyle().
			Foreground(mutedColor).
			MarginBottom(1)

	// selectedStyle: Highlighted/selected items in lists
	// Bold green to indicate active selection
	selectedStyle = lipgloss.NewStyle().
			Foreground(secondaryColor).
			Bold(true)

	// normalStyle: Regular text items
	// White text for standard content
	normalStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFFFFF"))

	// dimStyle: De-emphasized content
	// Gray text for less important information
	dimStyle = lipgloss.NewStyle().
			Foreground(mutedColor)

	// errorStyle: Error messages
	// Bold red to draw attention to problems
	errorStyle = lipgloss.NewStyle().
			Foreground(errorColor).
			Bold(true)

	// helpStyle: Keyboard shortcut hints and help text
	// Gray text with top margin, positioned at bottom of views
	helpStyle = lipgloss.NewStyle().
			Foreground(mutedColor).
			MarginTop(1)

	// spinnerStyle: Loading spinner animation
	// Purple to match the primary brand color
	spinnerStyle = lipgloss.NewStyle().
			Foreground(primaryColor)
)
