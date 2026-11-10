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

o.bind("SUPER + RETURN", "Terminal", "uwsm-app -- xdg-terminal-exec --dir=\"$(fuck-omarchy-cmd-terminal-cwd)\"")
o.bind(
	"SUPER + ALT + RETURN",
	"Tmux",
	"uwsm-app -- xdg-terminal-exec --dir=\"$(fuck-omarchy-cmd-terminal-cwd)\" bash -c \"tmux attach || tmux new -s Work\""
)
o.bind("SUPER + SHIFT + RETURN", "Browser", "fuck-omarchy-launch-browser")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "fuck-omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + F", "File manager", "uwsm-app -- nautilus --new-window")
o.bind(
	"SUPER + ALT + SHIFT + F",
	"File manager (cwd)",
	"uwsm-app -- nautilus --new-window \"$(fuck-omarchy-cmd-terminal-cwd)\""
)
o.bind("SUPER + SHIFT + N", "Editor", "fuck-omarchy-launch-editor")
o.bind(
	"SUPER + SHIFT + E",
	"Beeper",
	"fuck-omarchy-launch-or-focus ^beeper$ \"uwsm-app -- beeper\""
)
o.bind(
	"SUPER + SHIFT + O",
	"Obsidian",
	"fuck-omarchy-launch-or-focus ^obsidian$ \"uwsm-app -- obsidian\""
)
o.bind("SUPER + ALT + A", "Toggle Autostart", "skyytoggle-autostart")
o.bind("SUPER + L", "Lock System", "fuck-omarchy-system-lock")
o.bind("SUPER + F10", "Toggle audio output", "skyytoggle-audio")
o.bind("SUPER + ALT + I", "Toggle Idle Lock", "skyytoggle-idle")
o.bind(
	"SUPER + ALT + SHIFT + L",
	"Update Limine",
	"uwsm-app -- xdg-terminal-exec -- bash -lc 'skyylimine'"
)
o.bind("SUPER + CTRL + U", "Update everything", "fuck-omarchy-launch-floating-terminal-with-presentation fuck-omarchy-update-all")
o.bind("SUPER + PERIOD", "Emoji picker", "fuck-omarchy-shell shell toggle fuck-omarchy.emojis")
o.bind("SUPER + ALT + P", "Pomoru (workspace 7)", "~/.local/bin/desktop/skyypomoru")
