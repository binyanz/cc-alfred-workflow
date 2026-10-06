#!/bin/bash -l

# dynamic-profile-clear.sh: Remove all dynamically created iTerm2 profiles
# - dev-* profiles: keeps only those matching live dev ai sessions (+ dev-claode base profile)
# - claude-* profiles: keeps those with a live tmux session, removes the rest

PROFILE_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

live_sessions=$(/usr/local/bin/dev ai list 2>/dev/null | awk '$NF == "active" || $NF == "stale" { print $1 }')

removed=0
kept=0

# Clean dev-* profiles
for f in "$PROFILE_DIR"/dev-*.json; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .json)"
  session="${name#dev-}"

  if echo "$live_sessions" | grep -qx "$session"; then
    echo "KEEP  $name (live session)"
    kept=$((kept + 1))
  else
    echo "DEL   $name"
    rm "$f"
    removed=$((removed + 1))
  fi
done

# Clean claude-* profiles
tmux_sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

for f in "$PROFILE_DIR"/claude-*.json; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .json)"
  session="${name#claude-}"

  if echo "$tmux_sessions" | grep -qx "$session"; then
    echo "KEEP  $name (live tmux session)"
    kept=$((kept + 1))
  else
    echo "DEL   $name"
    rm "$f"
    removed=$((removed + 1))
  fi
done

echo ""
echo "Done: removed $removed, kept $kept"
