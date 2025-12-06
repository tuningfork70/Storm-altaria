#!/bin/bash

# 1. Get List of Devices using JSON (Fail-proof)
# We format it as: "ID  Description"
options=$(pactl -f json list sinks | jq -r '.[] | "\(.index)  \(.description)"')

# 2. Open Wofi
selected=$(echo "$options" | wofi --dmenu --prompt "Select Audio Output" --height 250 --width 400)

if [ ! -z "$selected" ]; then
    # 3. Extract the ID (First number)
    id=$(echo "$selected" | awk '{print $1}')

    # 4. Set Default using BOTH tools (Double tap)
    pactl set-default-sink "$id"
    wpctl set-default "$id"

    # 5. Force Move Audio Streams
    # Moves every playing app to the new ID
    pactl list short sink-inputs | awk '{print $1}' | while read stream; do
        pactl move-sink-input "$stream" "$id"
    done

    # 6. Save the ID for the Volume Script
    echo "$id" > ~/.config/hypr/scripts/current_sink

    notify-send "Audio" "Switched to ID: $id"
fi
