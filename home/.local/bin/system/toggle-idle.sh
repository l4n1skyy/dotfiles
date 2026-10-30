#!/bin/bash

if omarchy-shell idle toggle; then
    notify-send "Idle lock" "Toggled" -i weather-clear
else
    notify-send "Idle lock" "Omarchy shell is unavailable" -i dialog-error
    exit 1
fi
