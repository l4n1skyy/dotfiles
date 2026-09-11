#!/usr/bin/env bash

set -euo pipefail

config=${1:-/boot/limine.conf}
temporary_config=$(mktemp)

cleanup() {
	rm -f "$temporary_config"
}
trap cleanup EXIT

notify_failure() {
	local message=$1
	notify-send -u critical 'Limine update failed' "$message" 2>/dev/null || true
}
trap 'notify_failure "The configuration was not changed."' ERR

install_config() {
	if cmp -s "$temporary_config" "$config"; then
		notify-send 'Limine update' 'Limine is already up to date.' 2>/dev/null || true
		return 0
	fi

	sudo install -m 0644 "$temporary_config" "$config"
	notify-send 'Limine updated' 'The Limine configuration was updated successfully.' 2>/dev/null || true
}

if [[ ! -r "$config" ]]; then
	notify_failure "Cannot read $config."
	exit 1
fi

if ! grep -qF '/+Omarchy' "$config"; then
	awk '
	{
		if ($0 ~ /^default_entry:/) {
			print "default_entry: OS/Arch Linux"
		} else if ($0 == "  //linux") {
			print "  //Arch Linux"
		} else if (arch_entry && $0 ~ /^[[:space:]]*$/) {
			next
		} else {
			print
		}
		if ($0 == "  //Arch Linux" || $0 == "  //linux") {
			arch_entry = 1
		}
	}
	' "$config" > "$temporary_config" || {
		notify_failure "Could not normalize the Limine entries."
		exit 1
	}
	install_config
	exit 0
fi

awk '
{
	line[NR] = $0
	if ($0 == "/+Omarchy") {
		omarchy_line = NR
	}
	if (omarchy_line && NR > omarchy_line && $0 ~ /^[[:space:]]+\/\/linux$/ && !linux_start) {
		linux_start = NR
	}
	if (linux_start && NR > linux_start && $0 ~ /^\/[^\/]/ && !linux_end) {
		linux_end = NR
	}
	if (!arch_line && $0 == "  //Arch Linux") {
		arch_line = NR
	}
	if (!windows_line && $0 ~ /^[[:space:]]*\/\/Windows$/) {
		windows_line = NR
	}
}
END {
	if (!arch_line || !windows_line || !linux_start || !linux_end || arch_line >= windows_line) {
		exit 1
	}

	for (i = 1; i < arch_line; i++) {
		if (line[i] ~ /^default_entry:/) {
			print "default_entry: OS/Arch Linux"
		} else {
			print line[i]
		}
	}
	for (i = linux_start; i < linux_end; i++) {
		if (i == linux_start) {
			print "  //Arch Linux"
		} else if (line[i] ~ /^[[:space:]]*$/) {
			continue
		} else {
			print line[i]
		}
	}
	for (i = windows_line; i < omarchy_line; i++) {
		if (line[i] ~ /^[[:space:]]*$/) {
			continue
		}
		windows_line_text = line[i]
		sub(/^[[:space:]]*/, "", windows_line_text)
		print "  " windows_line_text
	}
}
' "$config" > "$temporary_config" || {
	notify_failure "Could not find the expected Limine entries."
	exit 1
}

if grep -q '^/+Omarchy$' "$temporary_config"; then
	notify_failure 'The generated Omarchy section was not removed.'
	exit 1
fi

install_config