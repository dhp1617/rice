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

# ---------- Dependencies --------#!/bin/bash
# install.sh — one-shot rice installer
set -e

RICE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/rice-backup-$(date +%Y%m%d-%H%M)"
USERNAME="$(whoami)"

echo "→ Installing rice from $RICE"
echo "→ User: $USERNAME"

# ─────────────────────────────────────────────────
# 1. BACKUP EXISTING CONFIG
# ─────────────────────────────────────────────────
mkdir -p "$BACKUP"
for d in hypr kitty waybar quickshell ambxst; do
    [ -e "$HOME/.config/$d" ] && cp -r "$HOME/.config/$d" "$BACKUP/" && echo "  backed up ~/.config/$d"
done
[ -e "$HOME/.local/src/ambxst" ] && cp -r "$HOME/.local/src/ambxst" "$BACKUP/"
[ -e "$HOME/bin" ] && cp -r "$HOME/bin" "$BACKUP/"
[ -e "$HOME/.local/share/ambxst" ] && cp -r "$HOME/.local/share/ambxst" "$BACKUP/"
echo "→ Backup: $BACKUP"

# ─────────────────────────────────────────────────
# 2. PACKAGES
# ─────────────────────────────────────────────────
echo "→ Installing packages..."
sudo pacman -S --needed --noconfirm \
    hyprland hyprpaper hyprpolkitagent \
    kitty waybar rofi pavucontrol \
    grim slurp wl-clipboard cliphist \
    brightnessctl tlp \
    nautilus sushi gthumb \
    nvidia-open-dkms nvidia-utils nvidia-settings nvidia-prime \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    tesseract tesseract-data-eng libnotify zbar curl jq xdg-utils \
    imagemagick wtype playerctl ddcutil \
    ttf-jetbrains-mono-nerd ttf-roboto noto-fonts noto-fonts-emoji \
    go git base-devel sddm nm-connection-editor \
    accountsservice inetutils 2>/dev/null || true

# AUR packages
if ! command -v yay >/dev/null 2>&1; then
    echo "→ Installing yay..."
    cd /tmp && git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm
    cd ~
fi
yay -S --needed --noconfirm \
    quickshell-git matugen ttf-iosevka-nerd ttf-phosphor-icons 2>/dev/null || true

# ─────────────────────────────────────────────────
# 3. AMBXST BUILD
# ─────────────────────────────────────────────────
echo "→ Building Ambxst..."
mkdir -p ~/.local/src ~/.local/bin
rm -rf ~/.local/src/ambxst
cp -r "$RICE/ambxst/src" ~/.local/src/ambxst

cd ~/.local/src/ambxst
[ -f Makefile ] && make build
if [ -f ambxst ]; then
    cp ambxst ~/.local/bin/ambxst
    chmod +x ~/.local/bin/ambxst
    echo "  ✓ ~/.local/bin/ambxst"
fi

# axctl binary (official installer)
if ! command -v axctl >/dev/null 2>&1; then
    curl -fsSL get.axeni.de/axctl | sh
fi

# ─────────────────────────────────────────────────
# 4. SYSTEM SERVICES
# ─────────────────────────────────────────────────
echo "→ Configuring services..."
sudo systemctl mask power-profiles-daemon 2>/dev/null || true
sudo systemctl enable tlp sddm
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
sudo usermod -aG input "$USERNAME"
sudo usermod -aG video "$USERNAME"

# ─────────────────────────────────────────────────
# 5. COPY CONFIGS
# ─────────────────────────────────────────────────
echo "→ Installing configs..."

