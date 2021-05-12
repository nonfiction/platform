#!/bin/bash

# ---------------------------------------------------------
# Volume functions
# ---------------------------------------------------------

has_volume() {
  defined $(get_volume_id "$1")
}

get_volume_id() {
  doctl compute volume list --format "ID,Name,Size" | grep " $1 " | awk '{print $1}'
}

get_volume_size() {  
  doctl compute volume list --format "ID,Name,Size" | grep " $1 " | awk '{print $3}'
}

# ---------------------------------------------------------
# Show Volume Info
# ---------------------------------------------------------
get_volume_info() {
  
  local volume_size
  
  header_row "VOLUME: ${FS_TYPE} / ${REGION}"
  
  if has_volume $1; then
    volume_size=$(get_volume_size $1)

    if [ "$VOLUME_SIZE" -gt "$volume_size" ]; then 
      # sudo resize2fs /dev/disk/by-id/scsi-0DO_example
      #will_resize_volume=true
      touch /tmp/dirty.txt
      volume_row $1 "${volume_size}GB" "${VOLUME_SIZE}GB" "(expand)"
    else
      #will_resize_volume=false
      volume_row $1 "${volume_size}GB" "${VOLUME_SIZE}GB" "(no change)"
    fi
    
  else
    touch /tmp/dirty.txt
    volume_row "${node}" "..." "${VOLUME_SIZE}GB" "(new)"
  fi
  
}

create_volume() {  

  defined $1 || return  
  local volume_name=$1
  
  local swarm_name=$2
  undefined $2 && swarm_name="$volume_name"
  
  local role=$3
  undefined $3 && role="primary"
  
  defined $REGION || return
  defined $VOLUME_SIZE || return
  defined $FS_TYPE || return  
  
  echo "=> Creating volume $volume_name"
  doctl compute volume create $volume_name \
    --region="${REGION}" \
    --size="${VOLUME_SIZE}GiB" \
    --fs-type="${FS_TYPE}" \
    --tag="swarm,swarm-${swarm_name},swarm-${swarm_name}-${role}"
}

resize_volume() { 

  defined $1 || return  
  local volume_name=$1
  
  defined $REGION || return
  defined $VOLUME_SIZE || return

  if [ "$VOLUME_SIZE" -gt "$(get_volume_size $volume_name)" ]; then 
    echo "=> Expanding volume $volume_name"
    doctl compute volume-action resize "$(get_volume_id $volume_name)" \
      --region="$REGION" 
      --size="$VOLUME_SIZE" 
      --wait 
  else
    echo "=> Volume $volume_name unchanged"
  fi
  
}

create_or_resize_volume() {
  if has_volume $1; then    
    resize_volume $1
  else
    create_volume $1 $2 $3
  fi
}

