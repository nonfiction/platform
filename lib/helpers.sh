#!/bin/bash

# ---------------------------------------------------------
# Helper functions
# ---------------------------------------------------------

# True if command or file does exist
has() {
  if [ -e "$1" ]; then return 0; fi
  command -v $1 >/dev/null 2>&1 && { return 0; }
  return 1
}

# True if command or file doesn't exist
hasnt() {
  if [ -e "$1" ]; then return 1; fi
  command -v $1 >/dev/null 2>&1 && { return 1; }
  return 0
}

# True if variable is not empty
defined() {
  if [ -z "$1" ]; then return 1; fi  
  return 0
}

# True if variable is empty
undefined() {
  if [ -z "$1" ]; then return 0; fi
  return 1
}

# True if argument has error output
error() {
  local err="$($@ 2>&1 > /dev/null)"  
  if [ -z "$err" ]; then return 1; fi
  return 0
}

# Pretty messages
# print black/on_red Warning message!
# print prompt/yellow/on_purple This is a prompt
print() {
  
  local black='\e[0;30m'  ublack='\e[4;30m'  on_black='\e[40m'  reset='\e[0m'
  local red='\e[0;31m'    ured='\e[4;31m'    on_red='\e[41m'
  local green='\e[0;32m'  ugreen='\e[4;32m'  on_green='\e[42m'
  local yellow='\e[0;33m' uyellow='\e[4;33m' on_yellow='\e[43m'
  local blue='\e[0;34m'   ublue='\e[4;34m'   on_blue='\e[44m'
  local purple='\e[0;35m' upurple='\e[4;35m' on_purple='\e[45m'
  local cyan='\e[0;36m'   ucyan='\e[4;36m'   on_cyan='\e[46m'
  local white='\e[0;37m'  uwhite='\e[4;37m'  on_white='\e[47m'
  
  local format=""
  for color in $(echo "$1" | tr "/" "\n"); do  
    format="${format}${!color}"
  done
  local message="${@:2}"  
  
  printf "${format}${message}${reset}\n";
  
}

echo_env() {
  defined $1 || return
  local key="$1" val="${!1}" trim=$2
  if defined $trim; then
    val="$(echo $val | head -c $trim)...$(echo $val | tail -c $trim)"
  fi
  echo "$(print white "${key}=")$(print green "\"${val}\"")"
}

echo_env_example() {
  defined $1 || return
  defined $2 || return
  local key="$1" val="${2}"
  echo "$(print white "export ${key}=")$(print green "\"${val}\"")"
}

echo_next() {
  defined $1 || return
  echo "$(print green "=>") $(print black/on_white " ${@} ")"
}

echo_stop() {
  defined $1 || return
  echo "$(print red "=>") $(print black/on_red " ${@} ")"
}

# If $answer is "y", then we don't bother with user input
ask() { 
  echo "$(print green "=>") $(print white "$@")"
  read -p " y/[n] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
  if [ ! $? -ne 0 ]; then return 0; else return 1; fi
}


# Check for environment variable, or fall back on up to 2 files
env_or_file() {
  local variable="${!1}"
  if undefined "$variable"; then
    defined "$2" && has "$2" && variable="$(cat $2)"
    if undefined "$variable"; then
      defined "$3" && has "$3" && variable="$(cat $3)"
    fi
  fi
  echo "$variable"
}

# Mark this as loaded
export HELPERS_LOADED=1
