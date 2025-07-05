#!/bin/bash

#==============================#
# ML Job Container Launcher 🐳 #
#==============================#

MACHINE_ID="${1:-m001}"
CONTAINER_NAME_TAG="${2:-latest}"

ENV_FILE="${SCRIPT_DIR}/launch/conf/${MACHINE_ID}/ml-jobs.env"
DOCKER_IMAGE="ghcr.io/nsubrahm/analytics:${CONTAINER_NAME_TAG}"
CONTAINER_NAME="ml-jobs-${MACHINE_ID}"

SCRIPT_DIR="$HOME/launcher/launch/batch"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/ml-jobs-${MACHINE_ID}-$(date +'%Y%m%d_%H%M%S').log"

NETWORK="mitra"

REQUIRED_VARS=(SCHEMA_NAME MACHINE_ID SHIFT_START_HOUR SHIFT_DURATION_HOURS TZ)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

mkdir -p "$LOG_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
    log "ERROR: Env file '$ENV_FILE' not found."
    exit 1
fi

log "Sourcing environment from '$ENV_FILE'"
set -a
source "$ENV_FILE"
set +a

missing_vars=()
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log "ERROR: Missing required env variables:"
    for var in "${missing_vars[@]}"; do
        log "  - $var"
    done
    exit 2
fi

log "Launching ML job for '${MACHINE_ID}' using '${DOCKER_IMAGE}'"
docker run -d \
    --name "$CONTAINER_NAME" \
    --env-file "$ENV_FILE" \
    --network "$NETWORK" \
    "$DOCKER_IMAGE" >> "$LOG_FILE" 2>&1

if [[ $? -ne 0 ]]; then
    log "ERROR: Docker failed to start."
    exit 3
fi

exit 0