#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Write to debug file for inspection
echo "$input" > ~/.claude/statusline-debug.json

# Get current directory
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$current_dir")

# Get model display name
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

# Get context info - current context usage (not cumulative)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# Calculate used tokens from percentage
used_tokens=$(echo "scale=0; $used_pct * $context_size / 100" | bc)

# Format tokens as K (thousands)
format_tokens() {
    local tokens=$1
    if [ "$tokens" -ge 1000 ]; then
        echo "scale=0; $tokens / 1000" | bc
    else
        echo "scale=0; $tokens / 1000" | bc
    fi
}

used_k=$(format_tokens "$used_tokens")
total_k=$(format_tokens "$context_size")

# Determine color based on usage percentage
if (( $(echo "$used_pct < 50" | bc -l) )); then
    usage_color=$'\033[32m'  # Green
elif (( $(echo "$used_pct < 80" | bc -l) )); then
    usage_color=$'\033[33m'  # Yellow
else
    usage_color=$'\033[31m'  # Red
fi

# Build progress bar [----------]
bar_width=10
filled=$(printf "%.0f" $(echo "scale=2; $used_pct * $bar_width / 100" | bc))
[ "$filled" -gt "$bar_width" ] && filled=$bar_width
[ "$filled" -lt 0 ] && filled=0
empty=$((bar_width - filled))

bar="["
if [ "$filled" -gt 0 ]; then
    bar+=$(printf "%${filled}s" | tr ' ' '=')
fi
if [ "$empty" -gt 0 ]; then
    bar+=$(printf "%${empty}s" | tr ' ' '-')
fi
bar+="]"

# Get git branch
branch=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Color codes (using $'...' syntax for proper escape interpretation)
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
BLUE=$'\033[34m'
GREEN=$'\033[32m'
DIM_GRAY=$'\033[90m'
RESET=$'\033[0m'

# Build status line with colors
output=""

# Model name (Magenta)
if [ -n "$model_name" ]; then
    output+="${MAGENTA}${model_name}${RESET}"
    output+=" ${DIM_GRAY}|${RESET} "
fi

# Progress bar (dynamic color)
output+="${usage_color}${bar}${RESET}"
output+=" ${DIM_GRAY}|${RESET} "

# Percentage (same color as progress bar)
output+="${usage_color}$(printf "%.0f" "$used_pct")%${RESET}"
output+=" ${DIM_GRAY}|${RESET} "

# Context tokens (Cyan)
output+="${CYAN}${used_k}K / ${total_k}K${RESET}"

# Git branch (Blue)
if [ -n "$branch" ]; then
    output+=" ${DIM_GRAY}|${RESET} "
    output+="${BLUE}${branch}${RESET}"
fi

# Project name (Green)
output+=" ${DIM_GRAY}|${RESET} "
output+="${GREEN}${dir_name}${RESET}"

# Print with color support
echo "${output}"
