#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "==============================================="
echo "Arch Linux Setup Script"
echo "==============================================="
echo "This script assumes you are running it as a non-root user"
echo "with sudo privileges and that you have a basic Arch install."
echo "It will guide you through installing common software and setting up"
echo "components like CUPS, Hyprland, and Bluetooth."
echo ""
echo "Press Enter to continue or Ctrl+C to exit."
read -r

# --- CUPS Setup ---
echo ""
read -rp "Do you want to set up CUPS (Common Unix Printing System)? (y/n): " setup_cups
setup_cups=$(echo "$setup_cups" | tr '[:upper:]' '[:lower:]')

if [ "$setup_cups" = "y" ]; then
    echo "Setting up CUPS..."
    sudo pacman -Syu --noconfirm cups
    sudo systemctl enable cups.service
    sudo systemctl start cups.service
    echo "CUPS has been installed and started."
else
    echo "CUPS setup skipped."
fi

# --- Hyprland Desktop Setup ---
echo ""
read -rp "Do you want to set up the Hyprland Desktop environment? (y/n): " setup_hyprland
setup_hyprland=$(echo "$setup_hyprland" | tr '[:upper:]' '[:lower:]')

if [ "$setup_hyprland" = "y" ]; then
    echo "Setting up Hyprland Desktop..."
    sudo pacman -Syu --noconfirm hyprland wofi waybar swaylock swayidle swww dunst polkit greetd greetd-tuigreet xorg-xwayland gcc python3 pulseaudio curl htop fastfetch nautilus pipewire vlc firefox alsa-utils terminator network-manager-applet gvfs-mtp gvfs-gphoto2 qalculate-gtk eog xdg-utils
    sudo systemctl enable pipewire.service # Enable pipewire user service
    sudo systemctl start pipewire.service # Start pipewire user service

    echo "Copying dotfiles..."
    mkdir -p ~/.config/
    # Ensure dotconfig directory exists before copying
    if [ -d "dotconfig" ]; then
        cp -r dotconfig/* ~/.config/
        echo "Dotfiles copied."
    else
        echo "Warning: 'dotconfig' directory not found. Skipping dotfile copy."
    fi

    echo "Copying fonts..."
    # Ensure assets/MyFonts directory exists before copying
    if [ -d "assets/MyFonts" ]; then
        sudo cp -r assets/MyFonts /usr/share/fonts/
        # Update font cache
        sudo fc-cache -fv
        echo "Fonts copied and cache updated."
    else
        echo "Warning: 'assets/MyFonts' directory not found. Skipping font copy."
    fi

    echo "Hyprland setup complete. You may need to configure greetd manually."
else
    echo "Hyprland Desktop setup skipped. Performing minimal install."
fi

# --- Bluetooth Setup ---
echo ""
read -rp "Do you want to set up Bluetooth? (y/n): " setup_bluetooth
setup_bluetooth=$(echo "$setup_bluetooth" | tr '[:upper:]' '[:lower:]')

if [ "$setup_bluetooth" = "y" ]; then
    echo "Setting up Bluetooth..."
    sudo pacman -Syu --noconfirm bluez bluez-utils
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service
    echo "Bluetooth setup complete."
else
    echo "Bluetooth setup skipped."
fi

# --- Yay (AUR Helper) Setup ---
echo ""
read -rp "Do you want to install Yay (AUR helper) and common AUR packages (visual-studio-code-bin)? (y/n): " setup_yay
setup_yay=$(echo "$setup_yay" | tr '[:upper:]' '[:lower:]')

if [ "$setup_yay" = "y" ]; then
    echo "Setting up Yay and installing AUR packages..."
    sudo pacman -Syu --noconfirm go git base-devel # Ensure build tools are installed

    # Clone Yay, build, and install
    YAY_DIR="yay_build"
    echo "Cloning Yay repository..."
    if [ -d "$YAY_DIR" ]; then
        echo "Removing existing $YAY_DIR directory..."
        rm -rf "$YAY_DIR"
    fi
    git clone https://aur.archlinux.org/yay.git "$YAY_DIR"
    cd "$YAY_DIR" || { echo "Error: Failed to change directory to $YAY_DIR. Exiting."; exit 1; }

    echo "Building and installing Yay..."
    makepkg -si --noconfirm
    cd .. # Return to original directory
    rm -rf "$YAY_DIR" # Clean up build directory
    echo "Yay installed successfully."

    # Install AUR packages using Yay (excluding auto-cpufreq for now)
    echo "Installing AUR packages: visual-studio-code-bin"
    yay -S --noconfirm visual-studio-code-bin

    # Install official repository packages
    echo "Installing official repository packages: sof-firmware ibus avahi"
    sudo pacman -S --noconfirm sof-firmware ibus avahi

    echo "Yay and common additional packages setup complete."
else
    echo "Yay and common additional packages setup skipped."
fi

# --- auto-cpufreq Setup ---
echo ""
read -rp "Do you want to install and configure auto-cpufreq for CPU optimization? (y/n): " setup_autocpufreq
setup_autocpufreq=$(echo "$setup_autocpufreq" | tr '[:upper:]' '[:lower:]')

if [ "$setup_autocpufreq" = "y" ]; then
    echo "Setting up auto-cpufreq..."
    # Install auto-cpufreq using Yay
    echo "Installing auto-cpufreq from AUR..."
    yay -S --noconfirm auto-cpufreq

    echo "Copying auto-cpufreq configuration..."
    # Ensure assets directory exists before copying
    if [ -f "assets/auto-cpufreq.conf" ]; then
        sudo cp assets/auto-cpufreq.conf /etc/
        echo "auto-cpufreq configuration copied."
    else
        echo "Warning: 'assets/auto-cpufreq.conf' not found. Skipping config copy."
    fi
    echo "auto-cpufreq setup complete."
else
    echo "auto-cpufreq setup skipped."
fi


echo ""
echo "==============================================="
echo "Script finished."
echo "Please reboot your system for changes to take effect."
echo "==============================================="

exit 0
