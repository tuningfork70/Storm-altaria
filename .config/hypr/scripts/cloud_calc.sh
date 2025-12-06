#!/bin/bash

# 1. Open Wofi to get the equation
# We use /dev/null as input so it starts empty
equation=$(echo "" | wofi --dmenu \
  --conf /dev/null \
  --style ~/.config/wofi/style.css \
  --prompt "Calculate..." \
  --height 200 \
  --width 500)

# 2. If user typed something, solve it
if [ -n "$equation" ]; then
  # Run qalc in "terse" mode (just the answer)
  result=$(qalc -t "$equation")

  # 3. Show the result in a new Wofi window
  # If they click it, copy to clipboard
  action=$(echo "$result" | wofi --dmenu \
    --conf /dev/null \
    --style ~/.config/wofi/style.css \
    --prompt "Result (Enter to Copy)" \
    --height 200 \
    --width 500)

  if [ -n "$action" ]; then
    echo "$action" | wl-copy
    notify-send "Calculator" "Copied: $action"
  fi
fi
