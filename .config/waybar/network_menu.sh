#!/bin/bash

# Define options
entries="Wifi Off\nWifi On\nnmtui\nNetwork Settings"

# Show menu and get selection
selected=$(echo -e "$entries" | wofi --pid $$ --dmenu --cache-file /dev/null --prompt "Network Menu" --width 300 --height 200)

case $selected in
    "Wifi Off")
        nmcli radio wifi off
        ;;
    "Wifi On")
        nmcli radio wifi on
        ;;
    "nmtui")
        # Launch nmtui in a terminal (using foot as per user preference)
        foot -e nmtui
        ;;
    "Network Settings")
        nm-connection-editor
        ;;
esac
