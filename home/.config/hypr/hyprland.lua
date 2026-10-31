-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- fuck-omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("FO_PATH") or (os.getenv("HOME") .. "/.local/share/fuck-omarchy")) .. "/default/hypr/bootstrap.lua")

-- Disable all fuck-omarchy default bindings. Add your own in hypr/bindings.lua.
-- fo_default_bindings = false
--
-- Or disable only bindings for fuck-omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- fo_preinstalled_bindings = false

-- Load fuck-omarchy defaults.
require("default.hypr.fo")

-- Put your personal overrides in these files. They're loaded after fuck-omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.groupbar")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
