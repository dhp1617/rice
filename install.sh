#!/bin/bash
# install.sh — self-contained Hyprland rice installer
set -e

RICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/rice-backup-$(date +%Y%m%d-%H%M)"

echo "→ Installing rice from $RICE_DIR"

# ---------- Backup ----------
mkdir -p "$BACKUP"
for d in hypr kitty quickshell ambxst; do
    [ -e "$HOME/.config/$d" ] && cp -r "$HOME/.config/$d" "$BACKUP/" && echo "  backed up ~/.config/$d"
done
[ -e "$HOME/.local/share/ambxst" ] && cp -r "$HOME/.local/share/ambxst" "$BACKUP/"
[ -e "$HOME/.local/src/ambxst" ]   && cp -r "$HOME/.local/src/ambxst"   "$BACKUP/"
echo "→ Backup saved: $BACKUP"

# ---------- Dependency check ----------
echo "→ Checking dependencies..."
MISSING=""
for pkg in hyprland hyprpaper kitty matugen curl jq go; do
    command -v $pkg >/dev/null 2>&1 || MISSING="$MISSING $pkg"
done
if [ -n "$MISSING" ]; then
    echo "  ⚠ Missing:$MISSING"
    echo "  Install with: sudo pacman -S$MISSING"
    read -p "  Continue anyway? [y/N] " ans
    [ "$ans" != "y" ] && exit 1
fi

# ---------- Ambxst: copy source ----------
echo "→ Installing Ambxst source..."
mkdir -p ~/.local/src
rm -rf ~/.local/src/ambxst
cp -r "$RICE_DIR/ambxst/src" ~/.local/src/ambxst

# ---------- Ambxst: build ----------
echo "→ Building Ambxst..."
cd ~/.local/src/ambxst
if [ -f Makefile ]; then
    make build
    if [ -f ambxst ]; then
        mkdir -p ~/.local/bin
        cp ambxst ~/.local/bin/ambxst
        chmod +x ~/.local/bin/ambxst
        echo "  ✓ installed to ~/.local/bin/ambxst"
    else
        echo "  ✗ build did not produce binary — check manually"
        exit 1
    fi
else
    echo "  ✗ no Makefile found"
    exit 1
fi

# ---------- Hyprland ----------
echo "→ Installing Hyprland config"
mkdir -p ~/.config/hypr/scripts
cp "$RICE_DIR/hypr/hyprland.lua" ~/.config/hypr/
cp "$RICE_DIR/hypr/scripts/"*.sh ~/.config/hypr/scripts/
chmod +x ~/.config/hypr/scripts/*.sh

# ---------- Quickshell widgets ----------
echo "→ Installing Quickshell widgets"
mkdir -p ~/.config/quickshell/widgets
cp "$RICE_DIR/quickshell/widgets/"*.qml ~/.config/quickshell/widgets/

# ---------- Kitty ----------
echo "→ Installing Kitty config"
mkdir -p ~/.config/kitty
cp "$RICE_DIR/kitty/kitty.conf" ~/.config/kitty/

# ---------- Ambxst config ----------
echo "→ Installing Ambxst config"
mkdir -p ~/.config/ambxst
cp -r "$RICE_DIR/ambxst/config/"* ~/.config/ambxst/ 2>/dev/null || true
mkdir -p ~/.local/share/ambxst
cp "$RICE_DIR/ambxst/axctl.toml" ~/.local/share/ambxst/ 2>/dev/null || true

# ---------- PATH check ----------
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo ""
    echo "⚠ ~/.local/bin is not in PATH. Add to ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "✓ Install complete."
echo ""
echo "Next steps:"
echo "  1. Ensure ~/.local/bin is on PATH (see above if warned)"
echo "  2. Log out and back into Hyprland"
echo ""
echo "Restore point: $BACKUP"
