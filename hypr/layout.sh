#!/bin/bash

# --- 1. THE GUARD ---
# Wait for core apps to exist.
while ! hyprctl clients | grep -q "class: org.omarchy.nvim"; do sleep 0.2; done
while ! hyprctl clients | grep -q "class: obsidian"; do sleep 0.2; done
while ! hyprctl clients | grep -q "class: cbonsai-term"; do sleep 0.2; done
while ! hyprctl clients | grep -q "class: timr-term"; do sleep 0.2; done

# --- 2. WORKSPACE 10: SOCIAL ---
hyprctl dispatch workspace 10
sleep 0.5
hyprctl dispatch focuswindow "class:^vesktop$"
hyprctl dispatch togglegroup
sleep 0.2
hyprctl dispatch focuswindow "class:^Spotify$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done

# --- 3. WORKSPACE 9: PRODUCTIVITY (UNTOUCHED STRINGS) ---
hyprctl dispatch workspace 9
sleep 0.5
# Wake-up Poke
hyprctl dispatch focuswindow "class:^chrome-app\.todoist\.com__app-Default$"
sleep 0.3
hyprctl dispatch focuswindow "class:^chrome-calendar\.google\.com__-Default$"
sleep 0.3
# Grouping Anchor
hyprctl dispatch focuswindow "class:^obsidian$"
hyprctl dispatch togglegroup
sleep 0.2
# Brute Force Join
hyprctl dispatch focuswindow "class:^chrome-app\.todoist\.com__app-Default$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done
hyprctl dispatch focuswindow "class:^chrome-calendar\.google\.com__-Default$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done
# Final focus
hyprctl dispatch focuswindow "class:^obsidian$"

# --- 4. WORKSPACE 1: THE DASHBOARD ---
hyprctl dispatch workspace 1
sleep 0.5

# Force Positions
hyprctl dispatch focuswindow "class:^org\.omarchy\.nvim$"
hyprctl dispatch movewindow r
sleep 0.1

hyprctl dispatch focuswindow "class:^timr-term$"
hyprctl dispatch movewindow l
hyprctl dispatch movewindow u
sleep 0.1

hyprctl dispatch focuswindow "class:^cbonsai-term$"
hyprctl dispatch movewindow l
hyprctl dispatch movewindow d
sleep 0.1

# RATIO: timr is now a tiny bit shorter (-200)
hyprctl dispatch focuswindow "class:^timr-term$"
hyprctl dispatch resizeactive 0 -200
sleep 0.1

# WIDTH: Shrink the dashboard side
hyprctl dispatch focuswindow "class:^cbonsai-term$"
hyprctl dispatch moveoutofgroup
sleep 0.1
hyprctl dispatch resizeactive -600 0 

# --- 5. MAIN LANDING ---
hyprctl dispatch focuswindow "class:^org\.omarchy\.nvim$"

# --- 6. THE BEEPER NINJA (BACKGROUND) ---
(
    while ! hyprctl clients | grep -q "class: BeeperTexts"; do sleep 1; done
    hyprctl dispatch workspace 10
    sleep 0.2
    hyprctl dispatch focuswindow "class:^BeeperTexts$"
    for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done
    hyprctl dispatch focuswindow "class:^BeeperTexts$"
    hyprctl dispatch workspace 1
    hyprctl dispatch focuswindow "class:^org\.omarchy\.nvim$"
) &
