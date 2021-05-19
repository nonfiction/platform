#!/bin/bash

if [ -z "$HELPERS_LOADED" ]; then 
  if [ -e helpers.sh ]; then source helpers.sh;
  else source <(curl -fsSL https://github.com/nonfiction/platform/raw/master/swarm/lib/helpers.sh); fi
fi

# Returns number of bricks in a volume
get_bricks() {
  defined $1 || return  
  gluster volume info $1 | grep "Number of Bricks" | tail -c 3 | xargs
}

# Returns /mnt/node/volume_name unless BRICK_DIR env is set
get_brick_dir() {
  local node="${1}"
  if defined $BRICK_DIR; then
    echo $BRICK_DIR
  else
    echo "/mnt/${node}/${VOLUME_NAME}"
  fi
}

# Check if volume exists, pass volume name
undefined_volume() {
  undefined $1 && return 0  
  undefined "$(gluster volume info $1 | grep Started)" && return 0
  return 1
}

# Check if brick exists, pass volume name & mount path
undefined_brick() {
  undefined $1 && return 0  
  undefined $2 && return 0  
  undefined "$(gluster volume info $1 | grep $2)" && return 0
  return 1
}

# Check if volume isn't mounted
unmounted_volume() {
  undefined $1 && return 0  
  local volume=$1
  undefined "$(df | grep localhost:/$volume)" && return 0
  return 1
}
