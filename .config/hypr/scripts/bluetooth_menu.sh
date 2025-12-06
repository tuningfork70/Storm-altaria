#!/bin/bash

# 1. Check if Bluetooth is powered on
power_state=$(bluetoothctl show | grep "Powered: yes")

if [ -z "$power_state" ]; then
    # If OFF, show only "Turn On"
    option=$(echo -e "  Turn Bluetooth On" | wofi --dmenu --prompt "Bluetooth is OFF" --height 100)
    if [ "$option" == "  Turn Bluetooth On" ]; then
        bluetoothctl power on
        notify-send "Bluetooth" "Powered ON"
    fi
    exit
fi

# 2. Get list of Paired Devices (MAC + Name)
# Format: "MAC Address  Name"
devices=$(bluetoothctl devices | cut -d ' ' -f 2-)

# 3. Add a "Turn Off" option at the top
options="  Turn Bluetooth Off\n$devices"

# 4. Show the Menu
selected=$(echo -e "$options" | wofi --dmenu --prompt "Bluetooth Devices" --height 300 --width 400)

# 5. Handle Selection
if [ "$selected" == "  Turn Bluetooth Off" ]; then
    bluetoothctl power off
    notify-send "Bluetooth" "Powered OFF"
    exit
fi

# If a device was picked
if [ ! -z "$selected" ]; then
    # Extract MAC address (First word)
    mac=$(echo "$selected" | awk '{print $1}')

    # Check if currently connected
    if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
        bluetoothctl disconnect "$mac"
        notify-send "Bluetooth" "Disconnected"
    else
        notify-send "Bluetooth" "Connecting..."
        bluetoothctl connect "$mac"
    fi
fi
