#!/usr/bin/env bash
set -euo pipefail

# Toggle mute only for Spotify sink inputs (does not touch system output mute).
if ! command -v pactl >/dev/null 2>&1; then
  exit 0
fi

mapfile -t spotify_inputs < <(
  pactl list sink-inputs | awk '
    /^Sink Input #[0-9]+/ {
      id = $3
      sub("#", "", id)
    }
    /application.name = / {
      line = tolower($0)
      if (line ~ /spotify/) {
        print id
      }
    }
    /application.process.binary = / {
      line = tolower($0)
      if (line ~ /spotify/) {
        print id
      }
    }
  ' | sort -u
)

if [[ ${#spotify_inputs[@]} -eq 0 ]]; then
  exit 0
fi

for input_id in "${spotify_inputs[@]}"; do
  current_state="$(pactl get-sink-input-mute "$input_id" | awk '{print $2}')"
  if [[ "$current_state" == "yes" ]]; then
    pactl set-sink-input-mute "$input_id" 0
  else
    pactl set-sink-input-mute "$input_id" 1
  fi
done
