#!/bin/bash

# ---------------------------------------------------------
# DNS record functions
# ---------------------------------------------------------

# has_record() {
#   defined "$(doctl compute domain records list $DOMAIN -o json | grep "\"name\": \"${1}\"" | head -n 1)"
# }

has_record() {
  defined $1 || return
  defined "$(get_record $1)"
}

get_record() {
  doctl compute domain records list $DOMAIN --format "ID,Name,Data" | grep -F " $1 " | awk '{print $3}'
}

# ---------------------------------------------------------
# Show DNS records
# --------------------------------------------------------- 
get_record_info() {
  
  defined $1 || return
  defined $DOMAIN || return  
  
  local public_record wildcard_record #private_record
  local droplet_public_ip #droplet_private_ip
  
  header_row "DNS RECORDS: ${DOMAIN}"
  
  droplet_public_ip="$(get_droplet_public_ip $1)"
  defined $droplet_public_ip || droplet_public_ip="?"
  # droplet_private_ip="$(get_droplet_private_ip $1)"
  # defined $droplet_private_ip || droplet_private_ip="?"
  
  public_record=$(get_record $1)
  if defined "$public_record" && [ "$public_record" = "$droplet_public_ip" ]; then
    record_row "${1}" "${public_record}" "(no change)"
  else
    touch /tmp/dirty.txt
    record_row "${1}" "${droplet_public_ip}" "(new)"
  fi
  
  wildcard_record=$(get_record "*.${1}")
  if defined "$wildcard_record" && [ "$wildcard_record" = "$droplet_public_ip" ]; then
    record_row "*.${1}" "${wildcard_record}" "(no change)"
  else
    touch /tmp/dirty.txt
    record_row "*.${1}" "${droplet_public_ip}" "(new)"
  fi
  
  # private_record=$(get_record "private.${1}")
  # if defined "$private_record" && [ "$private_record" = "$droplet_private_ip" ]; then
  #   record_row "private.${1}" "${private_record}" "(no change)"
  # else
  #   touch /tmp/dirty.txt
  #   record_row "private.${1}" "${droplet_private_ip}" "(new)"
  # fi
  
}

create_record() {
  defined $1 || return
  defined $2 || return  
  defined $DOMAIN || return
  
  if has_record $1; then
    echo "=> DNS record $1 already exists"
  else
    echo "=> Creating DNS record $1"
    doctl compute domain records create $DOMAIN \
    --record-name="$1" \
    --record-data="$2" \
    --record-type="A" \
    --record-ttl="300"
  fi
}
