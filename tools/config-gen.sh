#!/bin/bash

# Usage: ./config-gen.sh m002

machine_id="${1}"
caps_id="$(echo "$machine_id" | tr '[:lower:]' '[:upper:]')"
template="$HOME/demo/configs/config.json"
output="$HOME/demo/configs/${machine_id}.json"

jq \
  --arg m "$machine_id" \
  --arg c "$caps_id" \
  --arg p "$caps_id" \
  '.PROJECT_NAME = $p | .MACHINE_ID_CAPS = $c | .MACHINE_ID = $m' \
  "$template" > "$output"