#!/bin/bash
# Watches Ambxst wallpaper changes and syncs Hyprland borders
WATCH="$HOME/.cache/ambxst/wallpapers.json"
LAST=""

while true; do
    if [ -f "$WATCH" ]; then
        CUR=$(grep -oP '"currentWall":\s*"\K[^"]+' "$WATCH" 2>/dev/null)
        if [ -n "$CUR" ] && [ "$CUR" != "$LAST" ]; then
            if [ -n "$LAST" ]; then
                # Wait for axctl.toml to be rewritten
                sleep 2
                A=$(grep '^active_color' ~/.local/share/ambxst/axctl.toml | grep -oP 'rgb\(\K[^)]+')
                I=$(grep '^inactive_color' ~/.local/share/ambxst/axctl.toml | grep -oP 'rgb\(\K[^)]+')
                if [ -n "$A" ]; then
                    hyprctl eval "hl.config({general={col={active_border={colors={\"rgb($A)\",\"rgb($A)\"},angle=45},inactive_border=\"rgb($I)\"}}})"
                fi
            fi
            LAST="$CUR"
        fi
    fi
    sleep 0.5
done
