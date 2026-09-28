#!/bin/bash
# Toggle between full rice (Ambxst) and minimal (Waybar)
# Usage: rice-mode.sh [full|minimal|toggle]
exec >> /tmp/rice-mode.log 2>&1
echo "=== $(date) arg=$1 ==="
STATE="$HOME/.cache/rice-mode"

# Determine current mode
CURRENT="full"
[ -f "$STATE" ] && CURRENT=$(cat "$STATE")

# Determine target
case "${1:-toggle}" in
  full)    TARGET="full" ;;
  minimal) TARGET="minimal" ;;
  toggle|*) 
    [ "$CURRENT" = "full" ] && TARGET="minimal" || TARGET="full"
    ;;
esac

echo "Switching: $CURRENT → $TARGET"

# ---------- MINIMAL MODE ----------
if [ "$TARGET" = "minimal" ]; then
    echo "minimal" > "$STATE"

    # Kill rice
    pkill -f "border-watcher.sh"         2>/dev/null
    pkill -f "theme.sh"                  2>/dev/null
    pkill -x ambxst                      2>/dev/null
    sleep 1

    # Perf tuning
    brightnessctl set 30% 2>/dev/null
    hyprctl eval 'hl.monitor({output="eDP-1", mode="1920x1080@60", position="auto", scale="1"})' 2>/dev/null

    # Start Waybar detached
    pkill waybar 2>/dev/null
    sleep 0.5
    setsid waybar >/dev/null 2>&1 < /dev/null &

    notify-send "Rice Mode" "Minimal / battery saver" 2>/dev/null
    exit 0
fi

# ---------- FULL MODE ----------
echo "full" > "$STATE"

# Kill minimal
pkill waybar 2>/dev/null
sleep 0.5

# Restore perf
brightnessctl set 80% 2>/dev/null
hyprctl eval 'hl.monitor({output="eDP-1", mode="1920x1080@144", position="auto", scale="1"})' 2>/dev/null

# Start rice (detached so they survive)
setsid ambxst >/dev/null 2>&1 < /dev/null &
sleep 2
setsid bash "$HOME/.config/hypr/scripts/border-watcher.sh" >/dev/null 2>&1 < /dev/null &

notify-send "Rice Mode" "Full rice active" 2>/dev/null
