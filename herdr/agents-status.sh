#!/bin/sh
# Licznik agentów herdr: ⚙ pracuje, ⏸ czeka na Ciebie, ✓ skończył, ○ bezczynny
# --tmux: format dla paska tmux, pusty gdy nie ma agentów
PATH="$HOME/.local/bin:$PATH"
json=$(herdr agent list 2>/dev/null) || exit 0
count() { printf '%s' "$json" | grep -o "\"agent_status\": *\"$1\"" | wc -l | tr -d ' '; }
out=""
add() { [ "$2" -gt 0 ] && out="${out:+$out  }$1 $2"; }
add "⚙" "$(count working)"
add "⏸" "$(count blocked)"
add "✓" "$(count done)"
add "○" "$(count idle)"
if [ "$1" = "--tmux" ]; then
  [ -n "$out" ] && printf 'herdr %s │ ' "$out"
else
  printf '%s\n' "${out:-· brak agentów}"
fi
exit 0
