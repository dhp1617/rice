#!/bin/bash
# install.sh — restore this rice on a fresh Arch install
set -e

RICE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/rice-backup-$(date +%Y%m%d-%H%M)"

echo "→ Installing rice from $RICE"

# ---------- Backup existing ----------
mkdir -p "$BACKUP"
for d in hypr kitty waybar quickshell ambxst; do
    [ -e "$HOME/.config/$d" ] && cp -r "$HOME/.config/$d" "$BACKUP/" && echo "  backed up ~/.config/$d"
done
[ -e "$HOME/.local/src/ambxst" ] && cp -r "$HOME/.local/src/ambxst" "$BACKUP/"
[ -e "$HOME/bin" ] && cp -r "$HOME/bin" "$BACKUP/"

# ---------- Dependencies ----------
echo "→ Checking dependencies..."
MISSING=""
for pkg in hyprland hyprpaper kitty waybar rofi pavucontrol grim slurp wl-clipboard tlp brightnessctl matugen curl jq go; do
    command -v $pkg >/dev/null 2>&1 || MISSING="$MISSING $pkg"
done
[ -n "$MISSING" ] && echo "  ⚠ Missing:$MISSING" && echo "  Install: sudo pacman -S$MISSING"

# ---------- Ambxst source ----------
echo "→ Ambxst source → ~/.local/src/ambxst"
mkdir -p ~/.local/src
rm -rf ~/.local/src/ambxst
cp -r "$RICE/ambxst/src" ~/.local/src/ambxst

# ---------- Ambxst build ----------
echo "→ Building Ambxst..."
cd ~/.local/src/ambxst
[ -f Makefile ] && make build
if [ -f axctl ]; then
    cp axctl ~/.local/bin/axctl
    chmod +x ~/.local/bin/axctl
    echo "  ✓ ~/.local/bin/axctl"
fi

# axctl — official binary
if ! command -v axctl >/dev/null 2>&1; then
    curl -fsSL get.axeni.de/axctl | sh
    echo "  ✓ axctl installed"
fi

# ---------- Configs ----------
echo "→ Hyprland"
mkdir -p ~/.config/hypr/scripts
cp "$RICE/hypr/hyprland.lua" ~/.config/hypr/
cp "$RICE/hypr/scripts/"*.sh ~/.config/hypr/scripts/
chmod +x ~/.config/hypr/scripts/*.sh

echo "→ Kitty"
mkdir -p ~/.config/kitty
cp "$RICE/kitty/kitty.conf" ~/.config/kitty/

echo "→ Waybar"
mkdir -p ~/.config/waybar
cp -r "$RICE/waybar/"* ~/.config/waybar/

echo "→ Ambxst config"
mkdir -p ~/.config/ambxst
cp -r "$RICE/ambxst/config/"* ~/.config/ambxst/
mkdir -p ~/.local/share/ambxst
cp "$RICE/ambxst/axctl.toml" ~/.local/share/ambxst/

echo "→ ~/bin scripts"
mkdir -p ~/bin
cp "$RICE/bin/"*.sh ~/bin/
chmod +x ~/bin/*.sh

# ---------- PATH ----------
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo ""
    echo "⚠ Add to ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$HOME/bin:\$PATH\""
fi

echo ""
echo "✓ Done. Log out, log back in."
echo "Backup: $BACKUP"