# Hyprland
mkdir -p ~/.config/hypr/scripts
cp "$RICE/hypr/hyprland.lua" ~/.config/hypr/
cp "$RICE/hypr/scripts/"*.sh ~/.config/hypr/scripts/
chmod +x ~/.config/hypr/scripts/*.sh

# Kitty
mkdir -p ~/.config/kitty
cp "$RICE/kitty/kitty.conf" ~/.config/kitty/

# Waybar
mkdir -p ~/.config/waybar
cp -r "$RICE/waybar/"* ~/.config/waybar/ 2>/dev/null || true

# Ambxst config
mkdir -p ~/.config/ambxst/config ~/.local/share/ambxst
cp -r "$RICE/ambxst/config/"* ~/.config/ambxst/config/
cp "$RICE/ambxst/binds.json" ~/.config/ambxst/ 2>/dev/null || true
cp "$RICE/ambxst/axctl.toml" ~/.local/share/ambxst/
chmod 444 ~/.local/share/ambxst/axctl.toml

# Wallpaper state
cp "$RICE/ambxst/wallpapers.json" ~/.cache/ambxst/ 2>/dev/null || true

# SDDM theme config
if [ -f "$RICE/sddm-theme.conf" ]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp "$RICE/sddm-theme.conf" /etc/sddm.conf.d/theme.conf
fi

# ─────────────────────────────────────────────────
# 6. BIN SCRIPTS
# ─────────────────────────────────────────────────
echo "→ Installing ~/bin scripts..."
mkdir -p ~/bin
cp "$RICE/bin/"*.sh ~/bin/
chmod +x ~/bin/*.sh

# ─────────────────────────────────────────────────
# 7. PATH
# ─────────────────────────────────────────────────
if ! grep -q '.local/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$HOME/bin:$PATH"' >> ~/.bashrc
fi

# ─────────────────────────────────────────────────
# 8. NVIDIA PM + CHARGE THRESHOLD
# ─────────────────────────────────────────────────
echo "→ NVIDIA power management..."
sudo mkdir -p /etc/modprobe.d /etc/udev/rules.d
echo 'options nvidia NVreg_DynamicPowerManagement=0x02' | sudo tee /etc/modprobe.d/nvidia-pm.conf >/dev/null
echo 'options nvidia_drm modeset=1' | sudo tee -a /etc/modprobe.d/nvidia-pm.conf >/dev/null
echo 'options nvidia_drm fbdev=1' | sudo tee -a /etc/modprobe.d/nvidia-pm.conf >/dev/null

sudo tee /etc/udev/rules.d/80-nvidia-pm.rules >/dev/null <<'UDEV'
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", TEST=="power/control", ATTR{power/control}="auto"
UDEV

# Battery threshold
if ! grep -q 'STOP_CHARGE_THRESH_BAT1' /etc/tlp.conf 2>/dev/null; then
    echo 'START_CHARGE_THRESH_BAT1=75' | sudo tee -a /etc/tlp.conf >/dev/null
    echo 'STOP_CHARGE_THRESH_BAT1=80'   | sudo tee -a /etc/tlp.conf >/dev/null
    echo 'RESTORE_THRESHOLDS_ON_BAT=1'  | sudo tee -a /etc/tlp.conf >/dev/null
fi

sudo systemctl restart tlp 2>/dev/null || true

# ─────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────
echo ""
echo "✓ Install complete"
echo ""
echo "Next steps:"
echo "  1. mkinitcpio -P   (rebuild initramfs for NVIDIA)"
echo "  2. Reboot"
echo "  3. First boot applies everything automatically"
echo ""
echo "Restore point: $BACKUP"--
echo "→ Checking dependencies..."
MISSING=""
for pkg in hyprland hyprpaper hyprpolkitagent kitty waybar rofi pavucontrol \
           grim slurp wl-clipboard cliphist brightnessctl tlp \
           tesseract tesseract-data-eng libnotify zbar curl jq xdg-utils \
           imagemagick matugen go git base-devel \
           ttf-jetbrains-mono-nerd ttf-iosevka-nerd ttf-phosphor-icons \
           ttf-roboto noto-fonts noto-fonts-emoji \
           nautilus sushi gthumb sddm; do
    command -v $pkg >/dev/null 2>&1 || MISSING="$MISSING $pkg"
done
if [ -n "$MISSING" ]; then
    echo "  ⚠ Missing:$MISSING"
    echo "  Run: sudo pacman -S$MISSING"
    echo "  Or:  yay -S ttf-phosphor-icons ttf-iosevka-nerd"
fi
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
