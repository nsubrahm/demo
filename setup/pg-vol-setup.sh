#!/bin/bash
# PostgreSQL Volume Setup Script
# This script sets up and mounts a new volume for PostgreSQL data and index directories.
# It is idempotent and safe to run multiple times.


set -euo pipefail

DEVICE="/dev/nvme1n1"
MOUNT_POINT="/mnt/pg"

# Parameters (can be set via environment or command line)
SCHEMA_NAME="${SCHEMA_NAME:-org1}"
MACHINE_ID="${MACHINE_ID:-m001}"

if [ $# -ge 1 ]; then
    SCHEMA_NAME="$1"
fi
if [ $# -ge 2 ]; then
    MACHINE_ID="$2"
fi

FSTAB_ENTRY="$DEVICE $MOUNT_POINT ext4 defaults,nofail 0 2"
DATA_DIR="$MOUNT_POINT/$SCHEMA_NAME/$MACHINE_ID/data"
INDX_DIR="$MOUNT_POINT/$SCHEMA_NAME/$MACHINE_ID/indx"
PG_UID=70
PG_GID=70

log() {
    echo "[pg-vol-setup] $1"
}

create_filesystem() {
    if mount | grep -q "^$DEVICE "; then
        log "$DEVICE is already mounted. Skipping mkfs."
        return
    fi
    if ! blkid $DEVICE | grep -q 'TYPE="ext4"'; then
        log "Creating ext4 filesystem on $DEVICE..."
        sudo mkfs.ext4 -F $DEVICE
    else
        log "$DEVICE already has an ext4 filesystem. Skipping mkfs."
    fi
}

create_mount_point() {
    if [ ! -d "$MOUNT_POINT" ]; then
        log "Creating mount point $MOUNT_POINT..."
        sudo mkdir -p "$MOUNT_POINT"
    fi
}

mount_volume() {
    if ! mountpoint -q "$MOUNT_POINT"; then
        log "Mounting $DEVICE to $MOUNT_POINT..."
        sudo mount "$DEVICE" "$MOUNT_POINT"
    else
        log "$MOUNT_POINT is already mounted."
    fi
}

add_to_fstab() {
    if ! grep -qs "^$DEVICE " /etc/fstab; then
        log "Adding $DEVICE to /etc/fstab..."
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
    else
        log "$DEVICE already present in /etc/fstab."
    fi
}

setup_data_dir() {
    log "Ensuring data directory $DATA_DIR exists and has correct permissions..."
    sudo mkdir -p "$DATA_DIR"
    sudo chown -R $PG_UID:$PG_GID "$DATA_DIR"
    sudo chmod 700 "$DATA_DIR"
}

setup_index_dir() {
    log "Ensuring index directory $INDX_DIR exists and has correct permissions..."
    sudo mkdir -p "$INDX_DIR"
    sudo chown -R $PG_UID:$PG_GID "$INDX_DIR"
    sudo chmod 700 "$INDX_DIR"
}

main() {
    create_filesystem
    create_mount_point
    mount_volume
    add_to_fstab
    setup_data_dir
    setup_index_dir
    log "PostgreSQL volume setup complete."
}

main "$@"
