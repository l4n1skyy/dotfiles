# Overwrite parts of the fo-menu with user-specific submenus.
# See $FO_PATH/bin/fo-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when fuck-omarchy changes.
#
# Example of minimal system menu:
#
# show_system_menu() {
#   case $(menu "System" "  Lock\n󰐥  Shutdown") in
#   *Lock*) fo-lock-screen ;;
#   *Shutdown*) fo-system-shutdown ;;
#   *) back_to show_main_menu ;;
#   esac
# }
#
# Example of overriding just the about menu action: (Using zsh instead of bash (default))
#
# show_about() {
#   exec fo-launch-or-focus-tui "zsh -c 'fastfetch; read -k 1'"
# }
