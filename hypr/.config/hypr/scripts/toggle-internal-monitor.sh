#!/bin/bash
INTERNAL="eDP-1"

if hyprctl monitors | grep -q "$INTERNAL"; then
    hyprctl keyword monitor "$INTERNAL,disabled"
else
    hyprctl keyword monitor "$INTERNAL,1920x1080@144Hz,auto,1"
fi
