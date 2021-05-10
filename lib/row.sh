#!/bin/bash

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