#!/bin/bash

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
