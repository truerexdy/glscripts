#!/bin/bash

packages=(
    pciutils
    usbutils
    btop
    nvtop
    smartmontools
    sysstat
    iotop
    nload
    iftop
    ethtool
    iproute2
)

echo "Updating package database..."
sudo pacman -Sy

echo "Installing system monitoring tools..."
for pkg in "${packages[@]}"; do
    echo "Installing $pkg..."
    sudo pacman -S --noconfirm --needed "$pkg"
done

echo "Installation complete."
