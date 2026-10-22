#!/bin/sh
PATH="$HOME/.local/bin:$PATH"
# Przełącza tmux do okna z herdr; jeśli go nie ma, otwiera nowe okno "herdr".
target=$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' | awk '$2=="herdr"{print $1; exit}')
if [ -n "$target" ]; then
  tmux switch-client -t "$target" \; select-window -t "$target" \; select-pane -t "$target"
else
  tmux new-window -n herdr -c "#{pane_current_path}" herdr
fi
