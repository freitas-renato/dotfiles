#!/bin/bash
# Lid handler for Hyprland.
#
# WHY THIS EXISTS
# Closing the lid on this laptop changes NOTHING in DRM or Hyprland. Verified by
# logging a full lid cycle: the connector stays "connected/enabled" and Hyprland
# keeps eDP-1 enabled the entire time the lid is shut. Only the embedded controller
# cuts the panel backlight, and that is invisible to DRM.
#
# The consequence is that Hyprland keeps treating the internal panel as a live
# output while the lid is closed, so focus and new windows can land on a screen you
# physically cannot see (observed: "focusedmon>>eDP-1,5" with the lid shut).
#
# So we disable the output explicitly on close and restore it on open.
#
# Called from hyprland.conf:
#   bindl = , switch:on:Lid Switch,  exec, .../lid.sh close
#   bindl = , switch:off:Lid Switch, exec, .../lid.sh open

set -u

INTERNAL="eDP-1"
MODE="1920x1080@144Hz"
POSITION="auto"
SCALE="1"

LOGFILE="/tmp/hypr-lid.log"
log() { printf '%s lid.sh: %s\n' "$(date +%T)" "$*" >>"$LOGFILE"; }

# Is the internal panel currently disabled? (`monitors all` includes disabled ones;
# select by name so an unrelated disabled output like HDMI-A-5 can't confuse us.)
# NOTE: do not write `.disabled // "true"` here -- jq's `//` treats a literal `false`
# as empty, so an enabled panel would wrongly report as disabled. Branch explicitly.
internal_disabled() {
    [ "$(hyprctl monitors all -j | jq -r --arg i "$INTERNAL" \
        '[.[] | select(.name == $i)]
         | if length == 0 then "true" else (.[0].disabled | tostring) end')" = "true" ]
}

# Count live outputs that are NOT the internal panel. `monitors` (no `all`) lists
# only enabled ones, which is exactly what we want here.
other_outputs() {
    hyprctl monitors -j | jq --arg i "$INTERNAL" '[.[] | select(.name != $i)] | length'
}

enable_internal() {
    hyprctl keyword monitor "$INTERNAL,$MODE,$POSITION,$SCALE"
}

disable_internal() {
    hyprctl keyword monitor "$INTERNAL,disable"
}

case "${1:-}" in
close)
    others="$(other_outputs)"
    if [ "${others:-0}" -gt 0 ]; then
        disable_internal
        log "lid closed, ${others} other output(s) live -> disabled $INTERNAL"
    else
        # Refuse to leave the machine with zero usable screens.
        log "lid closed but $INTERNAL is the only output -> leaving it enabled"
    fi
    ;;
open)
    enable_internal
    log "lid opened -> enabled $INTERNAL"
    ;;
toggle)
    if internal_disabled; then
        enable_internal
        log "toggle -> enabled $INTERNAL"
    else
        disable_internal
        log "toggle -> disabled $INTERNAL"
    fi
    ;;
*)
    echo "usage: ${0##*/} {close|open|toggle}" >&2
    exit 1
    ;;
esac
