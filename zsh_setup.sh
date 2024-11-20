#!/bin/bash

# Exit on any error
set -e

echo "Starting ZSH environment setup..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install required packages
install_dependencies() {
    echo "Installing dependencies..."
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y zsh curl git
    elif command_exists yum; then
        sudo yum update -y
        sudo yum install -y zsh curl git
    else
        echo "Package manager not supported. Please install zsh, curl, and git manually."
        exit 1
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    echo "Installing Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh is already installed"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

# Install Starship
install_starship() {
    echo "Installing Starship prompt..."
    if command_exists starship; then
        echo "Starship is already installed"
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
}

# Install useful Oh My Zsh plugins
install_plugins() {
    echo "Installing Oh My Zsh plugins..."
    
    # zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    
    # zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
}

# Configure .zshrc
configure_zshrc() {
    echo "Configuring .zshrc..."
    
    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
    fi
    
    # Create new .zshrc with custom configuration
    cat > "$HOME/.zshrc" << 'EOL'
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme to "clean" (Starship will override this)
ZSH_THEME="clean"

# Configure plugins
plugins=(
    git
    docker
    kubectl
    zsh-autosuggestions
    zsh-syntax-highlighting
    history
    colored-man-pages
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Initialize Starship prompt
eval "$(starship init zsh)"

# Useful aliases
alias ll='ls -lah'
alias zshconfig='nano ~/.zshrc'
alias reload='source ~/.zshrc'
EOL
}

# Configure Starship
configure_starship() {
    echo "Configuring Starship..."
    mkdir -p ~/.config
    cat > ~/.config/starship.toml << 'EOL'
# Starship configuration

[character]
success_symbol = "[➜](bold green) "
error_symbol = "[✗](bold red) "

[cmd_duration]
min_time = 500
format = "took [$duration](bold yellow)"

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = "🌱 "
truncation_length = 20

[git_status]
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
EOL
}

# Main installation process
main() {
    install_dependencies
    install_oh_my_zsh
    install_starship
    install_plugins
    configure_zshrc
    configure_starship
    
    echo "Installation complete! Please restart your terminal or run:"
    echo "exec zsh"
    echo "To start using your new shell environment."
}

main
