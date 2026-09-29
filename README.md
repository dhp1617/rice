# Hyprland Rice

A dynamic, wallpaper-themed Hyprland desktop with custom Quickshell widgets.

## ✨ Features

- **Dynamic theming** — colors extracted from wallpaper, applied everywhere
- **Ambxst shell** — notch bar, control center, dashboard, launcher
- **Custom widgets** — calendar, system stats, crypto prices (in ₹)
- **Everything follows the wallpaper** — borders, terminal, widgets, popups
- **Draggable widgets** — place them wherever you want

## 🧩 Stack

| Component | Purpose |
|-----------|---------|
| Hyprland | Wayland compositor |
| Ambxst | Shell (notch bar, control panel) |
| hyprpaper | Wallpaper daemon |
| Kitty | Terminal |
| Quickshell | Custom desktop widgets |
| Wallust | (legacy — replaced by Ambxst Matugen) |

## 🖼️ Widgets

| Widget | What it shows | File |
|--------|--------------|------|
| Calendar | Month view with today highlighted | `quickshell/widgets/CalendarWidget.qml` |
| System Stats | CPU / RAM / Battery | `quickshell/widgets/StatsWidget.qml` |
| Crypto | BTC / ETH / DOGE prices in INR | `quickshell/widgets/CryptoWidget.qml` |

All widgets:
- Read colors from `~/.cache/ambxst/colors.json`
- Auto-update when wallpaper changes
- Draggable (release → prints position to log)

## 🎨 How theming works

1. You set a wallpaper (via Ambxst picker or `theme.sh`)
2. Ambxst runs **Matugen** to extract colors
3. It writes:
   - `~/.cache/ambxst/colors.json` → widget colors
   - `~/.cache/ambxst/kitty.conf` → terminal colors
   - `~/.local/share/ambxst/axctl.toml` → Hyprland border colors
   - `~/.config/gtk-3.0/gtk.css` → GTK apps
4. `border-watcher.sh` watches for changes and applies borders to Hyprland
5. Widgets re-read `colors.json` and repaint

## 📦 Install

### Prerequisites

- Arch Linux (or Arch-based)
- `hyprland`, `hyprpaper`, `kitty`
- `quickshell` (from AUR or source)
- `ambxst` (custom fork — see below)
- `matugen`, `curl`, `jq`

### Setup

```bash
git clone https://github.com/YOUR_USER/rice.git ~/rice
cd ~/rice
./install.sh


## Post-install checklist

1. **Fonts** — install all required:
   ```bash
   sudo pacman -S ttf-jetbrains-mono-nerd ttf-roboto noto-fonts noto-fonts-emoji
   yay -S ttf-iosevka-nerd ttf-phosphor-icons

   sudo pacman -S tesseract tesseract-data-eng libnotify zbar curl jq xdg-utils

   curl -fsSL get.axeni.de/axctl | sh

   sudo pacman -S nvidia-open-dkms nvidia-utils nvidia-settings nvidia-prime
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"


   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

   

	   
