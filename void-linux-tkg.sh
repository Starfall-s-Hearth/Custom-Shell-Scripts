#!/bin/bash

# Set variables
REPO_DIR="$HOME/void-packages"        # Directory for void-packages
BUILD_SCRIPT="$HOME/setup_build.sh"    # Path to your existing build setup script
KERNEL_NAME="linux-tkg"                # Name of the kernel package to build
ARCH="x86_64"                          # Architecture (adjust if necessary)
LOG_FILE="$HOME/kernel_build.log"      # Log file for capturing output

# Function to check for required commands
check_dependencies() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed. Please install it and try again." | tee -a "$LOG_FILE"
            exit 1
        fi
    done
}

# Check for required dependencies
check_dependencies curl make xbps-src

# Check if the repository directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Directory $REPO_DIR does not exist. Running setup script..." | tee -a "$LOG_FILE"
    
    # Check if the setup script exists before attempting to run it
    if [ -f "$BUILD_SCRIPT" ]; then
        bash "$BUILD_SCRIPT" | tee -a "$LOG_FILE"  # Run the setup script if the directory is missing
    else
        echo "Error: Setup script $BUILD_SCRIPT not found. Exiting." | tee -a "$LOG_FILE"
        exit 1  # Exit with an error code if the setup script is missing
    fi
else
    echo "Directory $REPO_DIR already exists." | tee -a "$LOG_FILE"
fi

# Change to the repository directory
cd "$REPO_DIR" || { echo "Failed to change directory to $REPO_DIR. Exiting." | tee -a "$LOG_FILE"; exit 1; }

# Check if xbps-src is initialized before building
if [ ! -d "hostdir" ]; then
    echo "xbps-src is not initialized. Please run the setup script first." | tee -a "$LOG_FILE"
    exit 1  # Exit if xbps-src has not been initialized
fi

# Copy Void Linux's default .config file for the kernel
DEFAULT_CONFIG_URL="https://github.com/void-linux/void-packages/raw/master/srcpkgs/linux/files/${ARCH}-dotconfig"
CONFIG_FILE="$REPO_DIR/srcpkgs/linux/files/${ARCH}-dotconfig"

echo "Downloading default .config file for $ARCH architecture..." | tee -a "$LOG_FILE"
curl -L -o "$CONFIG_FILE" "$DEFAULT_CONFIG_URL" 2>>"$LOG_FILE"

# Prompt user to make changes using menuconfig
echo "You can now customize your kernel configuration." | tee -a "$LOG_FILE"
cd "$REPO_DIR/srcpkgs/linux" || { echo "Failed to change directory to srcpkgs/linux. Exiting." | tee -a "$LOG_FILE"; exit 1; }
make menuconfig

# Run make oldconfig to update .config with new options
echo "Running 'make oldconfig' to update configuration..." | tee -a "$LOG_FILE"
make oldconfig 2>>"$LOG_FILE"

# After updating, continue with building the kernel package using all available processor cores
echo "Building the kernel package: $KERNEL_NAME..." | tee -a "$LOG_FILE"
cd "$REPO_DIR" || { echo "Failed to change directory back to $REPO_DIR. Exiting." | tee -a "$LOG_FILE"; exit 1; }
if ./xbps-src pkg -j$(nproc) "$KERNEL_NAME" >>"$LOG_FILE" 2>&1; then
    echo "Installing the package..." | tee -a "$LOG_FILE"
    sudo xbps-install --repository=hostdir/binpkgs "$KERNEL_NAME" >>"$LOG_FILE" 2>&1
else
    echo "Error: Build failed. Cleaning up..." | tee -a "$LOG_FILE"
    cd "$REPO_DIR/srcpkgs/linux" || { echo "Failed to change directory back to srcpkgs/linux. Exiting." | tee -a "$LOG_FILE"; exit 1; }
    make clean >>"$LOG_FILE" 2>&1  # Clean up previous build artifacts
    exit 1      # Exit with an error code if the build fails
fi

echo "Kernel package $KERNEL_NAME has been successfully installed." | tee -a "$LOG_FILE"