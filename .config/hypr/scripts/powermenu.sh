#!/bin/bash

# Options (Nerd Font Glyphs)
lock="  Lock"
suspend="  Sleep"
logout="  Logout"
reboot="  Reboot"
shutdown="  Shutdown"

# The Menu List
options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

# Open Wofi
# -dmenu: Text menu mode
# --conf /dev/null: Ignore global config to keep it a list
selected=$(echo -e "$options" | wofi --dmenu --conf /dev/null --style ~/.config/wofi/style.css --prompt "Goodnight?" --height 270 --width 300)

# Exit if nothing selected
if [ -z "$selected" ]; then
  exit 0
fi

# Actions (Using Pattern Matching)
case $selected in
*Lock*)
  pidof hyprlock || hyprlock
  ;;
*Sleep*)
  systemctl suspend
  ;;
*Logout*)
  hyprctl dispatch exit
  ;;
*Reboot*)
  systemctl reboot
  ;;
*Shutdown*)
  poweroff
  ;;
esac
