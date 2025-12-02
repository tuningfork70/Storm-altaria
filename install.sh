#!/bin/bash

# -----------------------------------------------------
# STORM ALTARIA INSTALLER (REVISED v2)
# Automates: Drivers, Configs, Anti-Loop logic
# -----------------------------------------------------

set -e

SOURCE_USER="tuning-fork" # The username in your config files

echo "Initializing Storm Altaria Setup..."

# 0. Safety Check
if [ "$EUID" -eq 0 ]; then
  echo "Error: Do not run as root (sudo). Run as your normal user."
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

# 1.1 Fix Multilib (32-bit support)
echo "Configuring multilib repository..."
sudo sed -i "/\[multilib\]/,/Include/ s/^#//" /etc/pacman.conf
echo "Refreshing package databases..."
sudo pacman -Syy --noconfirm

# 2. Install Base Packages
echo "Installing System Packages from pkglist.txt..."
if [ -f "pkglist.txt" ]; then
  # Filter out comments and install
  yay -S --needed --noconfirm $(grep -vE "^\s*#" pkglist.txt | tr '\n' ' ')
else
  echo "Warning: pkglist.txt not found! Skipping package install."
fi

# ------------------------------------------------------
# 2.5 Hardware Auto-Detection & Driver Patching
# ------------------------------------------------------
echo "Detecting Hardware..."

# Ensure pciutils is installed for detection
sudo pacman -S --needed --noconfirm pciutils

if lspci | grep -i "nvidia" &>/dev/null; then
  echo "--- Nvidia GPU detected ---"
  echo "Installing Nvidia DKMS drivers..."
  yay -S --needed --noconfirm linux-headers nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings

  # 1. Kernel Parameter (DRM Modesetting)
  echo "Setting kernel parameter..."
  echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf

  # 2. Early Loading (CRITICAL FIX FOR BLACK SCREENS)
  # This forces the GPU drivers to load before Hyprland tries to start.
  echo "Patching mkinitcpio for early Nvidia loading..."
  sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
  
  echo "Rebuilding initramfs..."
  sudo mkinitcpio -P

elif lspci | grep -i "amd" &>/dev/null && lspci | grep -i "vga" &>/dev/null; then
  echo "--- AMD GPU detected ---"
  echo "Installing Mesa/Vulkan..."
  yay -S --needed --noconfirm xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon
  
  # Optional: Early load AMD
  sudo sed -i 's/MODULES=(/MODULES=(amdgpu /' /etc/mkinitcpio.conf
  sudo mkinitcpio -P

elif lspci | grep -i "intel" &>/dev/null && lspci | grep -i "vga" &>/dev/null; then
  echo "--- Intel GPU detected ---"
  echo "Installing Intel Media Drivers..."
  yay -S --needed --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver
fi

# CPU Microcode
if grep -q "AuthenticAMD" /proc/cpuinfo; then
  echo "AMD CPU detected. Installing microcode..."
  yay -S --needed --noconfirm amd-ucode
elif grep -q "GenuineIntel" /proc/cpuinfo; then
  echo "Intel CPU detected. Installing microcode..."
  yay -S --needed --noconfirm intel-ucode
fi

# ------------------------------------------------------
# 3. Backup & Install Configs
# ------------------------------------------------------
echo "Deploying Configs..."
BACKUP_DIR="$HOME/StormAltaria_Backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

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
if [ -f "configs.tar.gz" ]; then
    tar -xzvf configs.tar.gz -C "$HOME" --no-same-owner
else
    echo "Error: configs.tar.gz not found!"
    exit 1
fi

# Force scripts to be executable
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# 4. PATH PATCHING
echo "Patching hardcoded paths from '$SOURCE_USER' to '$USER'..."
find "$HOME/.config" "$HOME/.local/share/applications" -type f -exec grep -Iq "/home/$SOURCE_USER" {} \; -exec sed -i "s|/home/$SOURCE_USER|/home/$USER|g" {} +
echo "Paths updated."

# ------------------------------------------------------
# 4.5. ANTI-LOGIN LOOP PATCH (CRITICAL)
# ------------------------------------------------------
echo "Configuring Autostart Logic..."

# Disable Display Managers (SDDM/GDM) to prevent conflict with TTY autostart.
# We want the user to login via TTY, so they can see errors if Hyprland crashes.
if systemctl list-unit-files | grep -q "sddm.service"; then
    echo "Disabling SDDM to allow safe TTY autostart..."
    sudo systemctl disable sddm
    sudo systemctl stop sddm 2>/dev/null || true
fi
if systemctl list-unit-files | grep -q "gdm.service"; then
    sudo systemctl disable gdm
    sudo systemctl stop gdm 2>/dev/null || true
fi

echo "Applying Auto-Start Patch to .zshrc..."
# Appends logic to start Hyprland automatically ONLY on TTY1
cat >> "$HOME/.zshrc" <<EOF

# --- STORM ALTARIA AUTOSTART ---
# Only start Hyprland on TTY1 to avoid login loops.
# If it crashes, you will fall back to TTY1 command line.
if [ -z "\$DISPLAY" ] && [ "\$XDG_VTNR" -eq 1 ]; then
  exec Hyprland
fi
EOF

# 5. Services
echo "Enabling System Services..."
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

# 7. Shell Change
echo "Changing shell to Zsh..."
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh
fi

echo ""
echo "---------------------------------------------------------"
echo "SETUP COMPLETE!"
echo "Please REBOOT your system now."
echo "After reboot, login with your password and Hyprland will start."
echo "---------------------------------------------------------"
