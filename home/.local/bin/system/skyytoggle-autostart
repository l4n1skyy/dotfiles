#!/bin/bash
# Use the same name everywhere: disable_autostart
FLAG="$HOME/.cache/disable_autostart"

if [ -f "$FLAG" ]; then
    rm "$FLAG"
    # Added '|| true' so the script doesn't crash if notify-send fails
    notify-send "Startup Apps" "Enabled for next login" -i software-update-available || true
else
    touch "$FLAG"
    notify-send "Startup Apps" "Disabled for next login" -i dialog-warning || true
fi
