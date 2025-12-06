#!/bin/bash

# 1. Toggle Check
if pkill -x "wofi"; then
  exit 0
fi

# 2. Get List
raw_list=$(cliphist list)

# 3. Show Wofi
selected=$(echo "$raw_list" | wofi --dmenu --conf /dev/null --style ~/.config/wofi/style.css --prompt "Clipboard" --height 300 --width 600)

# 4. CHECK EXIT CODE (Fixes Ghost Paste)
if [ $? -ne 0 ]; then
  exit 1
fi

# 5. Decode & Copy
echo "$selected" | cliphist decode | wl-copy

# 6. Smart Paste Logic
sleep 0.2
current_window=$(hyprctl activewindow -j | jq -r ".class")

if [[ "$current_window" == "kitty" ]]; then
  wtype -M ctrl -M shift -k v -m shift -m ctrl
else
  wtype -M ctrl -k v -m ctrl
fi
