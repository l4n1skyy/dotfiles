# Overwrite parts of the fuck-omarchy-menu with user-specific submenus.
# See $FUCK_OMARCHY_PATH/bin/fuck-omarchy-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when fuck-omarchy changes.
#
# Example of minimal system menu:
#
# show_system_menu() {
#   case $(menu "System" "  Lock\n󰐥  Shutdown") in
#   *Lock*) fuck-omarchy-lock-screen ;;
#   *Shutdown*) fuck-omarchy-system-shutdown ;;
#   *) back_to show_main_menu ;;
#   esac
# }
#
# Example of overriding just the about menu action: (Using zsh instead of bash (default))
#
# show_about() {
#   exec fuck-omarchy-launch-or-focus-tui "zsh -c 'fastfetch; read -k 1'"
# }
