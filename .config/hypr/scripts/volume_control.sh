#!/bin/bash

# 1. Define the target
target="@DEFAULT_AUDIO_SINK@"

# 2. Check if we have a saved specific ID
if [ -f ~/.config/hypr/scripts/current_sink ]; then
  saved_id=$(cat ~/.config/hypr/scripts/current_sink)

  # 3. Verify if that ID actually exists right now
  if wpctl inspect "$saved_id" &>/dev/null; then
    target="$saved_id"
  fi
fi

# 4. Execute Command using the validated target
case $1 in
"up")
  wpctl set-volume -l 1.0 "$target" 5%+
  ;;
"down")
  wpctl set-volume "$target" 5%-
  ;;
"mute")
  wpctl set-mute "$target" toggle
  ;;
esac
