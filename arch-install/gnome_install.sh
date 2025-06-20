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

print_status "Updating system packages..."
sudo pacman -Syu --noconfirm

print_status "Installing Wayland display server..."
sudo pacman -S --noconfirm wayland

print_status "Installing minimal GNOME desktop environment..."
sudo pacman -S --noconfirm \
    gnome-shell \
    gnome-session \
    gnome-desktop \
    gnome-control-center \
    nautilus

print_status "Installing essential GNOME utilities..."
sudo pacman -S --noconfirm \
    gnome-keyring \
    gnome-settings-daemon \
    gnome-screenshot \
    gnome-system-monitor \
    gnome-disk-utility \
    gnome-calculator \
    gnome-clocks

print_status "Installing system utilities..."
sudo pacman -S --noconfirm \
    networkmanager \
    network-manager-applet \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    git \
    wget \
    curl \
    htop \
    unzip \
    zip


print_status "Enabling NetworkManager..."
sudo systemctl enable NetworkManager

print_status "Cleaning pacman cache..."
sudo pacman -Sc --noconfirm

print_status "Removing orphaned packages..."
if pacman -Qtdq > /dev/null 2>&1; then
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm
    print_success "Orphaned packages removed."
else
    print_status "No orphaned packages found."
fi

print_status "Performing final cache cleanup..."
sudo pacman -Scc --noconfirm

print_success "Minimal GNOME with Wayland installation completed successfully!"
print_warning "To start GNOME, run 'gnome-session' from a TTY (Ctrl+Alt+F2)"
print_status "GNOME will automatically use Wayland when available."

echo
read -p "Would you like to reboot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Rebooting system..."
    sudo reboot
else
    print_status "Please reboot manually when ready."
fi
