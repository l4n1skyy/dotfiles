#!/bin/bash

if fo-shell idle toggle; then
    notify-send "Idle lock" "Toggled" -i weather-clear
else
    notify-send "Idle lock" "fuck-omarchy shell is unavailable" -i dialog-error
    exit 1
fi
