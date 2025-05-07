#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "Starting Arch Linux post-installation setup..."

# Update system and install essential packages
echo "Updating system and installing essential packages..."
pacman -Syu --noconfirm
pacman -S --noconfirm neovim sudo git ufw networkmanager base-devel grub efibootmgr

# Check if packages were installed successfully (basic check)
if ! command -v grub-install &> /dev/null; then
    echo "Essential packages did not install correctly. Exiting."
    exit 1
fi

# Configure GRUB
echo "Configuring GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB # Assuming UEFI, adjust if needed
grub-mkconfig -o /boot/grub/grub.cfg

# Enable essential services
echo "Enabling essential services..."
systemctl enable systemd-journald
systemctl enable NetworkManager
ufw enable

# Configure locale and keymap
echo "Configuring locale and keymap..."
# Check if lines already exist before appending
grep -qxF "en_US.UTF-8 UTF-8" /etc/locale.gen || echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf # Overwrite to ensure only one LANG line
echo "KEYMAP=us" > /etc/vconsole.conf     # Overwrite to ensure only one KEYMAP line

# Set hostname
echo "Setting hostname..."
while true; do
    read -rp "Enter the hostname: " hname
    # Basic validation: starts with alphanumeric, contains only alphanumeric or hyphens
    if [[ "$hname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
        echo "$hname" > /etc/hostname
        echo "Hostname set successfully to $hname."
        break
    else
        echo "Invalid hostname format. Only alphanumeric characters and hyphens allowed, cannot start with a hyphen."
    fi
done

# Set root password
echo "Setting Root Password:"
passwd

# Configure timezone and time synchronization
echo "Configuring timezone and time synchronization..."
# Check if the timezone file exists before linking
if [[ -f "/usr/share/zoneinfo/Asia/Calcutta" ]]; then
    ln -sf /usr/share/zoneinfo/Asia/Calcutta /etc/localtime
    hwclock --systohc
    systemctl enable systemd-timesyncd
    echo "Timezone set to Asia/Calcutta and time sync enabled."
else
    echo "Warning: Timezone 'Asia/Calcutta' not found. Skipping timezone configuration."
fi


# Add a new user (optional)
echo "User creation (optional)..."
read -rp "Do you want to add a user? (y/n) " uin
uin=$(echo "$uin" | tr '[:upper:]' '[:lower:]')

if [[ "$uin" == "y" ]]; then
    read -rp "Enter username: " uname
    # Validate username format (basic)
    if [[ "$uname" =~ ^[a-z_][a-z0-9_]{0,30}$ ]]; then # Basic Linux username regex
        if id "$uname" &> /dev/null; then
            echo "User $uname already exists."
        else
            useradd -m "$uname"
            # Check if useradd was successful
            if id "$uname" &> /dev/null; then
                echo "Set password for user $uname:"
                passwd "$uname"
                echo "User $uname added successfully."
            else
                echo "Error: Failed to create user $uname."
            fi
        fi
    else
        echo "Invalid username format. Usernames must start with a lowercase letter or underscore, followed by lowercase letters, digits, or underscores (max 31 characters)."
    fi
else
    echo "Continuing without adding a user. Only root user will be available initially."
fi

echo "Arch Linux post-installation setup complete."

exit 0
