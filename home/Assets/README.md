# Assets

Central folder for my computer's custom assets (fuck-omarchy). Only `audio/` and `ascii/flower*.txt` are real files here; everything else is a link to the live file, so there is one copy of each.

| Folder | What | Lives in |
| --- | --- | --- |
| `audio/password/` | clips; one plays at random whenever the password popup opens (`skyysound-password`) | here |
| `logo/` | the l4n1skyy logo | Plymouth splash theme |
| `ascii/` | splash ASCII logo, flower-mini, "WELCOME L4N1SKYY" banner, flower braille art | Plymouth theme, `~/.config/limine`, here |
| `splash/` | Plymouth boot/LUKS splash (logo, flowers, entry, bullets, script) | `/usr/share/plymouth/themes/splash` (root-owned) |
| `login/` | SDDM login screen art | `~/.config/sddm/themes/cozette` |
| `lockscreen/` | art used by the shell lock screen | `shell/plugins/l4n1skyy.lock/assets` |
| `limine/` | boot menu header, wallpaper script, banner, wallpaper png | `~/.config/limine` |
| `wallpapers/`, `backgrounds/` | wallpapers | `~/.config/fuck-omarchy/` |

Drop more `.ogg/.oga/.wav/.mp3` clips in `audio/password/` and they join the rotation. Set `FUCK_OMARCHY_ASSETS` to use a different folder.
