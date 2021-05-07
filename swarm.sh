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


# ---------------------------------------------------------
# Header & Row helper functions
# ---------------------------------------------------------

# Print row for DNS record
record_row() { 
  printf "%2s %25s %-2s %-15s %-14s %2s\n" "|" "$1" "=>" "$2" "$3" "|"
}

# Print row for droplet
droplet_row() {
  printf "%2s %-10s %14s %-2s %-15s %-14s %2s\n" "|" " $1" "$2" "=>" "$3" "$4" "|"
}

# Print row for volume
volume_row() {
  printf "%2s %-19s %5s %-2s %-15s %-14s %2s\n" "|" " $1" "$2" "=>" "$3" "$4" "|"
}

# Print header row for node
node_row() {
  echo
  echo "=================================================================="
  echo " ${1}"
  echo "=================================================================="
}

divider_row() {
  printf "%2s %-60s %-2s\n" "|" " " "|"
  printf "%2s %-60s %-2s\n" "|" "============================================================" "|"
}

# Print header row for section
header_row() {
  printf "%2s %-60s %-2s\n" "|" " " "|"
  printf "%2s %-60s %-2s\n" "|" " $1" "|"
  printf "%2s %-60s %-2s\n" "|" "------------------------------------------------------------" "|"
}

# ---------------------------------------------------------
# DNS record functions
# ---------------------------------------------------------

has_record() {
  defined "$(doctl compute domain records list $DOMAIN -o json | grep "\"name\": \"${1}\"" | head -n 1)"
}

get_record() {
  doctl compute domain records list $DOMAIN --format "ID,Name,Data" | grep " $1 " | awk '{print $3}'
}

# ---------------------------------------------------------
# Show DNS records
# --------------------------------------------------------- 
get_record_info() {
  
  local public_record
  local wildcard_record
  local private_record
  
  header_row "DNS RECORDS: ${DOMAIN}"

  public_record=$(get_record $1)
  if defined $public_record; then
    record_row "${1}" "${public_record}" "(no change)"
  else
    record_row "${1}" "?" "(new)"
  fi
  
  wildcard_record=$(get_record "\*.${1}")
  if defined $wildcard_record; then
    record_row "*.${1}" "${wildcard_record}" "(no change)"
  else
    record_row "*.${1}" "?" "(new)"
  fi
  
  private_record=$(get_record "private.${1}")
  if defined $private_record; then
    record_row "private.${1}" "${private_record}" "(no change)"
  else
    record_row "private.${1}" "?" "(new)"
  fi
  
}

create_record() {
  if undefined $(get_record "$1"); then
    echo "=> Creating DNS record $1"
    doctl compute domain records create $DOMAIN \
    --record-name="$1" \
    --record-data="$2" \
    --record-type="A" \
    --record-ttl="300"
  else
    echo "=> DNS record $1 already exists"
  fi
}
  


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
    --tag-names="${TAG},${TAG}-${name},${TAG}-${name}-${role}" \
    --ssh-keys="${SSH_KEYS}" \
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
    --tag="${TAG},${TAG}-${name},${TAG}-${name}-${role}"
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



# ---------------------------------------------------------
# Ensure doctl is installed and authenticated
# ---------------------------------------------------------

# Install doctl (if it isn't already)
if hasnt doctl; then
  
  echo "=> Installing doctl..."
  
  # https://github.com/digitalocean/doctl/releases
  VERSION="1.59.0"
  curl -sL https://github.com/digitalocean/doctl/releases/download/v$VERSION/doctl-$VERSION-linux-amd64.tar.gz | tar -xzv
  mv ./doctl /usr/local/bin/doctl

fi

# Check if doctl is already authorized to list droplets
if error "doctl compute droplet list"; then
  
  echo "=> doctl unauthorized"
  
  #  https://cloud.digitalocean.com/account/api/tokens
  if undefined "$DO_TOKEN"; then
    echo "=> Missing DO_TOKEN!"
    echo "Create a Personal Access Token on Digital Ocean and set it to an environment variable named:"
    echo "export DO_TOKEN=\"...\""
    exit 1
  fi     

  echo "=> Authorizing doctl..."
  doctl auth init -t $DO_TOKEN 
  
fi  

# DOMAIN from env
if undefined $DOMAIN; then
  echo "=> Missing DOMAIN!"
  echo "Create a domain name named by Digital Ocean and set it to an environment variable named:"
  echo "export DOMAIN=\"example.com\""
  exit 1
fi

# ROOT_PASSWORD from env, or default
if undefined $ROOT_PASSWORD; then
  ROOT_PASSWORD="secret"
fi

