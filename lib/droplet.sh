#!/bin/bash

# ---------------------------------------------------------
# Droplet functions
# ---------------------------------------------------------

__droplet_list() {
  doctl compute droplet list --format "ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Tags"
}

has_droplet() {
  defined $1 || return
  defined $(get_droplet_id $1)
}

get_droplet_id() {
  defined $1 || return
  __droplet_list | grep " $1 " | awk '{print $1}'
}

get_droplet_public_ip() {
  defined $1 || return
  __droplet_list | grep " $1 " | awk '{print $3}'
}

get_droplet_private_ip() {
  defined $1 || return
  __droplet_list | grep " $1 " | awk '{print $4}'
}

# Get memory as integer (in GB)
get_droplet_memory() {
  defined $1 || return
  local mem
  mem=$(__droplet_list | grep " $1 " | awk '{print $5}')
  [ "$mem" = "1024" ] && echo 1
  [ "$mem" = "2048" ] && echo 2
  [ "$mem" = "3072" ] && echo 3
  [ "$mem" = "4096" ] && echo 4
  [ "$mem" = "8192" ] && echo 8  
}

# Get memory from size slug
get_droplet_memory_from_size() {
  echo $1 | awk 'BEGIN { FS = "-" } ; { print $3 }' | awk 'BEGIN { FS = "gb" } ; { print $1 }'
}

# Get droplet cpu
get_droplet_cpu() {
  defined $1 || return  
  __droplet_list | grep " $1 " | awk '{print $6}'
}

# Get cpu from size slug
get_droplet_cpu_from_size() {
  echo $1 | awk 'BEGIN { FS = "-" } ; { print $2 }' |  awk 'BEGIN { FS = "vcpu" } ; { print $1 }'
}

# Generate size slug from droplet 
# $5/mo: s-1vcpu-1gb
# $15/mo: s-2vcpu-2gb 
get_droplet_size() {
  defined $1 || return
  local mem cpu
  mem=$(get_droplet_memory $1)
  cpu=$(get_droplet_cpu $1)
  echo "s-${cpu}vcpu-${mem}gb"
}

get_droplet_replicas() {
  defined $1 || return
  echo "$(__droplet_list | grep "swarm-${1}-replica" | awk '{print $2}' | tr '\n' ' ' | xargs)"
}

get_droplet_additions() {
  
  local primary_name=$1 number_of_additions=0
  defined $1 || return
  defined $2 && number_of_additions=$2
  
  local i next additions
  
  # If the primary doesn't yet exist, add it as an addition
  #has_droplet $primary_name || additions="${primary_name}"

  echo "" > /tmp/reserved.txt
  for i in $(seq $number_of_additions); do
    next=$(__next_replica_name $primary_name)
    additions="${additions} ${next}"
  done
  rm -f /tmp/reserved.txt
  
  echo $additions | xargs
}

__next_replica_name() {
  local primary_name=$1 replica_name pad i
  touch /tmp/reserved.txt

  for i in $(seq 99); do
    pad="" && [ $i -lt 10 ] && pad="0"
    replica_name="${primary_name}${pad}${i}"
    if [[ ! "$(cat /tmp/reserved.txt)" =~ "[${replica_name}]" ]]; then
      echo "[${replica_name}]" >> /tmp/reserved.txt
      has_droplet $replica_name || break
    fi
  done

  echo $replica_name
}

# ---------------------------------------------------------
# Show droplet info
# ---------------------------------------------------------
get_droplet_info() {
  defined $1 || return
  
  local droplet_name=$1 droplet_size droplet_cpu droplet_cpu_env droplet_memory droplet_memory_env
  
  header_row "DROPLET: ${DROPLET_IMAGE} / ${REGION}"
  
  if has_droplet $droplet_name; then
    
    droplet_size=$(get_droplet_size $droplet_name)
    
    droplet_cpu=$(get_droplet_cpu_from_size $droplet_size)
    droplet_cpu_env=$(get_droplet_cpu_from_size $DROPLET_SIZE)
    
    droplet_memory=$(get_droplet_memory_from_size $droplet_size)
    droplet_memory_env=$(get_droplet_memory_from_size $DROPLET_SIZE)    
    
    if [ $droplet_cpu_env -gt $droplet_cpu ] || [ $droplet_memory_env -gt $droplet_memory ]; then
      touch /tmp/dirty.txt
      droplet_row $droplet_name "${droplet_size}" "${DROPLET_SIZE}" "(expand)"
    else
      droplet_row $droplet_name "${droplet_size}" "${DROPLET_SIZE}" "(no change)"
    fi
    
  else
    touch /tmp/dirty.txt
    droplet_row $droplet_name "..." "${DROPLET_SIZE}" "(new)"
  fi
  
}

