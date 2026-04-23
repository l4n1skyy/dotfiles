# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

export TODOIST_API_TOKEN=9578404adc84d0349408742d3558f33699a60a98

export PATH=$PATH:/home/l4n1skyy/.spicetify

alias bottles='flatpak run com.usebottles.bottles'

unalias ff 2>/dev/null

alias nv='nvim'

ff() {
  case "$1" in
    -p) ~/.local/bin/fastfetch-pokemon ;;
    -a) ~/.local/bin/fastfetch-anime ;;
    *)  ~/.local/bin/fastfetch-pokemon ;;
    #*)  command fastfetch "$@" ;;
  esac
}

function cdd {
  local SEARCH_PATHS="$HOME /mnt/shared"

  if [ -z "$1" ]; then
    # fd -t d means "type directory", -H means "include hidden"
    local target=$(fd -t d -H . $SEARCH_PATHS 2>/dev/null | fzf)
    [ -n "$target" ] && cd "$target"
  else
    local target=$(fd -t d -H . $SEARCH_PATHS 2>/dev/null | fzf -f "$1" | head -n 1)
    if [ -n "$target" ]; then
      cd "$target"
    else
      echo "cdd: No directory found matching '$1'"
    fi
  fi
}

alias ccc='cc -Wall -Wextra -Werror'

# Pyenv Setup
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
