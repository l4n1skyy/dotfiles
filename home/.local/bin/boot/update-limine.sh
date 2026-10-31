#!/usr/bin/env bash
# Re-apply the custom Limine boot menu:
#   OS:        CachyOS (CachyOS BORE kernel, default), Arch Linux (Arch kernel), Windows
#   Snapshots: snapshot-latest
# The same two root hooks run automatically after every kernel or snapshot update
# (/etc/boot/hooks/post.d/); this is the manual trigger (SUPER+ALT+SHIFT+L / update-limine).

set -euo pipefail

config=/boot/limine.conf
hooks=(/etc/boot/hooks/post.d/40-menu-layout /etc/boot/hooks/post.d/50-snapshot-latest)

notify() { notify-send "$@" 2>/dev/null || true; }

for hook in "${hooks[@]}"; do
	if [[ ! -x $hook ]]; then
		notify -u critical 'Limine update failed' "Missing hook: $hook"
		exit 1
	fi
done

# Try it on a copy first, so sudo is only needed when something actually changes
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
cp "$config" "$workdir/limine.conf"
for hook in "${hooks[@]}"; do "$hook" "$workdir/limine.conf" >/dev/null; done

if cmp -s "$config" "$workdir/limine.conf"; then
	notify 'Limine update' 'Limine is already up to date.'
	exit 0
fi

for hook in "${hooks[@]}"; do sudo "$hook"; done
notify 'Limine updated' 'The Limine configuration was updated successfully.'
