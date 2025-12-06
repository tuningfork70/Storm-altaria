#!/bin/bash

# -----------------------------------------------------
# STORM ALTARIA INSTALLER (v4 - FOLDER MODE)
# Automates: Drivers, Configs, Anti-Loop logic
# -----------------------------------------------------

set -e

SOURCE_USER="tuning-fork"

# Helper function for pretty printing
log() {
  echo -e "\033[0;32m[STORM]\033[0m $1"
}
error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1"
}

log "Initializing Storm Altaria Setup..."

# 0. Safety Check
if [ "$EUID" -eq 0 ]; then
  error "Do not run as root (sudo). Run as your normal user."
  exit 1
fi

# 1. Install Yay
if ! command -v yay &>/dev/null; then
  log "Installing Yay..."
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
else
  log "Yay is already installed."
fi

# 1.1 Fix Multilib
if grep -q "#\[multilib\]" /etc/pacman.conf; then
  log "Configuring multilib repository..."
  sudo sed -i "/\[multilib\]/,/Include/ s/^#//" /etc/pacman.conf
  log "Refreshing package databases..."
  sudo pacman -Syy --noconfirm
else
  log "Multilib is already enabled."
fi
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji
# 2. Install Base Packages
log "Installing System Packages from pkglist.txt..."
if [ -f "pkglist.txt" ]; then
  yay -S --needed --noconfirm $(grep -vE "^\s*#" pkglist.txt | tr '\n' ' ')
else
  error "pkglist.txt not found! Skipping package install."
fi

# 2.5 Hardware Auto-Detection
log "Detecting Hardware..."
sudo pacman -S --needed --noconfirm pciutils

if lspci | grep -i "nvidia" &>/dev/null; then
  log "--- Nvidia GPU detected ---"
  yay -S --needed --noconfirm linux-headers nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings
  echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf

  if ! grep -q "nvidia_drm" /etc/mkinitcpio.conf; then
    log "Patching mkinitcpio for early Nvidia loading..."
    sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
  fi
elif lspci | grep -i "amd" &>/dev/null && lspci | grep -i "vga" &>/dev/null; then
  log "--- AMD GPU detected ---"
  yay -S --needed --noconfirm xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon
elif lspci | grep -i "intel" &>/dev/null && lspci | grep -i "vga" &>/dev/null; then
  log "--- Intel GPU detected ---"
  yay -S --needed --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver
fi

# CPU Microcode
if grep -q "AuthenticAMD" /proc/cpuinfo; then
  yay -S --needed --noconfirm amd-ucode
elif grep -q "GenuineIntel" /proc/cpuinfo; then
  yay -S --needed --noconfirm intel-ucode
fi

# ------------------------------------------------------
# 3. Backup & Install Configs (FOLDER MODE)
# ------------------------------------------------------
log "Deploying Configs..."
BACKUP_DIR="$HOME/StormAltaria_Backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

CONFIGS=(
  ".config/hypr" ".config/waybar" ".config/kitty" ".config/wofi"
  ".config/dunst" ".config/swaync" ".config/fastfetch" ".config/yazi"
  ".config/mpv" ".config/spicetify" ".config/gtk-3.0" ".config/gtk-4.0"
  ".config/fontconfig" ".config/btop" ".config/nvim" ".config/glava"
  ".config/qt5ct" ".config/qimgv" ".config/qalculate"
  ".local/share/applications" ".zshrc"
  ".config/starship.toml"
)

log "Backing up existing configs to $BACKUP_DIR..."
for config in "${CONFIGS[@]}"; do
  DIR=$(dirname "$config")
  if [ -e "$HOME/$config" ]; then
    mkdir -p "$BACKUP_DIR/$DIR"
    mv "$HOME/$config" "$BACKUP_DIR/$DIR/"
  fi
done

log "Installing new configs..."
# Create target directories
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/Pictures"

# Copy directories
# We use cp -r to copy the contents of our repo's .config into the user's .config
if [ -d ".config" ]; then
  cp -r .config/* "$HOME/.config/"
else
  error ".config folder not found in repo!"
  exit 1
fi

# Copy loose files
cp .zshrc "$HOME/"
cp Pictures/altaria_wall.jpg "$HOME/Pictures/" 2>/dev/null || true
cp .local/share/applications/* "$HOME/.local/share/applications/" 2>/dev/null || true

# Force scripts to be executable
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# 4. PATH PATCHING (Redundant if we sanitized, but good failsafe)
log "Ensuring paths are correct..."
find "$HOME/.config" -type f -exec grep -Iq "/home/$SOURCE_USER" {} \; -exec sed -i "s|/home/$SOURCE_USER|/home/$USER|g" {} +

# 4.5 Autostart Logic
log "Configuring Autostart..."
if grep -q "STORM ALTARIA AUTOSTART" "$HOME/.zshrc"; then
  log "Autostart already configured."
else
  cat >>"$HOME/.zshrc" <<EOF

# --- STORM ALTARIA AUTOSTART ---
if [ -z "\$DISPLAY" ] && [ "\$XDG_VTNR" -eq 1 ]; then
  exec Hyprland
fi
EOF
fi

# 5. Services
log "Enabling Services..."
sudo systemctl enable --now NetworkManager
if command -v bluetoothd &>/dev/null; then
  sudo systemctl enable --now bluetooth
fi

# 6. Spicetify Apply
if [ -d "/opt/spotify" ] && command -v spicetify &>/dev/null; then
  log "Patching Spotify..."
  sudo chmod a+wr /opt/spotify
  sudo chmod a+wr /opt/spotify/Apps -R
  spicetify backup apply || true
  spicetify config current_theme Comfy color_scheme SoftCloud || true
  spicetify apply || true
fi

# 7. Shell Change
log "Changing shell to Zsh..."
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh
fi

echo ""
echo "---------------------------------------------------------"
echo "SETUP COMPLETE!"
echo "Please REBOOT your system now."
echo "---------------------------------------------------------"
