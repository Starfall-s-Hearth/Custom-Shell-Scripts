#!/bin/bash

# Define variables
ISO_NAME="custom_void_iso"  # Name of the output ISO file
OUTPUT_DIR="$HOME/iso_output"  # Directory to store the created ISO
TKG_KERNEL_DIR="$HOME/linux-tkg"  # Directory for linux-tkg kernel

# Function to install required packages
install_packages() {
    echo "Installing required packages..."
    sudo xbps-install -y base-devel gcc binutils make ncurses-devel bison flex openssl-devel elfutils-devel u-boot-tools python3 bc lz4 git || {
        echo "Failed to install required packages. Exiting."
        exit 1
    }
}

# Function to clone linux-tkg repository
clone_linux_tkg() {
    if [ ! -d "$TKG_KERNEL_DIR" ]; then
        echo "Cloning linux-tkg repository..."
        git clone https://github.com/Frogging-Family/linux-tkg.git "$TKG_KERNEL_DIR" || {
            echo "Failed to clone linux-tkg repository. Exiting."
            exit 1
        }
    else
        echo "linux-tkg repository already exists."
    fi
}

# Function to configure and compile the linux-tkg kernel
compile_kernel() {
    echo "Configuring and compiling linux-tkg kernel..."
    cd "$TKG_KERNEL_DIR" || {
        echo "Failed to change directory to $TKG_KERNEL_DIR. Exiting."
        exit 1
    }

    # Edit customization.cfg for optimizations (modify as needed)
    sed -i 's/^_configfile=.*/_configfile="running-kernel"/' customization.cfg

    # Compile and install the kernel
    chmod +x install.sh
    ./install.sh install || {
        echo "Kernel compilation failed. Exiting."
        exit 1
    }

    echo "Kernel compilation complete."
}

# Function to update GRUB configuration
update_grub() {
    echo "Updating GRUB configuration..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg || {
        echo "Failed to update GRUB configuration. Exiting."
        exit 1
    }
}

# Function to create a custom ISO with the new kernel
create_custom_iso() {
    echo "Creating custom ISO..."
    mkdir -p "$OUTPUT_DIR"
    
    # Install void-mklive if not already installed
    if ! command -v void-mklive &> /dev/null; then
        echo "Installing void-mklive..."
        sudo xbps-install -y void-mklive || {
            echo "Failed to install void-mklive. Exiting."
            exit 1
        }
    fi

    # Create the ISO with a list of packages (adjust as necessary)
    PACKAGES="i3 gimp inkscape audacity lmms zettlr taskwarrior dunst redshift neovim ranger feh mpv flatpak"
    
    sudo void-mklive -o "$OUTPUT_DIR/$ISO_NAME.iso" -p "$PACKAGES" || {
        echo "Failed to create custom ISO. Exiting."
        exit 1
    }

    echo "Custom ISO created at: $OUTPUT_DIR/$ISO_NAME.iso"
}

# Main script execution with error handling for each function call
{
    install_packages
    clone_linux_tkg
    compile_kernel
    update_grub
    create_custom_iso

} || {
    echo "An error occurred during the execution of the script. Please check the output for details."
}

echo "All tasks completed successfully. Please reboot your system."