#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"


dev_dir() {
  echo $1 | awk -F ':' '{print $2}'
}

volumes_env() {

  local node; node=$1
  defined $node || node=$(hostname)
  local fqdn; fqdn="${node}.$(cat /usr/local/env/DOMAIN)"

  export DO_BLOCK_VOL="$(hyphenify $fqdn)"
  export DO_BLOCK_DEV="/dev/disk/by-id/scsi-0DO_Volume_$(hyphenify $fqdn)"
  export DO_BLOCK_MNT="/mnt/$(slugify $fqdn)"

  export GFS_DATA_VOL="data-gfs"
  export GFS_DATA_DEV="${node}:/mnt/$(slugify $fqdn)/data-gfs"
  export GFS_DATA_MNT="/data"

  # export GFS_WORK_VOL="work-gfs"
  # export GFS_WORK_DEV="${node}:/mnt/work/work-gfs"
  # export GFS_WORK_MNT="/work"

}

# Returns number of bricks in a volume (plus or minus the second argument)
count_bricks() {
  defined $1 || return  
  local bricks num=0
  defined $2 && num=$2
  bricks=$(gluster volume info $1 | grep "Number of Bricks" | tail -c 3 | xargs)
  echo $((bricks + $num))
}


create_gluster_volume() {

  defined $1 || return  
  defined $2 || return  

  local vol="$1" dev="$2" 

  # Check if volume does not yet exist
  if undefined_gluster_volume $vol; then

    # Create volume 
    echo_next "Gluster create $vol"
    echo_run "gluster volume create $vol $dev force"
    sleep 3

    # Start volume
    echo_next "Gluster start $vol"
    echo_run "gluster volume start $vol"
    sleep 3

  else
    echo_info "Gluster volume $vol is already started"
  fi

}


expand_gluster_volume() {

  defined $1 || return  
  defined $2 || return  

  local vol="$1" dev="$2" brick_count=0
  brick_count=$(count_bricks $vol +1)

  # Check if brick does not yet exist
  if undefined_brick $vol $dev; then

    # Add brick to volume
    echo_next "Gluster add brick to $vol"
    echo_run "gluster volume add-brick $vol replica $brick_count $dev force"
    sleep 3

  else
    echo_info "Gluster brick $dev is already added to $vol"
  fi

} 


mount_gluster_volume() {

  defined $1 || return  
  defined $2 || return  

  local vol="$1" mnt="$2"

  # Mount volume now
  if unmounted_gluster_volume $vol; then
    echo_next "Gluster mount $vol"
    umount $mnt
    echo_run "mount.glusterfs localhost:/${vol} $mnt"
    echo_info "$vol is now mounted to $mnt"
  else
    echo_info "$vol is already mounted to $mnt"
  fi

  # Make sure this volume is mounted upon reboot
  entry="localhost:/${vol} ${mnt} glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0"
  if undefined "$(cat /etc/fstab | grep "${entry}")"; then
    echo_next "Appending /etc/fstab"
    echo "${entry}" | tee --append /etc/fstab
  fi

}

# Check if volume exists, pass volume name
undefined_gluster_volume() {
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
unmounted_gluster_volume() {
  undefined $1 && return 0  
  local volume=$1
  undefined "$(df | grep localhost:/$volume)" && return 0
  return 1
}
