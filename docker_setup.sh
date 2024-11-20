#!/bin/bash

# Exit on any error
set -e

echo "Starting Docker installation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Ubuntu version
check_ubuntu_version() {
    if ! command_exists lsb_release; then
        echo "Error: lsb_release command not found. Please install lsb-release package."
        exit 1
    fi
    
    version=$(lsb_release -cs)
    supported=0
    
    # List of supported Ubuntu versions
    for v in "noble" "jammy" "focal" "mantic"; do
        if [ "$version" = "$v" ]; then
            supported=1
            break
        fi
    done

    if [ "$supported" -eq 0 ]; then
        echo "Error: Ubuntu version '${version}' is not supported."
        echo "Supported versions are: noble (24.04), jammy (22.04), focal (20.04), mantic (23.10)"
        exit 1
    fi
    
    echo "Detected Ubuntu version: ${version}"
}

# Remove old versions of Docker
remove_old_versions() {
    echo "Removing old Docker versions (if any)..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove -y $pkg 2>/dev/null || true
    done
}

# Install prerequisites
install_prerequisites() {
    echo "Installing prerequisites..."
    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
}

# Set up Docker's apt repository
setup_repository() {
    echo "Setting up Docker repository..."
    
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}

# Install Docker Engine
install_docker() {
    echo "Installing Docker Engine..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Configure Docker to run without sudo
configure_docker_user() {
    echo "Configuring Docker to run without sudo..."
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker $USER
    echo "Note: You'll need to log out and back in for this to take effect."
}

# Verify installation
verify_installation() {
    echo "Verifying installation..."
    if sudo docker run hello-world; then
        echo "Docker installation verified successfully!"
    else
        echo "Error: Docker verification failed!"
        exit 1
    fi
}

# Enable Docker service
enable_docker_service() {
    echo "Enabling Docker service..."
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
}

# Main installation process
main() {
    echo "Checking system requirements..."
    check_ubuntu_version
    
    echo "Starting Docker installation process..."
    remove_old_versions
    install_prerequisites
    setup_repository
    install_docker
    enable_docker_service
    configure_docker_user
    verify_installation
    
    echo "Docker installation completed successfully!"
    echo "Please log out and log back in to use Docker without sudo."
    echo ""
    echo "You can verify the installation after logging back in by running:"
    echo "docker --version"
    echo "docker compose version"
}

# Run main function
main
