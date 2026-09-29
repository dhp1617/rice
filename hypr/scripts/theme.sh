#!/bin/bash
W="$1"
[ -z "$W" ] && W=$(cat ~/.cache/current-wallpaper 2>/dev/null)
[ ! -f "$W" ] && { echo "Not found"; exit 1; }
echo "$W" > ~/.cache/current-wallpaper

# Wallpaper
cat > ~/.config/hypr/hyprpaper.conf <<EOF
wallpaper {
    monitor = 
    path = $W
    fit_mode = cover
}
splash = false
ipc = on
EOF
pkill -x hyprpaper; sleep 0.3
setsid hyprpaper >/dev/null 2>&1 < /dev/null &
sleep 1

# Ambxst runs Matugen
ambxst wallpaper "$W"

# Wait for axctl.toml to update
# Wait until axctl.toml updates (max 3s, usually ~1s)
BEFORE=$(stat -c %Y ~/.local/share/ambxst/axctl.toml 2>/dev/null)
for i in $(seq 1 15); do
    sleep 0.2
    NOW=$(stat -c %Y ~/.local/share/ambxst/axctl.toml 2>/dev/null)
    [ "$NOW" != "$BEFORE" ] && break
done

# Read colors (single line each)
A=$(grep '^active_color' ~/.local/share/ambxst/axctl.toml | grep -oP 'rgb\(\K[^)]+')
I=$(grep '^inactive_color' ~/.local/share/ambxst/axctl.toml | grep -oP 'rgb\(\K[^)]+')

echo "Applying borders: active=$A inactive=$I"

# Apply borders
hyprctl eval "hl.config({general={col={active_border={colors={\"rgb($A)\",\"rgb($A)\"},angle=45},inactive_border=\"rgb($I)\"}}})"

pkill -SIGUSR1 kitty 2>/dev/null
echo "Done"
