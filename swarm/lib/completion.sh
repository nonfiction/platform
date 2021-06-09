#!/bin/bash

# Source once locally if available OR via curl if not 
include() {
  [ -z "$1" ] && return 1
  if [ -e /usr/local/share/platform/swarm/$1 ]; then source /usr/local/share/platform/swarm/$1;
  elif [ -e /root/platform/swarm/$1 ]; then source /root/platform/swarm/$1;
  else source <(curl -fsSL https://github.com/nonfiction/platform/raw/main/swarm/$1); fi
}

# Bash helper functions
include "lib/helpers.sh"


# source /root/platform/swarm/lib/completion.sh
function _swarm () {

  defined $XDG_CONFIG_HOME || XDG_CONFIG_HOME=$HOME/.config
  defined $XDG_DATA_HOME || XDG_DATA_HOME=$HOME/.local/share

  local commands="create deploy edit inspect list provision remove ssh size help"
  local word="${COMP_WORDS[COMP_CWORD]}";

  # List commands
  if   [ "${#COMP_WORDS[@]}" = "2" ]; then 

      if [[ $word = c*   ]]; then commands="create"
    elif [[ $word = d*   ]]; then commands="deploy"
    elif [[ $word = e*   ]]; then commands="edit"
    elif [[ $word = h*   ]]; then commands="help"
    elif [[ $word = i*   ]]; then commands="inspect"
    elif [[ $word = l*   ]]; then commands="list"
    elif [[ $word = p*   ]]; then commands="provision"
    elif [[ $word = r*   ]]; then commands="remove"
    elif [[ $word = si*  ]]; then commands="size"
    elif [[ $word = s*   ]]; then commands="ssh"
    fi

    COMPREPLY=($commands)

  # List swarms
  elif [ "${#COMP_WORDS[@]}" = "3" ]; then 

    if defined $word; then
      COMPREPLY=($(cd "${XDG_DATA_HOME}/swarms" && ls ${word}*))
    else
      COMPREPLY=($(cd "${XDG_DATA_HOME}/swarms" && ls))
    fi

  else COMPREPLY=()
  fi
}

complete -F _swarm swarm
