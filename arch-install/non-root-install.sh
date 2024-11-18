#!/bin/bash

echo "This script assumes that you have already created a new user other than root and executing this script as that user."

sleep 3

read -rp "Do you want to Setup CUPS? This might be required to add printers. (y/n): " uin
uin=$(echo "$uin" | tr '[:upper:]' '[:lower:]')
if [ "$uin" = "y" ]; then
  sudo pacman -Syu cups
  sudo systemctl enable cups.service
  sudo systemctl start cups.service  
  echo "CUPS has been installed and started."
else
  echo "CUPS setup skipped."
fi

read -rp "Do you want to Setup i3-wm Desktop? (y/n): " uin
uin=$(echo "$uin" | tr '[:upper:]' '[:lower:]')
if [ "$uin" = "y" ]; then
  sudo pacman -Syu xorg xorg-xinit i3 feh gcc python3 pulseaudio curl htop neofetch thunar pipewire vlc lxdm firefox alsa-utils i3status dmenu terminator lxdm
  sudo systemctl enable lxdm
  sudo systemctl enable pipewire
  touch ~/.xinitrc
  echo "exec i3" >> ~/.xinitrc
  mkdir ~/.config/
  cp -r dotconfig/* ~/.config/
  sudo cp -r assets/MyFonts /usr/share/fonts/
else
  echo "Minimal Install"
fi

read -rp "Do you want to Setup Bluetooth? (y/n): " uin
uin=$(echo "$uin" | tr '[:upper:]' '[:lower:]')
if [ "$uin" = "y" ]; then
  sudo pacman -Syu bluez bluez-utils
  sudo systemctl enable bluetooth
else
  echo "No Bluetooth"
fi


sudo pacman -Syu go git
git clone https://aur.archlinux.org/yay.git
cd yay || cd ./
makepkg PKGBUILD
sudo pacman -U yay-*
yay -S thunar visual-studio-code-bin
sudo pacman -S sof-firmware ibus avahi

yay -S auto-cpufreq
sudo cp assets/auto-cpufreq.conf /etc/

exit 0
