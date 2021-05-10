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

ask() { 
  printf "=> $1";
  read -p " y/[n] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
  if [ ! $? -ne 0 ]; then return 0; else return 1; fi
}

# syntax: confirm [<prompt>]
confirm() {
  local _prompt _default _response
 
  if [ "$1" ]; then _prompt="$1"; else _prompt="Are you sure"; fi
  _prompt="$_prompt [y/n] ?"
 
  # Loop forever until the user enters a valid response (Y/N or Yes/No).
  while true; do
    read -r -p "$_prompt " _response
    case "$_response" in
      [Yy][Ee][Ss]|[Yy]) # Yes or Y (case-insensitive).
        return 0
        ;;
      [Nn][Oo]|[Nn])  # No or N.
        return 1
        ;;
      *) # Anything else (including a blank) is invalid.
        ;;
    esac
  done
}

# Build padded name for node
node_name() {
  local name="$1"
  local number="$2"
  local pad=""
  [ "$number" -lt "10" ] && pad="0"
  echo "${name}${pad}${number}"
}


next_replica_name() {
  local pad
  local replica  
  touch /tmp/reserved_replicas

  for i in $(seq 99); do
    pad="" && [ $i -lt 10 ] && pad="0"
    replica="${1}${pad}${i}"
    if [[ ! "$(cat /tmp/reserved_replicas)" =~ "[${replica}]" ]]; then
      has_droplet $replica || break
    fi
  done

  echo "[${replica}]" >> /tmp/reserved_replicas
  echo $replica
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
