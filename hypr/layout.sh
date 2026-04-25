#!/bin/bash

# 1. Wait for the core apps (Nvim, Obsidian, Zen) to exist
while ! hyprctl clients | grep -q "class: org.omarchy.nvim"; do sleep 0.2; done
while ! hyprctl clients | grep -q "class: obsidian"; do sleep 0.2; done

# --- STEP 1: WORKSPACE 1 (DEV SETUP) ---
hyprctl dispatch workspace 1
sleep 0.5
# Ensure cbonsai isn't swallowed, then resize
hyprctl dispatch focuswindow "class:^cbonsai-term$"
hyprctl dispatch moveoutofgroup 
sleep 0.2
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

# --- STEP 3: WORKSPACE 10 (WAIT FOR BEEPER) ---
# We do Discord and Spotify first while waiting
hyprctl dispatch workspace 10
sleep 0.5
hyprctl dispatch focuswindow "class:^vesktop$"
hyprctl dispatch togglegroup
hyprctl dispatch focuswindow "class:^Spotify$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done

# NOW we wait for Beeper to join the party
while ! hyprctl clients | grep -q "class: BeeperTexts"; do sleep 0.5; done

# Beeper has arrived: Move it into the Discord/Spotify group
hyprctl dispatch focuswindow "class:^BeeperTexts$"
for dir in l r u d; do hyprctl dispatch moveintogroup $dir; done
# Re-order focus to Beeper if you want it first in the tabs
hyprctl dispatch focuswindow "class:^BeeperTexts$"

# --- STEP 4: FINAL FOCUS ---
hyprctl dispatch workspace 1
sleep 0.2
hyprctl dispatch focuswindow "class:^org\.omarchy\.nvim$"
