#!/bin/bash
# Manual toggle for the internal panel, bound to $mainMod+F7.
# Delegates to lid.sh so the mode/scale live in exactly one place.
exec "$(dirname "$(readlink -f "$0")")/lid.sh" toggle
