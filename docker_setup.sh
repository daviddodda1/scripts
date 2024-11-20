#!/bin/bash

# Exit on any error
set -e

echo "Starting Docker and Docker Compose installation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check OS
get_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Function to check architecture
get_arch() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) echo "unknown" ;;
    esac
}

# Remove old versions of Docker
remove_old_docker() {
    echo "Removing old Docker versions (if any)..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
}

# Install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
}

# Install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    remove_old_docker
    install_dependencies

    echo "Adding Docker's official GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "Setting up Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "Installing Docker Engine..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Install Docker on CentOS/RHEL
install_docker_centos() {
    echo "Installing yum-utils..."
    sudo yum install -y yum-utils

    echo "Adding Docker repository..."
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    echo "Installing Docker Engine..."
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Configure Docker post-installation
configure_docker() {
    echo "Performing post-installation steps..."
    
    # Create docker group if it doesn't exist
    if ! getent group docker > /dev/null; then
        sudo groupadd docker
    fi

    # Add current user to docker group
    sudo usermod -aG docker $USER

    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker

    echo "Testing Docker installation..."
    sudo docker run hello-world
}

# Create useful Docker aliases
create_docker_aliases() {
    echo "Creating Docker aliases..."
    
    # Backup existing .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
    fi

    # Add Docker aliases
    cat >> "$HOME/.bashrc" << 'EOL'

# Docker aliases
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs'
alias dprune='docker system prune -af'
alias dstop='docker stop $(docker ps -q)'
alias drmall='docker rm $(docker ps -a -q)'
EOL

    # If zsh is installed, add aliases there too
    if [ -f "$HOME/.zshrc" ]; then
        cat >> "$HOME/.zshrc" << 'EOL'

# Docker aliases
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs'
alias dprune='docker system prune -af'
alias dstop='docker stop $(docker ps -q)'
alias drmall='docker rm $(docker ps -a -q)'
EOL
    fi
}

# Create basic Docker Compose example
create_compose_example() {
    echo "Creating Docker Compose example..."
    mkdir -p ~/docker-compose-example
    
    cat > ~/docker-compose-example/docker-compose.yml << 'EOL'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: unless-stopped

  db:
    image: postgres:alpine
    environment:
      POSTGRES_PASSWORD: example
      POSTGRES_USER: myuser
      POSTGRES_DB: mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
EOL

    # Create example HTML file
    mkdir -p ~/docker-compose-example/html
    cat > ~/docker-compose-example/html/index.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Compose Test</title>
</head>
<body>
    <h1>Docker Compose is working!</h1>
    <p>If you can see this page, your Docker setup is complete.</p>
</body>
</html>
EOL

    echo "Docker Compose example created in ~/docker-compose-example/"
}

# Main installation function
main() {
    local os
    os=$(get_os)

    echo "Detected OS: $os"
    echo "Detected architecture: $(get_arch)"

    case $os in
        ubuntu|debian)
            install_docker_ubuntu
            ;;
        centos|rhel|fedora)
            install_docker_centos
            ;;
        *)
            echo "Unsupported operating system: $os"
            exit 1
            ;;
    esac

    configure_docker
    create_docker_aliases
    create_compose_example

    echo "Installation complete!"
    echo "Please log out and log back in for Docker group changes to take effect."
    echo ""
    echo "To test your installation:"
    echo "1. Log out and log back in"
    echo "2. Run: docker --version"
    echo "3. Run: docker compose version"
    echo "4. Try the example compose file in ~/docker-compose-example/"
    echo "   cd ~/docker-compose-example/ && docker compose up -d"
}

main
