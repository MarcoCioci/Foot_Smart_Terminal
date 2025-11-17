#!/usr/bin/env bash
set -Eeuo pipefail

# --- HELP FLAG --------------------------------------------------------------
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<EOF
Smart Foot Terminal
-------------------

This script launches a Foot terminal integrated with tmux, using a custom
configuration designed for Wayland:

✓ Ctrl+Space: toggle tmux copy-mode scrollback
✓ Vi-style copy-mode selection (Space, v, y, Enter)
✓ Persistent scrollback without interfering with Foot’s native selection
✓ Clean minimal UI (no tmux status bar)
✓ Wayland-friendly behavior (mouse disabled inside tmux)

Usage:
  foot_smart_terminal            Launch Foot + tmux
  foot_smart_terminal --help     Show this help message

Location:
  ~/.local/bin/foot_smart_terminal   (executable used by .desktop file)
  ~/Scripts/foot_smart_terminal      (source reference copy)
EOF
    exit 0
fi
# ---------------------------------------------------------------------------




# ---- Config ----
SESSION_NAME="${SESSION_NAME:-main}"
APP_ID="${APP_ID:-foot-terminal}"
TERM_FOR_FOOT="${TERM_FOR_FOOT:-foot-direct}"

# ---- Dependencies check ----
for bin in tmux foot pgrep ps awk; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Error: required command '$bin' not found in PATH." >&2
    exit 1
  }
done

# ---- Snapshot existing Foot windows BEFORE spawning a new one ----
# This ensures we never kill the one we just launched.
readarray -t FOOT_PIDS < <(ps -eo pid,comm | awk '$2=="foot"{print $1}')

# ---- Ensure tmux session exists (detached) ----
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux new-session -d -s "$SESSION_NAME"
fi

# ---- Get panes; if none, create a default shell pane ----
PANE_INFO="$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index} #{pane_pid} #{pane_current_command}" || true)"
if [[ -z "$PANE_INFO" ]]; then
  # Extremely rare, but create a window/pane
  tmux new-session -d -t "$SESSION_NAME" || true
  PANE_INFO="$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index} #{pane_pid} #{pane_current_command}")"
fi

# ---- Choose the pane to preserve: current heuristic = first pane ----
TARGET_PANE_LINE="$(printf "%s\n" "$PANE_INFO" | head -n 1)"
TARGET_PANE_INDEX="$(awk '{print $1}' <<<"$TARGET_PANE_LINE")"
TARGET_PANE_PID="$(awk '{print $2}' <<<"$TARGET_PANE_LINE")"

echo "Preserving tmux pane index $TARGET_PANE_INDEX (PID=$TARGET_PANE_PID)"

# ---- Launch a new Foot window attached to that pane ----
# We pass a specific app-id so GNOME can associate the window with our .desktop entry.
# We also set TERM to foot-direct for proper termcap behavior inside Foot.
foot --app-id="$APP_ID" \
  env TERM="$TERM_FOR_FOOT" \
  tmux new-session -A -t "$SESSION_NAME" \; \
  select-pane -t "$TARGET_PANE_INDEX" &

# Give Foot+tmux a moment to appear in the process table relationship
sleep 1

# ---- Kill all Foot windows that DO NOT own the preserved pane's PID ----
for foot_pid in "${FOOT_PIDS[@]:-}"; do
  # If there were no foot PIDs earlier, skip
  [[ -n "${foot_pid:-}" ]] || continue

  # Check only direct children of the Foot process
  PRESERVE=false
  while read -r child || [[ -n "${child:-}" ]]; do
    [[ -n "${child:-}" ]] || continue
    if [[ "$child" == "$TARGET_PANE_PID" ]]; then
      PRESERVE=true
      break
    fi
  done < <(pgrep -P "$foot_pid" || true)

  if [[ "$PRESERVE" == true ]]; then
    echo "Skipping preserved Foot window PID=$foot_pid"
  else
    echo "Killing Foot window PID=$foot_pid"
    kill "$foot_pid" 2>/dev/null || true
    # If it doesn't die quickly, force it
    sleep 0.2
    kill -0 "$foot_pid" 2>/dev/null && kill -9 "$foot_pid" 2>/dev/null || true
  fi
done
