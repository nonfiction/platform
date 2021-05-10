#!/bin/bash

# ---------------------------------------------------------
# Droplet functions
# ---------------------------------------------------------

has_droplet() {
  defined $(get_droplet_id "$1")
}

get_droplet_id() {
  doctl compute droplet list --format "ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Tags" | grep " $1 " | awk '{print $1}'
}

get_droplet_public_ip() {
  doctl compute droplet list --format "ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Tags" | grep " $1 " | awk '{print $3}'
}

get_droplet_private_ip() {
  doctl compute droplet list --format "ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Tags" | grep " $1 " | awk '{print $4}'
}

# Get memory as integer (in GB)
get_droplet_memory() {
  local mem
  mem=$(doctl compute droplet list --format "ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Tags" | grep " $1 " | awk '{print $5}')
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
  doctl compute droplet list --format "ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Tags" | grep " $1 " | awk '{print $6}'
}

# Get cpu from size slug
get_droplet_cpu_from_size() {
  echo $1 | awk 'BEGIN { FS = "-" } ; { print $2 }' |  awk 'BEGIN { FS = "vcpu" } ; { print $1 }'
}

# Generate size slug from droplet 
# $5/mo: s-1vcpu-1gb
# $15/mo: s-2vcpu-2gb 
get_droplet_size() {
  local mem
  local cpu
  mem=$(get_droplet_memory $1)
  cpu=$(get_droplet_cpu $1)
  echo "s-${cpu}vcpu-${mem}gb"
}

get_droplet_replicas() {
  local tag="swarm-${name}-replica"
  doctl compute droplet list --format "ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Tags" | grep $tag | awk '{print $2}'
}

# ---------------------------------------------------------
# Show droplet info
# ---------------------------------------------------------
get_droplet_info() {
  
  local droplet_size
  local droplet_cpu
  local droplet_cpu_env
  local droplet_memory
  local droplet_memory_env  
  
  header_row "DROPLET: ${DROPLET_IMAGE} / ${REGION}"
  
  if has_droplet $1; then
    
    droplet_size=$(get_droplet_size $1)
    
    droplet_cpu=$(get_droplet_cpu_from_size $droplet_size)
    droplet_cpu_env=$(get_droplet_cpu_from_size $DROPLET_SIZE)
    
    droplet_memory=$(get_droplet_memory_from_size $droplet_size)
    droplet_memory_env=$(get_droplet_memory_from_size $DROPLET_SIZE)    
    
    if [ $droplet_cpu_env -gt $droplet_cpu ] || [ $droplet_memory_env -gt $droplet_memory ]; then
      #will_resize_droplet=true
      droplet_row $1 "${droplet_size}" "${DROPLET_SIZE}" "(expand)"
    else
      #will_resize_droplet=false
      droplet_row $1 "${droplet_size}" "${DROPLET_SIZE}" "(no change)"
    fi
    
  else
    droplet_row $1 "..." "${DROPLET_SIZE}" "(new)"
  fi
  
}

create_droplet() {
  
  local role="replica"
  defined $2 && role="primary"
  
  # Download cloud-config.yml and fill out variables
  local config=/tmp/cloud-config.yml
  curl -sL https://github.com/nonfiction/platform/raw/master/cloud-config.yml > $config
  sed -i "s/__NAME__/${1}/" $config
  sed -i "s/__DOMAIN__/${DOMAIN}/" $config
  sed -i "s/__HASH__/$(openssl passwd -1 -salt SaltSalt $ROOT_PASSWORD)/" $config
  
  echo "=> Creating droplet $1"
  doctl compute droplet create $1 \
    --region="${REGION}" \
    --size="${DROPLET_SIZE}" \
    --image="${DROPLET_IMAGE}" \
    --tag-names="swarm,swarm-${name},swarm-${name}-${role}" \
    --user-data-file="$config" \
    --volumes="$(get_volume_id $1)" \
    --enable-private-networking \
    --enable-monitoring \
    --enable-backups \
    --verbose \
    --wait
}

resize_droplet() { 

  local droplet_id
  local droplet_size
  local droplet_cpu
  local droplet_cpu_env
  local droplet_memory
  local droplet_memory_env  
  
  droplet_id=$(get_droplet_id $1)
  droplet_size=$(get_droplet_size $1)
    
  droplet_cpu=$(get_droplet_cpu_from_size $droplet_size)
  droplet_cpu_env=$(get_droplet_cpu_from_size $DROPLET_SIZE)
    
  droplet_memory=$(get_droplet_memory_from_size $droplet_size)
  droplet_memory_env=$(get_droplet_memory_from_size $DROPLET_SIZE)    
    
  if [ $droplet_cpu_env -gt $droplet_cpu ] || [ $droplet_memory_env -gt $droplet_memory ]; then
    echo "=> Turning OFF droplet $1"
    doctl compute droplet-action power-off "$droplet_id" --verbose --wait
    echo "=> Expanding droplet $1"
    doctl compute droplet-action resize "$droplet_id" --size="$droplet_size" --verbose --wait
    echo "=> Turning ON droplet $1"
    doctl compute droplet-action power-on "$droplet_id" --verbose --wait
  else
    echo "=> Droplet $1 unchanged"
  fi
}

create_or_resize_droplet() {
  if has_droplet $1; then
    resize_droplet $1
  else
    create_droplet $1 $2
  fi
  
}

# First arg is the IP address, all other args are commands
# do 192.168.1.2 touch ~/file.txt 
run() {
  echo "$SSH_KEY" > ./ssh_key.tmp
  chmod 400 ./ssh_key.tmp
  ssh -o "StrictHostKeyChecking=no" root@$1 "${@:2}"
  rm ./ssh_key.tmp
}