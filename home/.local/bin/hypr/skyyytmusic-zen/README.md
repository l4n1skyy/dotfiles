# skyyytmusic-zen (backup, not in use)

YouTube Music in its own **Zen Browser** window, with a like button in the bar.
This was the setup until 2026-11-22, when it was replaced by **Pear Desktop**
(`~/.local/bin/hypr/skyyytmusic`, AUR `pear-desktop-bin`). It is kept here so it
can be brought back. Everything it needs lives in this folder; nothing of it is
installed anywhere else right now (the Zen profile was deleted).

## What's in here

| File | What it does |
|---|---|
| `skyyytmusic-zen` | Launcher. Opens music.youtube.com in a separate Zen instance (profile `~/.config/zen-youtube-music`, window class `ytmusic`), without piling up tabs. `focus` jumps to the window (or opens it), `open` goes to workspace 8 first. On every start it also wires up the like-button bridge (below). |
| `skyyytlike-zen` | `skyyytlike-zen status VIDEO_ID` / `toggle VIDEO_ID`: reads or flips the like of a track. Presses the page's own like button through the bridge when the window is open, otherwise calls YouTube Music's API with the profile's login cookies. |
| `bridge/extension/` | Small unsigned Zen extension (`skyyytmusic@skyy`) that reads and clicks the like button in the page. |
| `bridge/host` | Its native messaging host: listens on `$XDG_RUNTIME_DIR/skyyytmusic.sock` for `skyyytlike-zen`. |
| `skyyytmusic-zen.desktop` | App menu entry "YouTube Music (Zen backup)". |

No WebDriver/Marionette anywhere: with it YouTube sees `navigator.webdriver = true`
and stops streaming after a minute.

## Bring it back

Needs `zen-browser` and `python3` (both normally installed).

1. **Start it once.** The profile is created by itself:

   ```bash
   ~/.local/bin/hypr/skyyytmusic-zen/skyyytmusic-zen open
   ```

   The first start makes `~/.config/zen-youtube-music` (an empty folder, which Zen
   turns into a fresh profile), points the profile at `bridge/extension`, writes
   `user.js` (allow the unsigned extension, compact mode at startup) and the native
   messaging manifest `~/.mozilla/native-messaging-hosts/skyyytmusic.json`.

2. **Sign in** to your Google account in that window. Optionally install
   [uBlock Origin](https://addons.mozilla.org/firefox/addon/ublock-origin/) in it
   (the old profile had it).

3. **App menu entry:**

   ```bash
   cp ~/.local/bin/hypr/skyyytmusic-zen/skyyytmusic-zen.desktop ~/.local/share/applications/
   ```

4. **Autostart on workspace 8** (instead of Pear): in `~/.local/bin/hypr/layout.conf`
   change the `APP ytmusic` line to

   ```
   APP ytmusic  ytmusic  /home/l4n1skyy/.local/bin/hypr/skyyytmusic-zen/skyyytmusic-zen
   ```

   then regenerate the Hyprland autostart file:

   ```bash
   ~/.local/bin/hypr/layout.sh generate
   ```

5. **Bar heart and title click** (`~/.config/quickshell/fuck-omarchy/plugins/skyymedia/BarWidget.qml`):
   the heart only shows for Pear's player (`isPear`). For Zen, make `isPear` true for
   any player (or drop the check in `videoId`), set `likeBin` to
   `~/.local/bin/hypr/skyyytmusic-zen/skyyytlike-zen`, and make the title click run
   `skyyytmusic-zen/skyyytmusic-zen focus` instead of `skyyytmusic focus`.

Keep the profile **outside** this folder: `~/.local/bin` is copied into the public
dotfiles repo, and the profile holds your Google login.

## Remove it again

```bash
rm -rf ~/.config/zen-youtube-music ~/.mozilla/native-messaging-hosts/skyyytmusic.json
rm -f ~/.local/share/applications/skyyytmusic-zen.desktop
```

and undo steps 4 and 5.
