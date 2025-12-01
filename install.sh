#!/bin/bash

# -----------------------------------------------------
# STORM ALTARIA INSTALLER
# -----------------------------------------------------

set -e

# Define the source username to replace (Your username)
SOURCE_USER="tuning-fork"

echo "⚡ Initializing Storm Altaria Setup..."

# 0. Safety Check
if [ "$EUID" -eq 0 ]; then
  echo "❌ Error: Do not run as root (sudo). Run as user."
  exit 1
fi

# 1. Install Yay (AUR Helper)
if ! command -v yay &>/dev/null; then
  echo "📦 Installing Yay..."
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
else
  echo "✅ Yay is already installed."
fi

# 2. Install Packages from pkglist.txt
echo "📦 Installing Packages..."
if [ -f "pkglist.txt" ]; then
  # Install packages, ignoring comments and empty lines
  yay -S --needed --noconfirm $(grep -vE "^\s*#" pkglist.txt | tr '\n' ' ')
else
  echo "❌ pkglist.txt not found! Skipping package install."
fi

# 3. Backup & Install Configs
echo "🎨 Deploying Configs..."
BACKUP_DIR="$HOME/StormAltaria_Backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# List of folders to backup
CONFIGS=(
  ".config/hypr" ".config/waybar" ".config/kitty" ".config/wofi"
  ".config/dunst" ".config/swaync" ".config/fastfetch" ".config/yazi"
  ".config/mpv" ".config/spicetify" ".config/gtk-3.0" ".config/gtk-4.0"
  ".local/share/applications" ".zshrc"
)

echo "📂 Backing up existing configs to $BACKUP_DIR..."
for config in "${CONFIGS[@]}"; do
  DIR=$(dirname "$config")
  if [ -e "$HOME/$config" ]; then
    mkdir -p "$BACKUP_DIR/$DIR"
    mv "$HOME/$config" "$BACKUP_DIR/$DIR/"
  fi
done

# Extract files
echo "📂 Extracting new configs..."
tar -xzvf configs.tar.gz -C "$HOME" --no-same-owner

# 4. PATH PATCHING (The Fix for 'tuning-fork')
echo "🔧 Patching hardcoded paths from '$SOURCE_USER' to '$USER'..."
# We search specifically in the folders we just extracted
find "$HOME/.config" "$HOME/.local/share/applications" -type f -exec grep -Iq "/home/$SOURCE_USER" {} \; -exec sed -i "s|/home/$SOURCE_USER|/home/$USER|g" {} +
echo "✅ Paths updated."

# 5. Services
echo "⚙️ Enabling Services..."
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager

# 6. Spicetify Apply
if [ -d "/opt/spotify" ] && command -v spicetify &>/dev/null; then
  echo "🎵 Patching Spotify..."
  sudo chmod a+wr /opt/spotify
  sudo chmod a+wr /opt/spotify/Apps -R
  spicetify backup apply || true
  spicetify config current_theme Comfy color_scheme SoftCloud || true
  spicetify apply || true
fi

# 7. Shell
echo "🐚 Changing shell to Zsh..."
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh
fi

echo ""
echo "⚡ SETUP COMPLETE! Please reboot your system."
