#!/bin/bash

# Target: The Glava window
TARGET="^GLava$"

# Function to check and move
handle_glava() {
  # 1. Get current workspace ID
  active_ws=$(hyprctl activeworkspace -j | jq '.id')

  # 2. Count TILED windows on this workspace (ignore floating/pinned)
  # We only want to hide it if there's a tiled window covering the wallpaper.
  # If you want to hide for floating too, remove 'and .floating == false'
  count=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $active_ws and .class != \"GLava\")] | length")

  if [ "$count" -eq 0 ]; then
    # SHOW: Move to current workspace
    hyprctl dispatch movetoworkspacesilent "$active_ws,class:$TARGET"
  else
    # HIDE: Move to special workspace (off-screen)
    hyprctl dispatch movetoworkspacesilent "special:glava_hidden,class:$TARGET"
  fi
}

# Run once on startup
handle_glava

# Listen to socket events instantly (No polling)
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  case "$line" in
  workspace* | openwindow* | closewindow* | movewindow*)
    handle_glava
    ;;
  esac
done
