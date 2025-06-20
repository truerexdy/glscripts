#!/bin/bash
set -e

if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run as root"
    exit 1
fi

if ! command -v sudo &> /dev/null; then
    echo "Error: sudo not found"
    exit 1
fi

echo "Updating system packages..."
sudo pacman -Syu --noconfirm

echo "Installing Wayland display server..."
sudo pacman -S --noconfirm wayland

echo "Installing minimal GNOME desktop environment..."
sudo pacman -S --noconfirm \
    gnome-shell \
    gnome-session \
    gnome-desktop \
    gnome-control-center \
    nautilus

echo "Installing essential GNOME utilities..."
sudo pacman -S --noconfirm \
    gnome-keyring \
    gnome-settings-daemon \
    gnome-screenshot \
    gnome-system-monitor \
    gnome-disk-utility \
    gnome-calculator \
    gnome-clocks

echo "Installing system utilities..."
sudo pacman -S --noconfirm \
   networkmanager \
   pipewire \
   pipewire-pulse \
   wireplumber

echo "Enabling NetworkManager..."
sudo systemctl enable NetworkManager

echo "Cleaning pacman cache..."
sudo pacman -Sc --noconfirm

echo "Removing orphaned packages..."
if pacman -Qtdq > /dev/null 2>&1; then
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm
    echo "Orphaned packages removed."
else
    echo "No orphaned packages found."
fi

echo "Performing final cache cleanup..."
sudo pacman -Scc --noconfirm

echo "Minimal GNOME with Wayland installation completed successfully!"
echo "To start GNOME, run 'gnome-session' from a TTY (Ctrl+Alt+F2)"
echo "GNOME will automatically use Wayland when available."

echo
read -p "Would you like to reboot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting system..."
    sudo reboot
else
    echo "Please reboot manually when ready."
fi
