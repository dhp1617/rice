#!/bin/bash
# ~/.config/hypr/scripts/theme.sh — wallpaper handled entirely by Ambxst

W="$1"
CACHE="$HOME/.cache/current-wallpaper"

# Resolve wallpaper
[ -z "$W" ] || [ ! -f "$W" ] && W=$(cat "$CACHE" 2>/dev/null)
[ -z "$W" ] || [ ! -f "$W" ] && W=$(find ~/Pictures/wallpapers -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | head -1)
[ -z "$W" ] || [ ! -f "$W" ] && { echo "No wallpaper found"; exit 1; }

echo "$W" > "$CACHE"

# Apply via Ambxst (which handles wallpaper + colors + everything)
/home/dhp/.local/bin/ambxst wallpaper "$W"

# Wait for Ambxst to finish Matugen (rewrites axctl.toml)
BEFORE=$(stat -c %Y ~/.local/share/ambxst/axctl.toml 2>/dev/null)
for i in $(seq 1 15); do
    sleep 0.2
    NOW=$(stat -c %Y ~/.local/share/ambxst/axctl.toml 2>/dev/null)
    [ "$NOW" != "$BEFORE" ] && break
done

# Apply borders from axctl.toml
A=$(grep '^active_color' ~/.local/share/ambxst/axctl.toml | grep -oP 'rgb\(\K[^)]+')
I=$(grep '^inactive_color' ~/.local/share/ambxst/axctl.toml | grep -oP 'rgb\(\K[^)]+')
if [ -n "$A" ]; then
    hyprctl eval "hl.config({general={col={active_border={colors={\"rgb($A)\",\"rgb($A)\"},angle=45},inactive_border=\"rgb($I)\"}}})" 2>/dev/null
fi

# Reload Kitty colors
pkill -SIGUSR1 kitty 2>/dev/null

echo "Wallpaper applied: $W"
