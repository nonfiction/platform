#!/bin/bash

# Source once locally if available OR via curl if not 
include() {
  [ -z "$1" ] && return 1
  [[ "$INCLUDED" =~ "[$1]" ]] && return 0
  if [ -e /root/platform/swarm/$1 ]; then source /root/platform/swarm/$1;
  else source <(curl -fsSL https://github.com/nonfiction/platform/raw/master/swarm/$1); fi
 INCLUDED="${INCLUDED}[$1]"
}

# Bash helper functions
include "lib/helpers.sh"


# source /root/platform/swarm/lib/completion.sh
function _swarm () {

  defined $XDG_CONFIG_HOME || XDG_CONFIG_HOME=$HOME/.config
  defined $XDG_DATA_HOME || XDG_DATA_HOME=$HOME/.local/share

  local commands="create delete edit inspect list primary replicas ssh size update help"
  local word="${COMP_WORDS[COMP_CWORD]}";

  # List commands
  if   [ "${#COMP_WORDS[@]}" = "2" ]; then 

      if [[ $word = c* ]];  then commands="create"
    elif [[ $word = d* ]];  then commands="delete"
    elif [[ $word = e* ]];  then commands="edit"
    elif [[ $word = h* ]];  then commands="help"
    elif [[ $word = i* ]];  then commands="inspect"
    elif [[ $word = l* ]];  then commands="list"
    elif [[ $word = p* ]];  then commands="primary"
    elif [[ $word = r* ]];  then commands="replicas"
    elif [[ $word = ss* ]]; then commands="ssh"
    elif [[ $word = si* ]]; then commands="size"
    elif [[ $word = s* ]];  then commands="ssh size"
    elif [[ $word = u* ]];  then commands="update"
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
