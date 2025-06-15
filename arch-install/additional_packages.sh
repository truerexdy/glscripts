#!/bin/bash

set -e

essential=(
    "firefox"
    "gnome-clocks"
    "qalculate-gtk"
    "ufw"
    "htop"
)

devel=(
    "docker"
    "git"
    "neovim"
    "curl"
    "gcc"
    "go"
)

prod=(
    "libreoffice"
    "thunderbird"
    "gimp"
    "gnome-calendar"
    "obsidian"
)

read -p "Install essential packages? (y/N) " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo pacman -S "${essential[@]}" --noconfirm
else
    echo "Operation cancelled (default)."
fi

echo ""
read -p "Install development packages? (y/N) " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo pacman -S "${devel[@]}" --noconfirm
else
    echo "Operation cancelled (default)."
fi

echo ""
read -p "Install productivity packages? (y/N) " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo pacman -S "${prod[@]}" --noconfirm
else
    echo "Operation cancelled (default)."
fi
