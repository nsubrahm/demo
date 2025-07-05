#!/bin/bash
# install-docker.sh: Production-grade Docker install script for Ubuntu
# Usage: sudo ./install-docker.sh [username]

set -euo pipefail

USER_NAME="${1:-${SUDO_USER:-$USER}}"

log() {
    echo "[install-docker] $1"
}

main() {
    log "Updating apt package index..."
    sudo apt-get update

    log "Installing prerequisites..."
    sudo apt-get install -y ca-certificates curl gnupg

    log "Adding Docker's official GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    log "Adding Docker repository to apt sources..."
    echo \
      "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    log "Updating apt package index (post-repo add)..."
    sudo apt-get update

    log "Installing Docker Engine and related packages..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    log "Adding user $USER_NAME to docker group..."
    sudo usermod -aG docker "$USER_NAME"

    log "Adding helpful aliases to ~/.bashrc..."
    grep -qxF "alias a=aws" ~/.bashrc || echo "alias a=aws" >> ~/.bashrc
    grep -qxF "alias d=docker" ~/.bashrc || echo "alias d=docker" >> ~/.bashrc
    grep -qxF "alias n=nano" ~/.bashrc || echo "alias n=nano" >> ~/.bashrc

    log "Docker installation and setup complete. Please log out and log back in for group changes to take effect."
}

main "$@"
