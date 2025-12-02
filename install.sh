#!/bin/bash

# -----------------------------------------------------
# STORM ALTARIA INSTALLER (REGENERATED)
# -----------------------------------------------------

set -e

# Define the source username to replace (Your username)
SOURCE_USER="tuning-fork"

echo "Initializing Storm Altaria Setup..."

# 0. Safety Check
if [ "$EUID" -eq 0 ]; then
  echo "Error: Do not run as root (sudo). Run as user."
  exit 1
fi

# 1. Install Yay (AUR Helper)
if ! command -v yay &>/dev/null; then
  echo "Installing Yay..."
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
else
  echo "Yay is already installed."
fi

# 1.1 CRITICAL FIX: Force Enable Multilib Repository
echo "Configuring multilib repository..."
sudo sed -i "/\[multilib\]/,/Include/ s/^#//" /etc/pacman.conf

# Force a full database refresh
echo "Refreshing package databases..."
sudo pacman -Syy --noconfirm

# 1.5 Conflict Cleanup
echo "Removing potential conflicting packages..."
sudo pacman -Rdd --noconfirm pipewire-media-session pulseaudio jack2 2>/dev/null || true

# 2. Install Base Packages
echo "Installing System Packages from pkglist.txt..."
if [ -f "pkglist.txt" ]; then
  # Filter out comments and install
  yay -S --needed --noconfirm $(grep -vE "^\s*#" pkglist.txt | tr '\n' ' ')
else
  echo "pkglist.txt not found! Skipping package install."
fi

# ------------------------------------------------------
# 2.5 Hardware Auto-Detection & Driver Fixes
# ------------------------------------------------------
echo "Detecting Hardware..."

# GPU Driver Logic
if lspci | grep -i "nvidia" &>/dev/null; then
  echo "Nvidia GPU detected. Installing Nvidia drivers..."
  
  # FIX: Install linux-headers for DKMS module compilation
  # We assume standard 'linux' kernel. If using zen/lts, this needs adjustment.
  yay -S --needed --noconfirm linux-headers nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings

  # FIX: Enable Nvidia Modesetting (Crucial for Hyprland)
  echo "Enabling Nvidia Kernel Modesetting..."
  echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf
  
  # FIX: Regenerate initramfs to apply the modeset change
  echo "Regenerating initramfs (this may take a minute)..."
  sudo mkinitcpio -P

elif lspci | grep -i "amd" &>/dev/null && lspci | grep -i "vga" &>/dev/null; then
  echo "AMD GPU detected. Installing Mesa/Vulkan..."
  yay -S --needed --noconfirm xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon
elif lspci | grep -i "intel" &>/dev/null && lspci | grep -i "vga" &>/dev/null; then
  echo "Intel GPU detected. Installing Mesa/Vulkan..."
  yay -S --needed --noconfirm vulkan-intel lib32-vulkan-intel
fi

# CPU Microcode Logic
if grep -q "AuthenticAMD" /proc/cpuinfo; then
  echo "AMD CPU detected. Installing microcode..."
  yay -S --needed --noconfirm amd-ucode
elif grep -q "GenuineIntel" /proc/cpuinfo; then
  echo "Intel CPU detected. Installing microcode..."
  yay -S --needed --noconfirm intel-ucode
fi

# ------------------------------------------------------

# 3. Backup & Install Configs
echo "Deploying Configs..."
BACKUP_DIR="$HOME/StormAltaria_Backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# List of folders to backup
CONFIGS=(
  ".config/hypr" ".config/waybar" ".config/kitty" ".config/wofi"
  ".config/dunst" ".config/swaync" ".config/fastfetch" ".config/yazi"
  ".config/mpv" ".config/spicetify" ".config/gtk-3.0" ".config/gtk-4.0"
  ".local/share/applications" ".zshrc"
)

echo "Backing up existing configs to $BACKUP_DIR..."
for config in "${CONFIGS[@]}"; do
  DIR=$(dirname "$config")
  if [ -e "$HOME/$config" ]; then
    mkdir -p "$BACKUP_DIR/$DIR"
    mv "$HOME/$config" "$BACKUP_DIR/$DIR/"
  fi
done

# Extract files
echo "Extracting new configs..."
tar -xzvf configs.tar.gz -C "$HOME" --no-same-owner

# Force scripts to be executable
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# 4. PATH PATCHING
echo "Patching hardcoded paths from '$SOURCE_USER' to '$USER'..."
find "$HOME/.config" "$HOME/.local/share/applications" -type f -exec grep -Iq "/home/$SOURCE_USER" {} \; -exec sed -i "s|/home/$SOURCE_USER|/home/$USER|g" {} +
echo "Paths updated."

# ------------------------------------------------------
# 4.5. ANTI-LOGIN LOOP PATCH
# ------------------------------------------------------
echo "Applying Anti-Login Loop Patch to .zshrc..."
# This ensures Hyprland only starts on TTY1.
# If Hyprland crashes, you can use TTY2 (Ctrl+Alt+F2) to login safely.

cat >> "$HOME/.zshrc" <<EOF

# --- STORM ALTARIA AUTOSTART ---
# Only start Hyprland on TTY1 to avoid login loops on other TTYs
if [ -z "\$DISPLAY" ] && [ "\$XDG_VTNR" -eq 1 ]; then
  exec Hyprland
fi
EOF

# 5. Services
echo "Enabling Services..."
sudo systemctl enable --now NetworkManager
if command -v bluetoothd &>/dev/null; then
  sudo systemctl enable --now bluetooth
fi

# 6. Spicetify Apply
if [ -d "/opt/spotify" ] && command -v spicetify &>/dev/null; then
  echo "Patching Spotify..."
  sudo chmod a+wr /opt/spotify
  sudo chmod a+wr /opt/spotify/Apps -R
  spicetify backup apply || true
  spicetify config current_theme Comfy color_scheme SoftCloud || true
  spicetify apply || true
fi

# 7. Shell
echo "Changing shell to Zsh..."
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh
fi

echo ""
echo "SETUP COMPLETE! Please reboot your system."
