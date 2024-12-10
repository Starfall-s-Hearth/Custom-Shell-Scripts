#!/bin/bash

# Define variables for directory and configuration file
REPO_DIR="$HOME/void-packages"
CONFIG_FILE="$REPO_DIR/etc/conf"

# Function to print error messages and exit
function error_exit {
    echo "Error: $1" >&2
    exit 1
}

# Welcome message
echo "Welcome! This script will update your system and set up the package builder."

# Update and upgrade the system packages
echo "Step 1: Updating system packages..."
sudo xbps-install -Syu || error_exit "Failed to update system."

# Install git if it is not already installed
echo "Step 2: Checking for git installation..."
sudo xbps-install -Sy git || error_exit "Failed to install git."

# Clone or update the void-packages repository
if [ ! -d "$REPO_DIR" ]; then
    echo "Step 3: Cloning the void-packages repository..."
    git clone https://github.com/void-linux/void-packages.git "$REPO_DIR" || error_exit "Failed to clone repository."
else
    echo "Step 3: Repository already exists. Updating it..."
    cd "$REPO_DIR" || error_exit "Cannot access $REPO_DIR."
    git pull || error_exit "Failed to update repository."
fi

# Change to the void-packages directory
cd "$REPO_DIR" || error_exit "Cannot access $REPO_DIR."

# Set up the package builder for musl architecture
echo "Step 4: Setting up the package builder for musl..."
./xbps-src binary-bootstrap x86_64-musl || error_exit "Package builder setup failed."

# Create a configuration file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Step 5: Creating configuration file with default settings..."
    echo "XBPS_ALLOW_RESTRICTED=yes" > "$CONFIG_FILE"
    # Add other custom configurations here if needed
fi

echo "All steps completed successfully! Your system is updated, and the package builder is set up in $REPO_DIR."