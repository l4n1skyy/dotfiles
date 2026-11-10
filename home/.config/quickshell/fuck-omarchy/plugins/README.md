# First-party plugins

These plugins ship with fuck-omarchy and are discovered by the shell at startup.
They use the same `manifest.json` contract as third-party plugins; the
only difference is that the shell flags them with `__isFirstParty: true`.
First-party non-bar plugins are enabled unless listed in `disabledPlugins[]`;
`fuck-omarchy.bar` is the default bar option and becomes inactive only while another
`kind: "bar"` plugin is selected. Services and keep-loaded panels are mounted
at startup; other panels, overlays, and menus are loaded on demand.

User-installed plugins live alongside these conceptually but on disk under
`~/.config/fuck-omarchy/plugins/<plugin-id>/` rather than in this directory.

| Plugin        | id                        | kinds                   | entry point                           |
|---------------|---------------------------|-------------------------|---------------------------------------|
| Bar           | `fuck-omarchy.bar`             | `bar`                   | `bar/Bar.qml`                         |
| Image picker  | `fuck-omarchy.image-picker`    | `overlay`               | `image-picker/ImagePicker.qml`        |
| Emojis        | `fuck-omarchy.emojis`          | `overlay`               | `emojis/Emojis.qml`                   |
| Clipboard mgr | `fuck-omarchy.clipboard`       | `overlay`               | `clipboard/Clipboard.qml`             |
| Reminders     | `fuck-omarchy.reminders`       | `overlay`               | `reminders/ReminderFlow.qml`          |
| fuck-omarchy menu  | `fuck-omarchy.menu`            | `menu`, `bar-widget`    | `menu/Menu.qml`, `menu/BarWidget.qml` |
| Notifications | `fuck-omarchy.notifications`   | `service`               | `notifications/Service.qml`           |
| Audio         | `fuck-omarchy.audio`           | `bar-widget`            | `audio/Panel.qml`              |
| Bluetooth     | `fuck-omarchy.bluetooth`       | `bar-widget`            | `bluetooth/Panel.qml`          |
| Clock         | `fuck-omarchy.clock`           | `bar-widget`            | `clock/BarWidget.qml`          |
| Monitor       | `fuck-omarchy.monitor`         | `bar-widget`            | `monitor/Panel.qml`            |
| Network       | `fuck-omarchy.network`         | `bar-widget`            | `network/Panel.qml`            |
| Power         | `fuck-omarchy.power`           | `bar-widget`            | `power/Panel.qml`              |
| Tailscale     | `fuck-omarchy.tailscale`       | `bar-widget`            | `tailscale/Panel.qml`          |
| Agents   | `fuck-omarchy.agents`     | `bar-widget`            | `agents/Panel.qml`               |
| Weather       | `fuck-omarchy.weather`         | `bar-widget`            | `weather/BarWidget.qml`        |
| Media         | `fuck-omarchy.media`           | `service`, `bar-widget` | `media/Service.qml`, `media/BarWidget.qml` |
| Battery       | `fuck-omarchy.battery`         | `service`               | `battery/Service.qml`        |
| Idle          | `fuck-omarchy.idle`            | `service`               | `idle/Service.qml`           |
| Night light   | `fuck-omarchy.nightlight`      | `service`               | `nightlight/Service.qml`     |
| Lock screen   | `fuck-omarchy.lock`            | `service`               | `lock/Service.qml`                    |
| OSD           | `fuck-omarchy.osd`             | `panel`                 | `osd/Osd.qml`                         |
| Polkit agent  | `fuck-omarchy.polkit`          | `service`               | `polkit/PolkitAgent.qml`              |

First-party bar-only widgets also carry manifests next to their QML files,
e.g. `bar/widgets/Workspaces.manifest.json`. Rich popup widgets live in their
own plugin directories, each with its own `manifest.json`.

## Bar

The built-in status bar and default full-bar option. Layout lives in the
top-level `bar:` subtree of `~/.config/fuck-omarchy/shell.json` (with the shell
providing [`config/fuck-omarchy/shell.json`](../../config/fuck-omarchy/shell.json) when
the user has no file). See [`bar/README.md`](bar/README.md) for the widget catalogue
and customization schema.

## Image picker

Fullscreen image-grid selector overlay. Used by `fuck-omarchy-menu-images`
(wallpaper picker) and `fuck-omarchy-theme-switcher` (theme picker) and any
other caller that wants to present a directory of images with previews.

Two ways to drive it:

- Shell-level summon: `fuck-omarchy-shell shell summon fuck-omarchy.image-picker '<jsonPayload>'`.
  The payload can carry `imageDirs`, `imageRows`, `selectedImage`,
  `selectionFile`, `doneFile`, `showLabels`, `filterable`. Best for
  in-shell callers that already speak JSON.
- Direct IPC target: `fuck-omarchy-shell image-selector open <imageDirs> <imageRowsB64> <selectedImage> <selectionFile> <doneFile> <showLabels> <filterable>`.
  Positional args; `imageRowsB64` is base64-encoded so embedded newlines /
  tabs survive the bash argv handoff. This is what `fuck-omarchy-menu-images`
  uses. Colors come from the central shell theme singleton; there is no
  per-call override surface.

The selection round-trip remains file-based: callers create a
`selection_file` and `done_file` (both `mktemp`), pass the paths, and
poll `done_file` for existence. The plugin writes the chosen path into
`selection_file` and touches `done_file` when it's done. `cancel` IPC
clears it without writing a selection.

The plugin has `keepLoaded: true` so the layer-shell window survives
between summons within a single shell session.

## Lock screen

Session-lock surface using Quickshell's native `WlSessionLock` and two
separate PAM services: `fuck-omarchy-lock-password` for password auth and,
only when fingerprints are enrolled, `fuck-omarchy-lock-fingerprint` for
fingerprint auth. It mirrors the previous lock screen field dimensions,
colors, blurred wallpaper, placeholder, and Hyprland-driven corners.
The plugin sets `keepLoaded: true` so a plugin hot-reload (for example
an installed bar widget changing on disk) does not destroy the lock
client while Hyprland still holds the session lock.

## Polkit agent

Theme-aware authentication dialog for privileged actions. It uses
Quickshell's native `Quickshell.Services.Polkit.PolkitAgent` backend and
runs inside the long-lived `fuck-omarchy-shell` process, replacing the old
`polkit-gnome-authentication-agent-1` autostart.

## fuck-omarchy menu

Quickshell-powered fuck-omarchy command menu.
The menu UI lives in `menu/Menu.qml` as a first-party `menu` plugin and is
summoned through the shell (`fuck-omarchy-shell shell summon fuck-omarchy.menu ...`),
so it shares the long-running `fuck-omarchy-shell` process instead of starting a
second Quickshell instance.

The menu definition lives outside the shell host code:

- defaults: `default/fuck-omarchy/fuck-omarchy-menu.jsonc`
- user extensions: `~/.config/fuck-omarchy/extensions/fuck-omarchy-menu.jsonc`

The shell parses both JSONC files at startup (with `watchChanges: true`
so edits take effect without a restart), evaluates `when:` / `checked:`
bash expressions in a single batched subprocess, and executes the
selected `action:` string directly via `Quickshell.execDetached`. The
long-running shell process keeps the parsed menu in memory, so the
keybind → IPC → visible path costs ~30ms cold.

## Coming soon

- `fuck-omarchy.theme-switcher` — folds theme switching into the shell.
