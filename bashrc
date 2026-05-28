# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

export PATH=$PATH:/home/l4n1skyy/.spicetify
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"
export JAVA_HOME=/usr/lib/jvm/default
export PATH=$JAVA_HOME/bin:$PATH

alias bottles='flatpak run com.usebottles.bottles'
unalias ff 2>/dev/null
alias nv='nvim'
alias ccc='cc -Wall -Wextra -Werror'
alias p='python3'

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

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'micromamba shell init' !!
export MAMBA_EXE='/usr/bin/micromamba';
export MAMBA_ROOT_PREFIX='/home/l4n1skyy/.local/share/mamba';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"  # Fallback on help from micromamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
