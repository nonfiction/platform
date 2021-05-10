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
      volume_row $1 "${volume_size}GB" "${VOLUME_SIZE}GB" "(expand)"
    else
      #will_resize_volume=false
      volume_row $1 "${volume_size}GB" "${VOLUME_SIZE}GB" "(no change)"
    fi
    
  else
    volume_row "${node}" "..." "${VOLUME_SIZE}GB" "(new)"
  fi
  
}

create_volume() {
  local role="replica"
  defined $2 && role="primary"
  
  echo "=> Creating volume $1"
  doctl compute volume create $1 \
    --region="${REGION}" \
    --size="${VOLUME_SIZE}GiB" \
    --fs-type="${FS_TYPE}" \
    --tag="swarm,swarm-${name},swarm-${name}-${role}"
}

resize_volume() { 
  if [ "$VOLUME_SIZE" -gt "$(get_volume_size $1)" ]; then 
    echo "=> Expanding volume $1"
    doctl compute volume-action resize "$(get_volume_id $1)" \
      --region="$REGION" 
      --size="$VOLUME_SIZE" 
      --wait 
  else
    echo "=> Volume $1 unchanged"
  fi
}

create_or_resize_volume() {
  if has_volume $1; then    
    resize_volume $1
  else
    create_volume $1 $2
  fi
}

