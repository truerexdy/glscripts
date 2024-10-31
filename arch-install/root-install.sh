#!/bin/bash

pacman -Syu
pacman -S nano sudo git ufw networkmanager base-devel grub efibootmgr
grub-install
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable systemd-journald
systemctl enable NetworkManager
ufw enable

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
touch /etc/locale.conf
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
touch /etc/vconsole.conf
echo "KEYMAP=us" >> /etc/vconsole.conf


read -p "Do you want to set hostname? (y/n) " uin
uin=$(echo "$uin" | tr '[:upper:]' '[:lower:]')
if [[ $uin = y ]]; then
    read -p "Enter the hostname: " hname
    if [[ ! $hname =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
        echo "Invalid hostname format. Only alphanumeric characters and hyphens allowed."
        exit 1
    fi
    touch /etc/hostname
    echo "$hname" > /etc/hostname
    echo "Hostname set successfully."
else
    echo "Continuing without a hostname"
fi

echo "Enter Root Password:"
passwd

ln -sf /usr/share/zoneinfo/Asia/Calcutta /etc/localtime
hwclock --systohc

systemctl enable systemd-timesyncd


read -p "Do you want to add a user? (y/n) " uin  
uin=$(echo "$uin" | tr '[:upper:]' '[:lower:]')

if [[ $uin == "y" ]]; then
    read -p "Enter username: " uname
    if id "$uname" &> /dev/null; then
        echo "User $uname already exists."
    else
        useradd -m "$uname"
        passwd "$uname"
        echo "User $uname added successfully."
    fi
else
    echo "Continuing without adding a user. Only root user."
fi


echo "WARNING"
echo "WARNING"
echo "WARNING"
echo "Perform the following critical steps: "
echo "1. CHANGE THE UUID IN arch.conf"
echo "2. ADD HOSTNAME, if not added"
echo "WARNING"
echo "WARNING"
echo "WARNING"


exit 0
