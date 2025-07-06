#!/usr/bin/env bash
# utilisation.sh — report CPU & RAM usage every INTERVAL seconds
set -euo pipefail
IFS=$'\n\t'

# Default interval (seconds)
INTERVAL=10

usage() {
  cat <<EOF
Usage: $(basename "$0") [-i seconds] [-h]

  -i seconds   Poll interval in seconds (default: $INTERVAL)
  -h           Show this help message
EOF
  exit 1
}

# parse args
while getopts ":i:h" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ensure INTERVAL is a positive integer
if ! [[ $INTERVAL =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: interval must be a positive integer." >&2
  exit 2
fi

# cleanup on SIGINT/SIGTERM
cleanup() {
  echo "Interrupted; exiting." >&2
  exit 0
}
trap cleanup INT TERM

# check dependencies
for cmd in top free awk grep; do
  command -v "$cmd" >/dev/null \
    || { echo "Error: '$cmd' not found." >&2; exit 3; }
done

# metric functions
get_cpu() {
  # subtract idle (%) from 100
  top -bn1 | grep "Cpu(s)" \
    | awk '{printf("%.1f", 100 - $8)}'
}

get_ram() {
  # used/total * 100
  free | awk '/Mem:/ {printf("%.1f", $3/$2*100)}'
}

get_space() {
  # used/total * 100
  df -h /mount/point | awk 'NR==2 {print $5}'
}

# header
echo "Press Ctrl-C to stop. Poll every $INTERVAL s."

# main loop
while true; do
  timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
  cpu=$(get_cpu)
  ram=$(get_ram)
  hdd=$(get_space)
  printf '%s  CPU: %5s%%  RAM: %5s%% HDD:%5s\n' "$timestamp" "$cpu" "$ram" "$hdd"
  sleep "$INTERVAL"
done
