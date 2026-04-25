#!/bin/bash
# Force a smaller, specific size so it doesn't clash with the logo
export COLUMNS=40
export LINES=15

# Generate, strip colors, and escape for Pango
# We save it to a temporary file
cbonsai -p -l -L 20 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' > /tmp/hyprlock_bonsai.txt