# DROPLET_IMAGE from env, or default
# - ubuntu-18-04-x64
# - ubuntu-20-04-x64
if undefined $DROPLET_IMAGE; then
  DROPLET_IMAGE="ubuntu-18-04-x64"
fi

# DROPLET_SIZE from env, or default
# $5/mo: s-1vcpu-1gb
# $15/mo: s-2vcpu-2gb 
if undefined $DROPLET_SIZE; then
  DROPLET_SIZE="s-1vcpu-1gb"
fi

# VOLUME_SIZE from env, or default
if undefined $VOLUME_SIZE; then
  VOLUME_SIZE="50"
fi

# REGION from env, or default
if undefined $REGION; then
  REGION="tor1"
fi

# FS_TYPE from env, or default
if undefined $FS_TYPE; then
  FS_TYPE="ext4"
fi

# SSH_KEYS from env, or default
if undefined $SSH_KEYS; then
  SSH_KEYS="18792072"
fi

# TAG from env, or default
if undefined $TAG; then
  TAG="swarm"
fi




# First parameter is name of swarm
name="$1"
if undefined $1; then
  echo "=> Missing swarm name!"
  echo "The first argument for this script should be the swarm's name. Example: ./swarm.sh app 3"
  exit 1
fi

# Second parameter is number of new replicas, or default 0
new_replicas="$2"
undefined $2 && new_replicas=0

# echo "name: ${name}.${DOMAIN}"
# echo "nodes: ${nodes}"
# echo "root_password: ${ROOT_PASSWORD}"
# echo "droplet_image: ${DROPLET_IMAGE}"
# echo "droplet_size: ${DROPLET_SIZE}"
# echo "volume_size: ${VOLUME_SIZE}"

echo "=> Generating report..."


# PRIMARY NODE
status="NEW"
has_droplet $name && status="EXISTING"
node_row "${status} PRIMARY: ${name}"
get_droplet_info $name
get_volume_info $name
get_record_info $name
echo
echo

# EXISTING REPLICAS
for replica in $(get_droplet_replicas $name); do
  node_row "EXISTING REPLICA: ${replica}"
  get_droplet_info $replica
  get_volume_info $replica
  get_record_info $replica
done
echo
echo

# NEW REPLICAS
echo "" > /tmp/reserved_replicas
for i in $(seq $new_replicas); do
  replica=$(next_replica_name $name)
  node_row "NEW REPLICA: ${replica}"
  get_droplet_info $replica
  get_volume_info $replica
  get_record_info $replica  
done
echo
echo

echo "=================================================================="
if confirm "Make changes?"; then  
  echo "=> Begining..."
else
  echo "=> Cancelled."  
  exit 1;
fi

# ---------------------------------------------------------
# Process Primary
# ---------------------------------------------------------
status="NEW"
has_droplet $name && status="EXISTING"
node_row "${status} PRIMARY: ${name}"
get_droplet_info $name
get_volume_info $name
get_record_info $name
echo
echo

if confirm "Process node?"; then  
  create_or_resize_volume $name true
  create_or_resize_droplet $name true
  create_record "${name}" "$(get_droplet_public_ip $name)"
  create_record "*.${name}" "$(get_droplet_public_ip $name)"
  create_record "private.${name}" "$(get_droplet_private_ip $name)"
fi

# ---------------------------------------------------------
# Process Existing Replicas
# ---------------------------------------------------------
for replica in $(get_droplet_replicas $name); do  
  node_row "EXISTING REPLICA: ${replica}"
  get_droplet_info $replica
  get_volume_info $replica
  get_record_info $replica
  echo
  echo
  
  if confirm "Process node?"; then  
    create_or_resize_volume $replica
    create_or_resize_droplet $replica
    create_record "${replica}" "$(get_droplet_public_ip $replica)"
    create_record "*.${replica}" "$(get_droplet_public_ip $replica)"
    create_record "private.${replica}" "$(get_droplet_private_ip $replica)"
  fi
done

# ---------------------------------------------------------
# Process New Replicas
# ---------------------------------------------------------
echo "" > /tmp/reserved_replicas
for i in $(seq $new_replicas); do
  replica=$(next_replica_name $name)
  node_row "NEW REPLICA: ${replica}"
  get_droplet_info $replica
  get_volume_info $replica
  get_record_info $replica
  echo
  echo
  
  if confirm "Process node?"; then  
    create_or_resize_volume $replica
    create_or_resize_droplet $replica
    create_record "${replica}" "$(get_droplet_public_ip $replica)"
    create_record "*.${replica}" "$(get_droplet_public_ip $replica)"
    create_record "private.${replica}" "$(get_droplet_private_ip $replica)"
  fi 
  
done
echo
echo


exit 0