create_droplet() {

  defined $1 || return
  defined $DOMAIN || return
  defined $REGION || return
  defined $DROPLET_SIZE || return
  defined $DROPLET_IMAGE || return
  defined $ROOT_PASSWORD || return
  defined $ROOT_PUBLIC_KEY || return
  
  local droplet_name=$1

  local swarm_name=$2
  undefined $2 && swarm_name="$droplet_name"
  
  local role=$3
  undefined $3 && role="primary"
  
  # Download cloud-config.yml and fill out variables
  local config=/tmp/cloud-config.yml
  curl -sL https://github.com/nonfiction/platform/raw/master/cloud-config.yml > $config
  sed -i "s/__NAME__/${droplet_name}/" $config
  sed -i "s/__DOMAIN__/${DOMAIN}/" $config
  sed -i "s|__ROOT_PUBLIC_KEY__|${ROOT_PUBLIC_KEY}|" $config
  
  echo "=> Creating droplet $droplet_name"
  doctl compute droplet create $droplet_name \
    --region="${REGION}" \
    --size="${DROPLET_SIZE}" \
    --image="${DROPLET_IMAGE}" \
    --tag-names="swarm,swarm-${swarm_name},swarm-${swarm_name}-${role}" \
    --user-data-file="$config" \
    --volumes="$(get_volume_id $droplet_name)" \
    --enable-private-networking \
    --enable-monitoring \
    --enable-backups \
    --verbose \
    --wait
  
  # # Update password
  # echo "=> Updating root password on $droplet_name"
  # local ip
  # ip="$(get_droplet_public_ip $droplet_name)"
  # run $ip "echo root:${ROOT_PASSWORD} | chpasswd && echo work:${ROOT_PASSWORD} | chpasswd"
}

resize_droplet() { 
  defined $1 || return
  
  local droplet_name=$1 droplet_id droplet_size droplet_cpu droplet_cpu_env droplet_memory droplet_memory_env
  
  droplet_id=$(get_droplet_id $droplet_name)
  droplet_size=$(get_droplet_size $droplet_name)
    
  droplet_cpu=$(get_droplet_cpu_from_size $droplet_size)
  droplet_cpu_env=$(get_droplet_cpu_from_size $DROPLET_SIZE)
    
  droplet_memory=$(get_droplet_memory_from_size $droplet_size)
  droplet_memory_env=$(get_droplet_memory_from_size $DROPLET_SIZE)    
    
  if [ $droplet_cpu_env -gt $droplet_cpu ] || [ $droplet_memory_env -gt $droplet_memory ]; then
    echo "=> Turning OFF droplet $droplet_name"
    doctl compute droplet-action power-off "$droplet_id" --verbose --wait
    echo "=> Expanding droplet $droplet_name"
    doctl compute droplet-action resize "$droplet_id" --size="$droplet_size" --verbose --wait
    echo "=> Turning ON droplet $droplet_name"
    doctl compute droplet-action power-on "$droplet_id" --verbose --wait
  else
    echo "=> Droplet $droplet_name unchanged"
  fi
}

create_or_resize_droplet() {
  defined $1 || return
  
  local droplet_name=$1 swarm_name=$2 role=$3
  
  if has_droplet $droplet_name; then
    resize_droplet $droplet_name
  else
    create_droplet $droplet_name $swarm_name $role
  fi
  
}

# First arg is the IP address, all other args are commands
# run 192.168.1.2 touch ~/file.txt 
run() {
  defined "$ROOT_PRIVATE_KEY" || return
  defined $1 || return
  local host=$1
  echo "$ROOT_PRIVATE_KEY" > /tmp/root_private_key.txt
  chmod 400 /tmp/root_private_key.txt
  ssh -o "StrictHostKeyChecking=no" -i /tmp/root_private_key.txt root@$host "${@:2}"
  rm -f /tmp/root_private_key.txt
}