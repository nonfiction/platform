#!/bin/bash

# Bash helper functions
if [ -z "$HELPERS_LOADED" ]; then 
  if [ -e /root/platform/swarm/lib/helpers.sh ]; then source /root/platform/swarm/lib/helpers.sh;
  else source <(curl -fsSL https://github.com/nonfiction/platform/raw/master/swarm/lib/helpers.sh); fi
fi


# ---------------------------------------------------------
# Ensure doctl is installed and authenticated
# ---------------------------------------------------------

# Install doctl (if it isn't already)
if hasnt doctl; then
  
  echo_next "Installing doctl..."
  
  # https://github.com/digitalocean/doctl/releases
  version="1.61.0"
  curl -sL https://github.com/digitalocean/doctl/releases/download/v${version}/doctl-${version}-linux-amd64.tar.gz | tar -xzv
  mv doctl .doctl
  if error "mv ./.doctl /usr/local/bin/doctl"; then
    rm -f ./.doctl
    echo_stop "Missing permissions to move doctl to /usr/local/bin"
    echo "chown that directory so your user can write to it."
    exit 1
  fi

fi

# Check if doctl is already authorized to list droplets
if error "doctl compute droplet list"; then
  
  echo_info "doctl unauthorized, checking for token..."
  
  #  https://cloud.digitalocean.com/account/api/tokens
  DO_AUTH_TOKEN=$(env_or_file DO_AUTH_TOKEN /run/secrets/do_token)
  if undefined "$DO_AUTH_TOKEN"; then
    echo_stop "Missing DO_AUTH_TOKEN!"
    echo "Create a Personal Access Token on Digital Ocean and set it to an environment variable named:"
    echo_env_example "DO_AUTH_TOKEN" "..."
    exit 1
  fi     

  echo_next "Authorizing doctl..."
  doctl auth init -t $DO_AUTH_TOKEN

  if error "doctl compute droplet list"; then
    echo_stop "Supplied DO_AUTH_TOKEN is invalid!"
    exit 1
  fi
  
fi


# ---------------------------------------------------------
# Environment Variables
# ---------------------------------------------------------

# DOMAIN from env or secret
DOMAIN=$(env_or_file DOMAIN /run/secrets/domain)
if undefined $DOMAIN; then
  echo_stop "Missing DOMAIN!"
  echo "Create a domain name named by Digital Ocean and set it to an environment variable named:"
  echo_env_example "DOMAIN" "example.com"
  exit 1
fi

# ROOT_PRIVATE_KEY from env or secret
ROOT_PRIVATE_KEY="$(env_or_file ROOT_PRIVATE_KEY ./root_private_key /run/secrets/root_private_key)"
if undefined $ROOT_PRIVATE_KEY; then
  echo_stop "Missing ROOT_PRIVATE_KEY!"
  echo "Generate an SSH key and set it to an environment variable named:"
  echo_env_example "ROOT_PRIVATE_KEY" "-----BEGIN RSA PRIVATE KEY----- ..."
  echo "OR save a file in your current directory named: root_private_key"
  exit 1
fi

# ROOT_PUBLIC_KEY from ROOT_PRIVATE_KEY
echo "$ROOT_PRIVATE_KEY" > root_private_key.tmp
chmod 400 root_private_key.tmp
ROOT_PUBLIC_KEY="$(ssh-keygen -y -f root_private_key.tmp) root"
rm -f root_private_key.tmp

# ROOT_PASSWORD from env or secret
ROOT_PASSWORD=$(env_or_file ROOT_PASSWORD /run/secrets/root_password)
if undefined $ROOT_PASSWORD; then
  echo_stop "Missing ROOT_PASSWORD!"
  echo "Create a root password and set it to an environment variable named:"
  echo_env_example "ROOT_PASSWORD" "secret"
  exit 1
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
  VOLUME_SIZE="10"
fi

# REGION from env, or default
if undefined $REGION; then
  REGION="tor1"
fi

# FS_TYPE from env, or default
if undefined $FS_TYPE; then
  FS_TYPE="ext4"
fi

# WEBHOOK from env or secret
WEBHOOK="$(env_or_file WEBHOOK /run/secrets/webhook)"


# ---------------------------------------------------------
# Droplet functions
# ---------------------------------------------------------

droplets_by_tag() {
  defined $1 || return  
  doctl compute droplet list --no-header --format "ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Status,Tags" --tag-name="$1"
}

droplet_by_tag() {
  defined $1 || return  
  droplets_by_tag $1 | head -n1
}

has_droplet() {
  defined $1 || return
  defined $(get_droplet_id $1)
}

droplet_active() {
  defined $1 || return 1
  [ "$(droplet_by_tag :$1 | awk '{print $7}')" = "active" ] && return 0
  return 1
}

droplet_ready() {
  defined $1 || return 1
  droplet_active $1 && run $1 "ls /root" | grep platform > /dev/null && return 0
  return 1
}

get_droplet_id() {
  defined $1 || return
  droplet_by_tag :$1 | awk '{print $1}'
}

get_droplet_public_ip() {
  defined $1 || return
  droplet_by_tag :$1 | awk '{print $3}'
}

get_droplet_private_ip() {
  defined $1 || return
  droplet_by_tag :$1 | awk '{print $4}'
}

# Get memory as integer (in GB)
get_droplet_memory() {
  defined $1 || return
  local mem
  mem=$(droplet_by_tag :$1 | awk '{print $5}')
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
  droplet_by_tag :$1 | awk '{print $6}'
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

get_swarm_primary() {
  defined $1 || return
  local primary
  primary=$(droplet_by_tag :primary_${1} | awk '{print $2}')
  defined $primary && echo $primary || echo $1
}

# Look up number of existing replicas in swarm (optionally including additions, without removals)
get_swarm_replicas() {

  defined $1 || return
  local swarm=$1 additions=$2 removals=$3 keep= current_replicas= replicas=

  # Start with current replicas
  current_replicas="$(droplets_by_tag :replica_${1} | awk '{print $2}' | args)"

  # Loop through all current replicas + additions
  for node in $(echo "$current_replicas $additions" | args); do

    # Add most to the $replicas variable, but skip those contained within $removals
    keep=yes
    for removal in $removals; do
      [ "$removal" = "$node" ] && keep=no 
    done
    [ "$keep" = "yes" ] && replicas+="$node " 

  done

  # Return (potentially modified) replicas 
  echo $replicas | args

}

# Check if droplets ready 
droplets_ready() {

  defined $1 || return
  nodes=$1

  echo_next "Checking nodes... [$nodes]"

  nodes_ready="yes"
  for node in $nodes; do
    echo -n "$node "
    if droplet_ready $node; then 
      echo_color green "✓" 
    else
      echo_color red "✕" 
      nodes_ready=no
    fi
  done

  if [ "${nodes_ready}" = "no" ]; then
    return 1
  else
    return 0
  fi

}

reset_changes() {
  rm -f /tmp/changes.txt
}

set_changes() {
  touch /tmp/changes.txt
}

has_changes() {
  has /tmp/changes.txt && return 0
  return 1
}

reset_reserved() {
  echo "" > /tmp/reserved.txt
}

has_reserved() {
  defined $1 || return 1
  touch /tmp/reserved.txt
  [[ "$(cat /tmp/reserved.txt)" =~ "[${replica_name}]" ]] && return 0
  return 1
}

add_reserved() {
  defined $1 || return 1
  has_reserved $1 || echo "[${1}]" >> /tmp/reserved.txt
}

get_swarm_promotion() {
  defined $1 || return
  defined $2 || return

  local swarm_name=$1 primary= promotion=

  # Get primary node in swarm
  primary=$(get_swarm_primary $swarm_name)
  defined $primary || return

  # Get node to promote
  promotion=$(parse_args ^ ${@:2} | after_first | first)

  # Only return if droplet exists and isn't already primary
  if has_droplet $promotion; then
    if [ "${promotion}" != "${primary}" ]; then
      echo $promotion | xargs
    fi
  fi

}

# Look for -mynode or -2 args and sort them into named/numbered
parse_args() {
  defined $1 || return
  defined $2 || return

  local arg val named numbered=0

  for arg in ${@:2}; do
    if [ "${arg:0:1}" = $1 ]; then
      val="${arg:1}"
      if [[ $val =~ ^[0-9]+$ ]]; then 
        numbered=$(($numbered + $val))
      else
        named+="${val} "
      fi
    fi
  done

  echo "${numbered} ${named}" | args
}

get_swarm_removals() {
  defined $1 || return
  defined $2 || return

  local swarm_name=$1 primary=
  local named_removals="" numbered_removals=0

  # Get primary node in swarm
  primary=$(get_swarm_primary $swarm_name)
  defined $primary || return

  # Get nodes to remove
  numbered_removals=$(parse_args - ${@:2} | first)
  named_removals=$(parse_args - ${@:2} | after_first)

  # Build removals with node names available
  local i next removals

  # Add all the named removals, so long as it's not primary
  for next in $named_removals; do
    if [ "${next}" != "${primary}" ]; then
      has_droplet $next && removals="${removals} ${next}"
    fi
  done

  # Get existing replicas
  replicas="$(get_swarm_replicas $swarm_name | rargs)"

  # Add to the list of nodes to remove
  for i in $(seq $numbered_removals); do
    removals="${removals} $(echo $replicas | awk '{print $1}')"
    replicas="$(echo $replicas | awk '{$1=""}1' | xargs)"
  done
  
  # Return all these together
  echo $removals | args

}

get_swarm_additions() {
  defined $1 || return
  defined $2 || return

  local swarm_name=$1
  local named_additions="" numbered_additions=0

  # Get nodes to add
  numbered_additions=$(parse_args + ${@:2} | first)
  named_additions=$(parse_args + ${@:2} | after_first)

  # Build additions with node names available
  local i next additions
  reset_reserved

  # Add all the named additions, so long as it doesn't yet exist
  for next in $named_additions; do
    next=$(echo $next | awk '{print tolower($0)}')
    has_droplet $next || additions="${additions} ${next}"
    add_reserved $next
  done

  # Generate names for nodes that were added via number (ie: +3)
  for i in $(seq $numbered_additions); do
    next=$(next_replica_name $swarm_name)
    additions="${additions} ${next}"
  done
  
  # Return all these together
  echo $additions | args

}

# Find the next available droplet name in a swarm
next_replica_name() {
  local swarm_name=$1 replica_name pad i

  for i in $(seq 99); do
    pad="" && [ $i -lt 10 ] && pad="0"
    replica_name="${swarm_name}${pad}${i}"
    if ! has_reserved $replica_name; then
      add_reserved $replica_name
      has_droplet $replica_name || break
    fi
  done

  echo $replica_name
}


# ---------------------------------------------------------
# Show droplet info
# ---------------------------------------------------------
echo_droplet_info() {
  defined $1 || return
  
  local droplet_name=$1 droplet_size droplet_cpu droplet_cpu_env droplet_memory droplet_memory_env
  
  echo_header "DROPLET: ${DROPLET_IMAGE} / ${REGION}"
  
  if has_droplet $droplet_name; then
    
    droplet_size=$(get_droplet_size $droplet_name)
    
    droplet_cpu=$(get_droplet_cpu_from_size $droplet_size)
    droplet_cpu_env=$(get_droplet_cpu_from_size $DROPLET_SIZE)
    
    droplet_memory=$(get_droplet_memory_from_size $droplet_size)
    droplet_memory_env=$(get_droplet_memory_from_size $DROPLET_SIZE)    
    
    if [ $droplet_cpu_env != $droplet_cpu ] || [ $droplet_memory_env != $droplet_memory ]; then
      set_changes
      echo_droplet_size $droplet_name "${droplet_size}" "${DROPLET_SIZE}" "(update)"
    else
      echo_droplet_size $droplet_name "${droplet_size}" "${DROPLET_SIZE}" "(no change)"
    fi
    
  else
    set_changes
    echo_droplet_size $droplet_name "..." "${DROPLET_SIZE}" "(new)"
  fi
  
}


# ---------------------------------------------------------
# Create droplet
# ---------------------------------------------------------
create_droplet() {

  defined $1 || return
  defined $DOMAIN || return
  defined $REGION || return
  defined $DROPLET_SIZE || return
  defined $DROPLET_IMAGE || return
  defined $ROOT_PASSWORD || return
  defined $ROOT_PUBLIC_KEY || return
  
  local node_name=$1

  local swarm_name=$2
  undefined $2 && swarm_name="$node_name"
  
  local role=$3
  undefined $3 && role="primary"
  [ $role != "primary" ] && role="replica"
  
  # Download cloud-config.yml and fill out variables
  local config=/tmp/cloud-config.yml
  curl -sL https://github.com/nonfiction/platform/raw/master/swarm/lib/cloud-config.yml > $config
  sed -i "s/__NAME__/${node_name}/" $config
  sed -i "s/__DOMAIN__/${DOMAIN}/" $config
  sed -i "s|__ROOT_PUBLIC_KEY__|${ROOT_PUBLIC_KEY}|" $config
  sed -i "s|__WEBHOOK__|${WEBHOOK}|" $config
  
  echo_next "Creating droplet $node_name"
  doctl compute droplet create $node_name \
    --region="${REGION}" \
    --size="${DROPLET_SIZE}" \
    --image="${DROPLET_IMAGE}" \
    --tag-names=":swarm,:swarm_${swarm_name},:${role}_${swarm_name},:${node_name}" \
    --user-data-file="$config" \
    --volumes="$(get_volume_id $node_name)" \
    --enable-private-networking \
    --enable-monitoring \
    --enable-backups \
    --format="ID,Name,PublicIPv4,PrivateIPv4,Memory,VCPUs,Tags" \
    --verbose \
    --wait

  # Clean-up
  rm -f $config

}

# Delete this droplet forever and ever
remove_droplet() {
  defined $1 || return

  local droplet_name=$1 droplet_id=
  droplet_id=$(get_droplet_id $droplet_name)
  
  # Delete existing droplet
  if defined $droplet_id; then
    echo_next "Deleting droplet $droplet_name"
    doctl compute droplet delete $droplet_id --force
  fi
}


# ---------------------------------------------------------
# Resize droplet
# ---------------------------------------------------------

resize_droplet() { 
  defined $1 || return
  defined $2 || return
  
  local droplet_name=$1 primary_name=$2 droplet_id=
  local droplet_id droplet_size droplet_cpu droplet_cpu_env droplet_memory droplet_memory_env
  
  droplet_id=$(get_droplet_id $droplet_name)
  droplet_size=$(get_droplet_size $droplet_name)
    
  droplet_cpu=$(get_droplet_cpu_from_size $droplet_size)
  droplet_cpu_env=$(get_droplet_cpu_from_size $DROPLET_SIZE)
    
  droplet_memory=$(get_droplet_memory_from_size $droplet_size)
  droplet_memory_env=$(get_droplet_memory_from_size $DROPLET_SIZE)    
    
  if [ $droplet_cpu_env != $droplet_cpu ] || [ $droplet_memory_env != $droplet_memory ]; then
    echo_next "RESIZING droplet $droplet_name"

    echo_run $primary_name "docker node update --availability=drain ${droplet_name}"
    echo "Waiting 30 seconds for node to drain..."
    sleep 30

    echo_next "Turning OFF and RESIZING droplet $droplet_name"
    echo_run "doctl compute droplet-action resize $droplet_id --size=${DROPLET_SIZE} --verbose --wait"

    echo_next "Turning ON droplet $droplet_name"
    echo_run "doctl compute droplet-action power-on $droplet_id --verbose --wait"

    echo "Waiting 20 seconds for node to boot..."
    sleep 20

    echo_run $primary_name "docker node update --availability=active ${droplet_name}"

    echo_info "Droplet $droplet_name resized!"

  fi

}


# ---------------------------------------------------------
# Create/Resize droplet
# ---------------------------------------------------------

create_or_resize_droplet() {
  defined $1 || return
  
  local node_name=$1 swarm_name=$2 role=$3
  
  if has_droplet $node_name; then
    resize_droplet $node_name $swarm_name
  else
    create_droplet $node_name $swarm_name $role
  fi
  
}



# ---------------------------------------------------------
# Volume functions
# ---------------------------------------------------------

has_volume() {
  defined $(get_volume_id "$1")
}

get_volume_id() {
  doctl compute volume list --format "ID,Name,Size,Tags" | grep " $1 " | awk '{print $1}'
}

get_volume_size() {  
  doctl compute volume list --format "ID,Name,Size,Tags" | grep " $1 " | awk '{print $3}'
}

# ---------------------------------------------------------
# Show Volume Info
# ---------------------------------------------------------

echo_volume_info() {
  
  local volume_size
  
  echo_header "VOLUME: ${FS_TYPE} / ${REGION}"
  
  if has_volume $1; then
    volume_size=$(get_volume_size $1)

    if [ "$VOLUME_SIZE" -gt "$volume_size" ]; then 
      set_changes
      echo_volume_size $1 "${volume_size}GB" "${VOLUME_SIZE}GB" "(expand)"
    else
      echo_volume_size $1 "${volume_size}GB" "${VOLUME_SIZE}GB" "(no change)"
    fi
    
  else
    set_changes
    echo_volume_size "${node}" "..." "${VOLUME_SIZE}GB" "(new)"
  fi
  
}


# ---------------------------------------------------------
# Create volume
# ---------------------------------------------------------

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
  
  echo_next "Creating volume $volume_name"
  doctl compute volume create $volume_name \
    --region="${REGION}" \
    --size="${VOLUME_SIZE}GiB" \
    --fs-type="${FS_TYPE}" \
    --format="ID,Name,Size,Tags" \
    --tag=":swarm,:swarm_${swarm_name},:${role}_${swarm_name},:${volume_name}" 
}


# Delete this volume forever and ever
remove_volume() {

  defined $1 || return  
  local volume_name=$1 droplet_name=$1 volume_id= droplet_id=

  volume_id="$(get_volume_id $volume_name)"
  droplet_id="$(get_droplet_id $droplet_name)"
  
  # Detach volume from droplet and delete
  if defined $volume_id && defined $droplet_id; then

    echo_next "Detaching volume ${volume_name} from droplet ${droplet_name}"
    doctl compute volume-action detach $volume_id $droplet_id --wait

    echo_next "Deleting volume $volume_name"
    doctl compute volume delete $volume_id --force

  fi

}


# ---------------------------------------------------------
# Resize volume
# ---------------------------------------------------------

resize_volume() { 

  defined $1 || return  
  local volume_name=$1 droplet_name=$1 volume_id= droplet_id=
  
  defined $REGION || return
  defined $VOLUME_SIZE || return

  if [ "$VOLUME_SIZE" -gt "$(get_volume_size $volume_name)" ]; then 
    echo_next "EXPANDING volume $volume_name"

    volume_id="$(get_volume_id $volume_name)"
    droplet_id="$(get_droplet_id $droplet_name)"

    # Stop the brick before resizing 
    env="BEFORE_RESIZE=1 NAME=${droplet_name}"
    echo_run $droplet_name "${env} /root/platform/swarm/node/gluster"

    # Detach volume from droplet
    doctl compute volume-action detach "$volume_id" "$droplet_id" --wait

    # Resize volume
    doctl compute volume-action resize "$volume_id" \
      --region="$REGION" \
      --size="$VOLUME_SIZE" \
      --wait 

    # Re-attach volume to droplet
    doctl compute volume-action attach "$volume_id" "$droplet_id" --wait

    # Resize volume on node and start using the brick again
    env="AFTER_RESIZE=1 NAME=${droplet_name}"
    echo_run $droplet_name "${env} /root/platform/swarm/node/gluster"

    echo_info "Volume $volume_name expanded!"

  else
    echo_info "Volume $volume_name unchanged"
  fi
  
}

# ---------------------------------------------------------
# Create/Resize volume
# ---------------------------------------------------------

create_or_resize_volume() {
  if has_volume $1; then    
    resize_volume $1
  else
    create_volume $1 $2 $3
  fi
}



# ---------------------------------------------------------
# DNS record functions
# ---------------------------------------------------------

records_by_name() {
  defined $DOMAIN || return
  defined $1 || return
  doctl compute domain records list $DOMAIN --format "ID,Name,Data" | grep -F " $1 "
}

record_by_name() {
  defined $1 || return
  records_by_name $1 | head -n1
}

has_record() {
  defined $1 || return
  defined $(get_record_id $1)
}

get_record_id() {
  defined $1 || return
  record_by_name $1 | awk '{print $1}'
}

get_record_data() {
  defined $1 || return
  record_by_name $1 | awk '{print $3}'
}


# ---------------------------------------------------------
# Show DNS records
# --------------------------------------------------------- 

echo_record_info() {
  
  defined $1 || return
  defined $DOMAIN || return  
  
  local droplet_name=$1 droplet_ip
  droplet_ip="$(get_droplet_public_ip $1)"
  defined $droplet_ip || droplet_ip="?"

  echo_header "DNS RECORDS: ${DOMAIN}"
  
  # Display public record and wildcard record
  for record_name in $droplet_name *.$droplet_name; do

    record_data=$(get_record_data $record_name)
    if defined "$record_data" && [ "$record_data" = "$droplet_ip" ]; then
      echo_record_data "${record_name}" "${record_data}" "(no change)"
    elif defined "$record_data" && [ "$record_data" != "$droplet_ip" ]; then
      set_changes
      echo_record_data "${record_name}" "${droplet_ip}" "(update)"
    else
      set_changes
      echo_record_data "${record_name}" "${droplet_ip}" "(new)"
    fi

  done
  
}


# ---------------------------------------------------------
# Creaate/Update DNS record
# --------------------------------------------------------- 

create_or_update_record() {
  defined $1 || return
  defined $2 || return  
  defined $DOMAIN || return
  
  local record_name=$1 record_data=$2 record_id
  record_id=$(get_record_id $record_name)
  
  # Update existing DNS record
  if defined $record_id; then
    
    if [ "$record_data" = "$(get_record_data $record_name)" ]; then
      echo_info "Record ${record_name} unchanged"

    else
      echo_next "Updating record $record_name"
      doctl compute domain records update $DOMAIN \
      --record-id="${record_id}" \
      --record-data="${record_data}" \
      --format="ID,Type,Name,Data,TTL"
    fi
    
  # Create new DNS record
  else
    echo_next "Creating record $record_name"
    doctl compute domain records create $DOMAIN \
    --record-type="A" \
    --record-name="${record_name}" \
    --record-data="${record_data}" \
    --record-ttl="300" \
    --format="ID,Type,Name,Data,TTL"
  fi

}

remove_record() {
  defined $1 || return
  defined $DOMAIN || return

  local record_name=$1 record_id=
  record_id=$(get_record_id $record_name)
  
  # Delete existing DNS record
  if defined $record_id; then
    echo_next "Deleting record $record_name"
    doctl compute domain records delete $DOMAIN $record_id --force
  fi
}


# ---------------------------------------------------------
# Run SSH command on droplet
# --------------------------------------------------------- 

# First arg is the node name, all other args are commands
# run test01 touch ~/file.txt 
run() {

  defined "$ROOT_PRIVATE_KEY" || return
  defined $1 || return

  # Get the IP address of the droplet
  local name=$1 ip= key=
  ip="$(get_droplet_public_ip $name)"

  # Temporarily save the private key as a file
  key="/tmp/key-$(echo '('`date +"%s.%N"` ' * 1000000)/1' | bc).txt"
  echo "$ROOT_PRIVATE_KEY" > $key
  chmod 400 $key

  # SSH with the private and pass any commands
  ssh -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR \
      -i $key root@$ip "${@:2}"

  # Remove the temporary private key
  rm -f $key

}

# Echo the command before running it. 
# If 2 parameters, first one is remote, second is command to run on remote
# If 1 parameter, the command is run locally
echo_run() {
  defined $1 || return
  if defined $2; then
    echo "[${1}] ${2}"
    run "${1}" "${2}"
  else
    echo "$1"
    $1
  fi
}


# ---------------------------------------------------------
# Header & Row helper functions
# ---------------------------------------------------------

# Print header row for node
echo_node_header() {
  defined $1 || return
  defined $2 || return
  local node_name=$1 role=$2
  echo_main "$(has_droplet $node_name && echo "EXISTING" || echo "NEW") ${role^^}: ${node_name}"
}

# Print divider
echo_divider() {
  printf "%2s %-60s %-2s\n" "|" " " "|"
  printf "%2s %-60s %-2s\n" "|" "============================================================" "|"
}

# Print header row for section
echo_header() {
  printf "%2s %-60s %-2s\n" "|" " " "|"
  printf "%2s %-60s %-2s\n" "|" " $1" "|"
  printf "%2s %-60s %-2s\n" "|" "------------------------------------------------------------" "|"
}


# Print row for DNS record
echo_record_data() { 
  printf "%2s %25s %-2s %-15s %-14s %2s\n" "|" "$1" "=>" "$2" "$3" "|"
}

# Print row for droplet
echo_droplet_size() {
  printf "%2s %-10s %14s %-2s %-15s %-14s %2s\n" "|" " $1" "$2" "=>" "$3" "$4" "|"
}

# Print row for volume
echo_volume_size() {
  printf "%2s %-19s %5s %-2s %-15s %-14s %2s\n" "|" " $1" "$2" "=>" "$3" "$4" "|"
}

# Show price chart for droplet sizes
echo_droplet_prices() {
  local f="Slug,Disk,PriceMonthly"
  doctl compute size list --format="$f" | head -1 && \
  doctl compute size list --format="$f" | grep --color=never -e "s-[0-9]vcpu-[0-9]gb "
  echo_env_example "DROPLET_SIZE" "s-2vcpu-2gb"
}
