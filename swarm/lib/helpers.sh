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
# echo_color black/on_red Warning message!
# echo_color prompt/yellow/on_purple This is a prompt
echo_color() {
  
  local black='\e[0;30m'  ublack='\e[4;30m'  on_black='\e[40m'  reset='\e[0m'
  local red='\e[0;31m'    ured='\e[4;31m'    on_red='\e[41m'    default='\e[0m'
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

echo_line() {
  local color=$1 char=$2 line=""
  defined $1 || color="reset"
  defined $2 || char="⎯"
  for i in $(seq $(tput cols)); do
    line="${line}${char}"
  done
  echo_color $color $line
}

echo_env() {
  defined $1 || return
  local key="$1" val="${!1}" trim=$2
  if defined $trim; then
    val="$(echo $val | head -c $trim)[...]$(echo $val | tail -c $trim)"
  fi
  echo "$(echo_color white "${key}=")$(echo_color green "\"${val}\"")"
}

echo_env_example() {
  defined $1 || return
  defined $2 || return
  local key="$1" val="${2}"
  echo_line yellow
  echo "$(echo_color yellow "export") $(echo_color white "${key}=")$(echo_color green "\"${val}\"")"
  echo_line yellow
}


echo_main() {
  defined $1 || return
  echo
  echo_line blue
  echo "$(echo_color black/on_blue " ★ ") $(echo_color blue " ${@} ")"
  echo_line blue
}

echo_next() {
  defined $1 || return
  echo
  echo "$(echo_color black/on_green " ▶︎ ") $(echo_color green " ${@} ")"
}

echo_info() {
  defined $1 || return
  echo
  echo "$(echo_color black/on_yellow " ✔︎ ") $(echo_color yellow " ${@} ")"
}

echo_stop() {
  defined $1 || return
  echo
  echo "$(echo_color black/on_red " ✖︎ ") $(echo_color red " ${@} ")"
}

# If $answer is "y", then we don't bother with user input
ask() { 
  echo
  echo "$(echo_color black/on_yellow " ? ") $(echo_color yellow " ${@} ")"
  read -p " y/[n] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
  if [ ! $? -ne 0 ]; then return 0; else return 1; fi
}

ask_input() { 
  echo
  echo "$(echo_color black/on_yellow " ? ") $(echo_color yellow " $1 ")"
  read $1
  echo
}

# Print command before running
echo_run() {
  defined $1 || return  
  echo "${1}"
  $1
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

env_file_ask() {
  local variable="${!1}"
  if undefined "$variable"; then
    defined "$2" && has "$2" && variable="$(cat $2)"
    if undefined "$variable"; then
      defined "$3" && has "$3" && variable="$(cat $3)"
      if undefined "$variable"; then
        read variable
      fi
    fi
  fi
  echo "$variable"
}

# Append line to end of file if it doesn't exist
append() {
  if [ $# -lt 2 ] || [ ! -r "$2" ]; then
    echo 'Usage: append "line to append" /path/to/file'
  else
    grep -q "^$1" $2 || echo "$1" | tee --append $2
  fi
}

# Echos /dev/stdin or first argument if provided
input() {
  defined "$1" && echo "$1" && return 0
  test -p /dev/stdin && awk '{print}' /dev/stdin && return 0 || return 1
}

# Strip a string to only lowercase alphanumeric with hypen + underscore
slugify() {
  echo "$(input $1)" | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | tr '.' '_' | xargs
}

hyphenify() {
  echo "$(input $1)" | tr -cd '[:alnum:]_.' | tr '[:upper:]' '[:lower:]' | tr '.' '-' | xargs
}

node_from_fqdn() {
  echo "$(input $1)" | tr '.' ' ' | awk '{print $1}'
}

domain_from_fqdn() {
  echo "$(input $1)" | tr '.' ' ' | awk '{$1=""}1' | xargs | tr ' ' '.'
}

node_from_slug() {
  echo "$(input $1)" | tr '_' ' ' | awk '{print $1}'
}

domain_from_slug() {
  echo "$(input $1)" | tr '_' ' ' | awk '{$1=""}1' | xargs | tr ' ' '.'
}

args() {
  local args
  args=$(test -p /dev/stdin && awk '{print}' /dev/stdin && return 0 || return 1)
  echo "$args" | tr ' ' '\n' | sort | uniq | xargs
}

rargs() {
  local args
  args=$(test -p /dev/stdin && awk '{print}' /dev/stdin && return 0 || return 1)
  echo "$args" | tr ' ' '\n' | sort | uniq | tac | xargs
}

first() {
  local args
  args=$(test -p /dev/stdin && awk '{print}' /dev/stdin && return 0 || return 1)
  echo "$args" | awk '{print $1}'
}

after_first() {
  local args
  args=$(test -p /dev/stdin && awk '{print}' /dev/stdin && return 0 || return 1)
  echo "$args" | awk '{$1=""}1' | xargs
}

lines() {
  echo "$(input $1)" | tr ' ' "\n"
}

add() {
  x=10
  echo $((x + $1))
}

generate_password() {
  local length=25;
  defined $1 && length=$1 
  tr -cd '[:alnum:]' < /dev/urandom | fold -w$length | head -n 1
}

generate_key() {
  local key; key="/tmp/key-$(echo '('`date +"%s.%N"` ' * 1000000)/1' | bc)"
  ssh-keygen -b 4096 -t rsa -f $key -q -N ""
  cat $key
  rm "${key}" "${key}.pub"
}



# Mark this as loaded
export HELPERS_LOADED=1
