#!/bin/bash

set -e

echo "Starting optional Arch Linux setup."

read -rp "Elevate privileges for setup? (y/n): " confirm_sudo
confirm_sudo=$(echo "$confirm_sudo" | tr '[:upper:]' '[:lower:]')

if [ "$confirm_sudo" = "y" ]; then
    if ! sudo -v; then
        echo "Sudo authentication failed or cancelled. Exiting."
        exit 1
    fi
else
    echo "Sudo privileges not confirmed. Exiting."
    exit 1
fi

essential=(
    "firefox"
    "gnome-clocks"
    "qalculate-gtk"
    "htop"
    "okular"
    "gedit"
    "pavucontrol"
    "grim"
    "keepassxc"
    "ffmpeg"
    "baobab"
)

devel=(
    "docker"
    "git"
    "curl"
    "gcc"
    "go"
    "make"
    "cmake"
)

prod=(
    "libreoffice"
    "gnome-calendar"
    "obsidian"
)

read -rp "Install essential packages? (y/N): " install_essential
install_essential=$(echo "$install_essential" | tr '[:upper:]' '[:lower:]')

if [ "$install_essential" = "y" ]; then
    echo "Installing essential packages."
    sudo pacman -S --noconfirm "${essential[@]}"
else
    echo "Essential package installation skipped."
fi

echo ""
read -rp "Install development packages? (y/N): " install_devel
install_devel=$(echo "$install_devel" | tr '[:upper:]' '[:lower:]')

if [ "$install_devel" = "y" ]; then
    echo "Installing development packages."
    sudo pacman -S --noconfirm "${devel[@]}"
else
    echo "Development package installation skipped."
fi

echo ""
read -rp "Install productivity packages? (y/N): " install_prod
install_prod=$(echo "$install_prod" | tr '[:upper:]' '[:lower:]')

if [ "$install_prod" = "y" ]; then
    echo "Installing productivity packages."
    sudo pacman -S --noconfirm "${prod[@]}"
else
    echo "Productivity package installation skipped."
fi

echo ""
echo "Script finished."
echo "Reboot recommended."

exit 0
