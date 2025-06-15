#!/bin/bash

set -e
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

detect_cpu() {
    if lscpu | grep -q "AuthenticAMD"; then
        MICROCODE="amd-ucode"
    elif lscpu | grep -q "GenuineIntel"; then
        MICROCODE="intel-ucode"
    else
        MICROCODE=""
    fi
}

detect_gpu() {
    GPU_PACKAGES=""
    
    if lspci | grep -i nvidia &> /dev/null; then
        GPU_PACKAGES+="nvidia nvidia-utils "
    fi
    
    if lspci | grep -i -E "(amd|ati|radeon)" &> /dev/null; then
        GPU_PACKAGES+="mesa vulkan-radeon "
    fi
    
    if lspci | grep -i "intel.*graphics" &> /dev/null; then
        GPU_PACKAGES+="mesa vulkan-intel "
    fi
    
    if [[ -z "$GPU_PACKAGES" ]]; then
        GPU_PACKAGES="mesa"
    fi
}

is_laptop() {
    [[ -d "/sys/class/power_supply/BAT"* ]]
}

echo "Starting Arch Linux post-installation setup..."
echo "Updating system..."
pacman -Syu --noconfirm

echo "Detecting hardware..."
detect_cpu
detect_gpu

echo "Installing base packages..."
BASE_PACKAGES="neovim sudo git ufw networkmanager network-manager-applet base-devel grub efibootmgr linux-firmware"

if [[ -n "$MICROCODE" ]]; then
    BASE_PACKAGES+=" $MICROCODE"
fi

pacman -S --noconfirm $BASE_PACKAGES

echo "Installing GPU drivers..."
pacman -S --noconfirm $GPU_PACKAGES

if is_laptop; then
    echo "Laptop detected, installing power management..."
    pacman -S --noconfirm tlp
    systemctl enable tlp
fi

echo "Installing audio system..."
pacman -S --noconfirm pipewire pipewire-pulse wireplumber

if ! command -v grub-install &> /dev/null; then
    echo "Essential packages did not install correctly. Exiting."
    exit 1
fi

echo "Configuring GRUB..."
EFI_DIR="/boot"
if [[ -d "/boot/efi" ]]; then
    EFI_DIR="/boot/efi"
fi

grub-install --target=x86_64-efi --efi-directory="$EFI_DIR" --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabling services..."
systemctl enable NetworkManager
systemctl enable systemd-timesyncd
ufw --force enable

echo "Configuring locale..."
if ! grep -q "^en_IN.UTF-8 UTF-8" /etc/locale.gen; then
    echo "en_IN.UTF-8 UTF-8" >> /etc/locale.gen
fi
locale-gen
echo "LANG=en_IN.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "Setting hostname..."
while true; do
    read -rp "Enter hostname: " hname
    if [[ "$hname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] && [[ ${#hname} -le 63 ]]; then
        echo "$hname" > /etc/hostname
        cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hname.localdomain $hname
EOF
        break
    else
        echo "Invalid hostname format."
    fi
done

echo "Setting root password:"
passwd

echo "Configuring timezone..."
if [[ -f "/usr/share/zoneinfo/Asia/Kolkata" ]]; then
    ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
    hwclock --systohc
fi

echo "Creating user..."
read -rp "Enter username: " uname
if [[ "$uname" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
    useradd -m -G wheel "$uname"
    passwd "$uname"
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

read -rp "Disable root login for security? (y/n): " disable_root
if [[ "$disable_root" == "y" ]]; then
    passwd -l root
    echo "Root account disabled. Use sudo with your user account."
fi

echo "Arch Linux setup complete. Reboot recommended."
exit 0
