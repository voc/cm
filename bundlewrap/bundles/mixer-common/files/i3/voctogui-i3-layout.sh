#!/usr/bin/env bash

WINDOWS=$(xdotool search --all --onlyvisible --desktop $(xprop -notype -root _NET_CURRENT_DESKTOP | cut -c 24-) "" 2>/dev/null)

for window in $WINDOWS; do
    xdotool windowunmap "$window"
done

i3-msg "append_layout $HOME/.config/i3/layout.json"

for window in $WINDOWS; do
    xdotool windowmap "$window"
done
