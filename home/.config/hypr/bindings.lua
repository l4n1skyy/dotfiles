for _, keys in ipairs({
	"SUPER + RETURN",
	"SUPER + ALT + RETURN",
	"SUPER + SHIFT + RETURN",
	"SUPER + SHIFT + ALT + B",
	"SUPER + SHIFT + F",
	"SUPER + ALT + SHIFT + F",
	"SUPER + SHIFT + N",
	"SUPER + SHIFT + E",
	"SUPER + SHIFT + O",
	"SUPER + ALT + A",
	"SUPER + L",
	"SUPER + F10",
	"SUPER + ALT + I",
}) do
	hl.unbind(keys)
end

o.bind("SUPER + RETURN", "Terminal", "uwsm-app -- xdg-terminal-exec --dir=\"$(omarchy-cmd-terminal-cwd)\"")
o.bind(
	"SUPER + ALT + RETURN",
	"Tmux",
	"uwsm-app -- xdg-terminal-exec --dir=\"$(omarchy-cmd-terminal-cwd)\" bash -c \"tmux attach || tmux new -s Work\""
)
o.bind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + F", "File manager", "uwsm-app -- nautilus --new-window")
o.bind(
	"SUPER + ALT + SHIFT + F",
	"File manager (cwd)",
	"uwsm-app -- nautilus --new-window \"$(omarchy-cmd-terminal-cwd)\""
)
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
o.bind(
	"SUPER + SHIFT + E",
	"Beeper",
	"omarchy-launch-or-focus ^beeper$ \"uwsm-app -- beeper\""
)
o.bind(
	"SUPER + SHIFT + O",
	"Obsidian",
	"omarchy-launch-or-focus ^obsidian$ \"uwsm-app -- obsidian\""
)
o.bind("SUPER + ALT + A", "Toggle Autostart", "~/.local/bin/system/toggle-autostart.sh")
o.bind("SUPER + L", "Lock System", "hyprlock")
o.bind("SUPER + F10", nil, "~/.local/bin/system/toggle-audio.sh")
o.bind("SUPER + ALT + I", "Toggle Idle Lock", "~/.local/bin/system/toggle-idle.sh")
o.bind(
	"SUPER + ALT + SHIFT + L",
	"Update Limine",
	"uwsm-app -- xdg-terminal-exec -- bash -lc '~/.local/bin/boot/update-limine.sh'"
)
o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
