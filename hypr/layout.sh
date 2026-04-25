#!/bin/bash

# 1. Wait for the core apps (Nvim, Obsidian, Zen) to exist
while ! hyprctl clients | grep -q "class: org.omarchy.nvim"; do sleep 0.2; done
while ! hyprctl clients | grep -q "class: obsidian"; do sleep 0.2; done

# --- STEP 1: WORKSPACE 1 (DEV SETUP) ---
hyprctl dispatch workspace 1
sleep 0.5
# Focus cbonsai
hyprctl dispatch focuswindow "class:^cbonsai-term$"
# THE FIX: Force cbonsai to the left side if it ended up on the right
hyprctl dispatch movewindow l 
sleep 0.2
# Ensure it isn't swallowed, then resize
hyprctl dispatch moveoutofgroup 
sleep 0.2
# Now that it's on the left, -600 shrinks it correctly
hyprctl dispatch resizeactive -600 0 

# --- STEP 2: WORKSPACE 9 (WAKE WEB APPS & GROUP) ---
hyprctl dispatch workspace 9
sleep 0.5
# WAKE UP: Focus each to force Chromium to render
hyprctl dispatch focuswindow "class:^chrome-app\.todoist\.com__app-Default$"
sleep 0.3
hyprctl dispatch focuswindow "class:^chrome-calendar\.google\.com__-Default$"
sleep 0.3
# GROUPING: Anchor to Obsidian
hyprctl dispatch focuswindow "class:^obsidian$"
hyprctl dispatch togglegroup
sleep 0.2
# Pull web apps into Obsidian
hyprctl dispatch focuswindow "class:^chrome-app\.todoist\.com__app-Default$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done
hyprctl dispatch focuswindow "class:^chrome-calendar\.google\.com__-Default$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done
# Final focus on Obsidian for this workspace
hyprctl dispatch focuswindow "class:^obsidian$"

# --- STEP 3: WORKSPACE 10 (PARTIAL SOCIAL) ---
hyprctl dispatch workspace 10
sleep 0.5
hyprctl dispatch focuswindow "class:^vesktop$"
hyprctl dispatch togglegroup
sleep 0.2
hyprctl dispatch focuswindow "class:^Spotify$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done

# --- STEP 4: INTERIM FOCUS (Start Working) ---
# This lands you on Nvim so you can start coding while Beeper loads
hyprctl dispatch workspace 1
sleep 0.2
hyprctl dispatch focuswindow "class:^org\.omarchy\.nvim$"

# --- STEP 5: THE BEEPER WATCH ---
while ! hyprctl clients | grep -q "class: BeeperTexts"; do sleep 0.5; done

# Beeper has arrived: Quick jump to 10 to group it
hyprctl dispatch workspace 10
sleep 0.2
hyprctl dispatch focuswindow "class:^BeeperTexts$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done
# Focus Beeper as the active tab on 10
hyprctl dispatch focuswindow "class:^BeeperTexts$"

# --- STEP 6: FINAL FOCUS ---
hyprctl dispatch workspace 1
sleep 0.2
hyprctl dispatch focuswindow "class:^org\.omarchy\.nvim$"
