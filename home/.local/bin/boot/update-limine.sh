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

reorder_windows_before_snapshots() {
	local reordered_config
	reordered_config=$(mktemp)
	awk '
	{
		line[NR] = $0
		if (!snapshots_line && ($0 ~ /^[[:space:]]+\/\/Snapshots$/ || $0 == "/+Snapshots")) {
			snapshots_line = NR
		}
	}
	END {
		if (!snapshots_line) {
			for (i = 1; i <= NR; i++) print line[i]
			exit
		}

		snapshots_end = NR + 1
		for (i = snapshots_line + 1; i <= NR; i++) {
			if (line[i] ~ /^\/[^\/]/) {
				snapshots_end = i
				break
			}
		}

		for (i = 1; i < snapshots_line; i++) print line[i]
		for (i = snapshots_end; i <= NR; i++) print line[i]

		# Keep the limine-snapper-sync snapshot entries exactly as it wrote them;
		# rewriting them breaks its bookkeeping and drops linux-omarchy snapshots.
		print "/+Snapshots"
		for (i = snapshots_line + 1; i < snapshots_end; i++) {
			if (line[i] !~ /^[[:space:]]*$/) print line[i]
		}
	}
	' "$temporary_config" > "$reordered_config" || {
		rm -f "$reordered_config"
		notify_failure "Could not order the Limine entries."
		exit 1
	}
	mv "$reordered_config" "$temporary_config"
}

remove_standard_linux_entry() {
	local filtered_config
	filtered_config=$(mktemp)
	awk '
function flush_entry() {
	if (!header_printed) {
		for (i = 1; i < entry_start; i++) print line[i]
		header_printed = 1
	}
	if (!entry_start || !standard_linux) {
		for (i = entry_start; i < NR; i++) print line[i]
	}
}
{
	if ($0 ~ /^\/[^\/]/) {
		if (entry_start) flush_entry()
		entry_start = NR
		standard_linux = 0
		in_os = ($0 == "/+OS")
	} else if (in_os && $0 ~ /^  \//) {
		if (entry_start) flush_entry()
		entry_start = NR
		standard_linux = 0
	}
	line[NR] = $0
	if (in_os && entry_start && $0 ~ /^  comment: kernel-id=linux[[:space:]]*$/) {
		standard_linux = 1
	}
}
END {
	if (entry_start) {
		if (!header_printed) {
			for (i = 1; i < entry_start; i++) print line[i]
		}
		if (!standard_linux) {
			for (i = entry_start; i <= NR; i++) print line[i]
		}
	} else {
		for (i = 1; i <= NR; i++) print line[i]
	}
}
' "$temporary_config" > "$filtered_config" || {
	rm -f "$filtered_config"
	notify_failure "Could not remove the standard Linux entry."
	exit 1
}
	mv "$filtered_config" "$temporary_config"
}

if ! grep -qF '/+Omarchy' "$config"; then
	awk '
	{
		if ($0 ~ /^default_entry:/) {
				print "default_entry: 2"
		} else if ($0 == "  //Omarchy") {
			omarchy_entry = 1
			print "  //Arch Linux"
		} else if ($0 == "  //Arch Linux" && !omarchy_entry) {
			omarchy_entry = 1
			print "  //Arch Linux"
		} else if ($0 == "  //linux-omarchy") {
			omarchy_entry = 1
			print "  //Arch Linux"
		} else if ($0 == "  //linux") {
			print "  //Arch Linux"
		} else if (arch_entry && $0 ~ /^[[:space:]]*$/) {
			next
		} else {
			print
		}
		if ($0 == "  //Omarchy" || $0 == "  //Arch Linux" || $0 == "  //linux-omarchy" || $0 == "  //linux") {
			arch_entry = 1
		}
	}
	' "$config" > "$temporary_config" || {
		notify_failure "Could not normalize the Limine entries."
		exit 1
	}
	remove_standard_linux_entry
	reorder_windows_before_snapshots
	install_config
	exit 0
fi

awk '
{
	line[NR] = $0
	if ($0 == "/+Omarchy") {
		omarchy_line = NR
	}
	if (omarchy_line && NR > omarchy_line && $0 ~ /^[[:space:]]+\/\/linux(-omarchy)?$/ && !linux_start) {
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
	if (!linux_end) {
		linux_end = NR + 1
	}

	if (!arch_line || !windows_line || !linux_start || !linux_end || arch_line >= windows_line) {
		exit 1
	}

	for (i = 1; i < arch_line; i++) {
		if (line[i] ~ /^default_entry:/) {
			print "default_entry: 2"
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

remove_standard_linux_entry
reorder_windows_before_snapshots

if grep -q '^/+Omarchy$' "$temporary_config"; then
	notify_failure 'The generated Omarchy section was not removed.'
	exit 1
fi

install_config