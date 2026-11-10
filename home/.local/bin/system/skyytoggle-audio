#!/bin/bash
# Toggle between laptop speakers and SonicGear (headphone jack) output
# Usage: toggle-audio-output.sh

CARD=2

HEADPHONE_STATE=$(amixer -c $CARD sget 'Headphone' | grep -o '\[on\]\|\[off\]' | head -1)

if [ "$HEADPHONE_STATE" = "[on]" ]; then
    # Currently on SonicGear -> switch to laptop speakers
    amixer -c $CARD sset 'Headphone' mute
    amixer -c $CARD sset 'Speaker' unmute
    notify-send "Audio Output" "Switched to Laptop Speakers" -i audio-speakers
else
    # Currently on laptop speakers -> switch to SonicGear
    amixer -c $CARD sset 'Speaker' mute
    amixer -c $CARD sset 'Headphone' unmute
    notify-send "Audio Output" "Switched to SonicGear Speakers" -i audio-headphones
fi
