# Modularity

This folder is a complete Quickshell config (a *shell profile*). Everything
visible is a plugin in `plugins/<name>/`: the bar, the menu, notifications, the
OSD, the lock screen, the polkit dialog, every panel. One plugin is one folder
with a `manifest.json`; delete or replace the folder and nothing else changes.

```
shell.qml        host: loads plugins, nothing visual of its own
services/        plugin registry and the scoped APIs plugins get
plugins/<name>/  one folder per plugin (bar, menu, notifications, osd, lock, polkit, ...)
Commons/ Ui/     the kit: shared colors/typography and widgets (optional, see below)
```

## Rules (checked by `fuck-omarchy-shell-audit`)

1. **No plugin reaches into another plugin's folder.** No imports or relative
   paths across `plugins/*`.
2. **Plugins find each other by capability, not by id.** A plugin lists what it
   implements and what it calls in its manifest:

   ```json
   "fuck_omarchy": { "provides": ["notifications"], "uses": ["osd"] }
   ```

   Callers write `shell.summon("osd", ...)` or `firstPartyServiceFor("notifications")`.
   The host routes the call to whichever enabled plugin provides that capability
   (`PluginRegistry.capabilityProvider`). A plugin you installed beats a built-in
   one, and a clone of a built-in (`fuck-omarchy-plugin-clone`) still takes over
   its original's calls. So swapping the notification daemon, the OSD or the
   media service means dropping in a plugin that `provides` the same capability.
   `uses` is also the allow-list for what a clone may summon; it is read from the
   built-in source, never from the clone.
3. **Shared look comes only from the kit.** `qs.Commons` (Colors, Style, Util,
   Border) and `qs.Ui` (buttons, panels, sliders...). A plugin that imports
   neither is kit-free and runs unchanged in any profile; the audit shows which.

## Capabilities today

| capability | provided by | typed interface |
| --- | --- | --- |
| `idle` | `skyyidle` | `setIdleEnabled`, `stayAwake` |
| `notifications` | `skyynotifications` | `setDoNotDisturb`, `doNotDisturb` |
| `nightlight` | `fuck-omarchy.nightlight` | `setNightlight`, `enabled` |
| `media` | `fuck-omarchy.media` | `runAction`, `activePlayer`, `sourcePlayers`, `playerKey`, `selectPlayer` |
| `osd` | `fuck-omarchy.osd` | summon with `{icon, message}` |
| `wifiqr` | `fuck-omarchy.wifiqr` | summon with a connection payload |
| `battery` | `fuck-omarchy.battery` | |
| `speedtest` | (none; the network panel's button does nothing until a plugin provides it) | |

The first four are the typed service proxies the bar may use
(`PluginFirstPartyServiceApi`); a new one is added to `serviceContracts` in
`shell.qml` and to that proxy.

## Swapping things

- **One component** (bar, menu, notifications...): `fuck-omarchy-plugin-clone <id>`,
  edit your copy, enable it. Callers keep working because of rule 2.
- **The whole shell:** `fuck-omarchy-shell-profile new <name>` (or drop any
  Quickshell config into `~/.config/quickshell/<name>/`), then
  `fuck-omarchy-shell-profile use <name>` and `fuck-omarchy-shell-profile back`.
  Your settings stay in `~/.config/fuck-omarchy`, so nothing is lost either way.
