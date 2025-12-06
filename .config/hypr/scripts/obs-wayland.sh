#!/bin/bash
# Force the QT framework to use the Wayland backend (Crucial fix for OBS)
export QT_QPA_PLATFORM="wayland"

# Ensure the portal knows which desktop it's dealing with
export XDG_CURRENT_DESKTOP="Hyprland"

# Launch OBS, replacing the script process
exec obs
