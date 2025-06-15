#!/bin/bash

set -e

read -rp "Do you want to set up CUPS (Common Unix Printing System)? (y/n): " setup_cups
setup_cups=$(echo "$setup_cups" | tr '[:upper:]' '[:lower:]')

if [ "$setup_cups" = "y" ]; then
    echo "Setting up CUPS..."
    sudo pacman -Syu cups
    sudo systemctl enable cups.service
    sudo systemctl start cups.service
    echo "CUPS has been installed and started."
else
    echo "CUPS setup skipped."
fi

echo ""
read -rp "Do you want to set up the Hyprland Desktop environment? (y/n): " setup_hyprland
setup_hyprland=$(echo "$setup_hyprland" | tr '[:upper:]' '[:lower:]')

if [ "$setup_hyprland" = "y" ]; then
    echo "Setting up Hyprland Desktop..."

sudo pacman -S networkmanager bluez bluez-utils pipewire pipewire-pulse pipewire-alsa ntfs-3g sway swaybg swaylock swayidle waybar wl-clipboard grim slurp vlc imv foot ibus gvfs gvfs-mtp scrcpy wofi nautilus mako lxsession lightdm zip unzip nvim xdg-desktop-portal xdg-desktop-portal-wlr fontconfig ttf-dejavu noto-fonts udisks2 brightnessctl pavucontrol alsa-utils lightdm lightdm-gtk-greeter terminator

    echo "Copying dotfiles..."
    mkdir -p ~/.config/
    if [ -d "dotconfig" ]; then
        cp -r dotconfig/* ~/.config/
        echo "Dotfiles copied."
    else
        echo "Warning: 'dotconfig' directory not found. Skipping dotfile copy."
    fi

    echo "Copying fonts..."
    if [ -d "assets/MyFonts" ]; then
        sudo cp -r assets/MyFonts /usr/share/fonts/
        sudo fc-cache -fv
        echo "Fonts copied and cache updated."
    else
        echo "Warning: 'assets/MyFonts' directory not found. Skipping font copy."
    fi

    echo "Hyprland setup complete. You may need to configure greetd manually."
else
    echo "Hyprland Desktop setup skipped. Performing minimal install."
fi

echo ""
read -rp "Do you want to set up Bluetooth? (y/n): " setup_bluetooth
setup_bluetooth=$(echo "$setup_bluetooth" | tr '[:upper:]' '[:lower:]')

if [ "$setup_bluetooth" = "y" ]; then
    echo "Setting up Bluetooth..."
    sudo pacman -Syu bluez bluez-utils
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service
    echo "Bluetooth setup complete."
else
    echo "Bluetooth setup skipped."
fi

echo ""
read -rp "Do you want to install Yay (AUR helper) and common AUR packages (visual-studio-code-bin)? (y/n): " setup_yay
setup_yay=$(echo "$setup_yay" | tr '[:upper:]' '[:lower:]')

if [ "$setup_yay" = "y" ]; then
    echo "Setting up Yay and installing AUR packages..."
    sudo pacman -Syu go git base-devel # Ensure build tools are installed

    YAY_DIR="yay_build"
    echo "Cloning Yay repository..."
    if [ -d "$YAY_DIR" ]; then
        echo "Removing existing $YAY_DIR directory..."
        rm -rf "$YAY_DIR"
    fi
    git clone https://aur.archlinux.org/yay.git "$YAY_DIR"
    cd "$YAY_DIR" || { echo "Error: Failed to change directory to $YAY_DIR. Exiting."; exit 1; }

    echo "Building and installing Yay..."
    makepkg -si
    cd ..
    rm -rf "$YAY_DIR"
    echo "Yay installed successfully."

    echo "Installing official repository packages: sof-firmware ibus avahi"
    sudo pacman -S sof-firmware ibus avahi

    echo "Yay and common additional packages setup complete."
else
    echo "Yay and common additional packages setup skipped."
fi

echo ""
read -rp "Do you want to install and configure auto-cpufreq for CPU optimization? (y/n): " setup_autocpufreq
setup_autocpufreq=$(echo "$setup_autocpufreq" | tr '[:upper:]' '[:lower:]')

if [ "$setup_autocpufreq" = "y" ]; then
    echo "Setting up auto-cpufreq..."
    echo "Installing auto-cpufreq from AUR..."
    yay -S auto-cpufreq
    echo "Copying auto-cpufreq configuration..."
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
