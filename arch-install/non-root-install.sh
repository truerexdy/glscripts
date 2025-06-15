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

read -rp "Set up CUPS? (y/n): " setup_cups
setup_cups=$(echo "$setup_cups" | tr '[:upper:]' '[:lower:]')

if [ "$setup_cups" = "y" ]; then
    echo "Setting up CUPS."
    sudo pacman -Syu --noconfirm cups
    sudo systemctl enable cups.service
    sudo systemctl start cups.service
    echo "CUPS installed."
else
    echo "CUPS setup skipped."
fi

read -rp "Set up Bluetooth? (y/n): " setup_bluetooth
setup_bluetooth=$(echo "$setup_bluetooth" | tr '[:upper:]' '[:lower:]')

if [ "$setup_bluetooth" = "y" ]; then
    echo "Setting up Bluetooth."
    sudo pacman -Syu --noconfirm bluez bluez-utils
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service
    echo "Bluetooth setup complete."
else
    echo "Bluetooth setup skipped."
fi

read -rp "Set up Desktop Environment? (y/n): " setup_desktop_env
setup_desktop_env=$(echo "$setup_desktop_env" | tr '[:upper:'] '[:lower:]')

if [ "$setup_desktop_env" = "y" ]; then
    echo "Installing desktop environment packages."
    DESKTOP_ENV_PACKAGES=(
        networkmanager ntfs-3g sway swaybg swaylock swayidle waybar wl-clipboard grim slurp vlc imv ibus gvfs gvfs-mtp scrcpy wofi nautilus mako lxsession lightdm zip unzip neovim xdg-desktop-portal xdg-desktop-portal-wlr fontconfig ttf-dejavu noto-fonts udisks2 brightnessctl pavucontrol alsa-utils lightdm lightdm-gtk-greeter terminator tmux tar unzip adw-gtk3 qt5ct qt6ct
    )
    sudo pacman -Syu --noconfirm "${DESKTOP_ENV_PACKAGES[@]}"

    echo "Configuring dark theme."
    mkdir -p ~/.config/gtk-3.0
    {
        echo "[Settings]"
        echo "gtk-application-prefer-dark-theme=true"
        echo "gtk-theme=Adwaita-dark"
        echo "gtk-icon-theme=Adwaita"
    } >> ~/.config/gtk-3.0/settings.ini

    mkdir -p ~/.config/gtk-4.0
    {
        echo "[Settings]"
        echo "gtk-application-prefer-dark-theme=true"
        echo "gtk-theme=Adwaita-dark"
        echo "gtk-icon-theme=Adwaita"
    } >> ~/.config/gtk-4.0/settings.ini

    mkdir -p ~/.config/qt5ct
    {
        echo "[Settings]"
        echo "icon_theme=Adwaita"
        echo "color_scheme=3"
        echo "standard_dialogs=default"
        echo "style=Adwaita-Dark"
    } >> ~/.config/qt5ct/qt5ct.conf

    mkdir -p ~/.config/qt6ct
    {
        echo "[Settings]"
        echo "icon_theme=Adwaita"
        echo "color_scheme=3"
        echo "standard_dialogs=default"
        echo "style=Adwaita-Dark"
    } >> ~/.config/qt6ct/qt6ct.conf

    echo 'export QT_QPA_PLATFORMTHEME="qt5ct"' | sudo tee -a /etc/profile.d/qt5ct.sh > /dev/null
    echo 'export QT_STYLE_OVERRIDE="Adwaita-Dark"' | sudo tee -a /etc/profile.d/qt5ct.sh > /dev/null
    echo 'export GTK_THEME="Adwaita-dark"' | sudo tee -a /etc/profile.d/gtk-dark.sh > /dev/null
    echo 'export XDG_CURRENT_DESKTOP="sway"' | sudo tee -a /etc/profile.d/xdg-desktop.sh > /dev/null
    echo 'export COLOR_SCHEME="dark"' | sudo tee -a /etc/profile.d/color-scheme.sh > /dev/null

    echo "Copying dotfiles."
    mkdir -p ~/.config/
    if [ -d "dotconfig" ]; then
        cp -r dotconfig/* ~/.config/
        echo "Dotfiles copied."
    else
        echo "Warning: 'dotconfig' not found. Skipping dotfile copy."
    fi

    echo "Copying fonts."
    if [ -d "assets/MyFonts" ]; then
        sudo cp -r assets/MyFonts /usr/share/fonts/
        sudo fc-cache -fv
        echo "Fonts copied and cache updated."
    else
        echo "Warning: 'assets/MyFonts' not found. Skipping font copy."
    fi

    echo "Desktop environment setup complete. Configure greetd manually."
else
    echo "Desktop environment setup skipped."
fi

read -rp "Install Yay and common AUR packages? (y/n): " setup_yay
setup_yay=$(echo "$setup_yay" | tr '[:upper:]' '[:lower:]')

if [ "$setup_yay" = "y" ]; then
    echo "Setting up Yay."
    sudo pacman -Syu --noconfirm go git base-devel

    YAY_DIR="yay_build"
    if [ -d "$YAY_DIR" ]; then
        echo "Removing existing $YAY_DIR."
        rm -rf "$YAY_DIR"
    fi
    git clone https://aur.archlinux.org/yay.git "$YAY_DIR"
    cd "$YAY_DIR" || { echo "Error: Failed to change directory to $YAY_DIR. Exiting."; exit 1; }

    echo "Building and installing Yay."
    makepkg -si --noconfirm
    cd ..
    rm -rf "$YAY_DIR"
    echo "Yay installed."

    echo "Installing official repository packages: sof-firmware ibus avahi."
    sudo pacman -S --noconfirm sof-firmware ibus avahi

else
    echo "Yay setup skipped."
fi

if [ "$setup_yay" = "y" ]; then
    read -rp "Install and configure auto-cpufreq? (y/n): " setup_autocpufreq
    setup_autocpufreq=$(echo "$setup_autocpufreq" | tr '[:upper:'] '[:lower:]')

    if [ "$setup_autocpufreq" = "y" ]; then
        echo "Setting up auto-cpufreq."
        echo "Installing auto-cpufreq from AUR."
        yay -S --noconfirm auto-cpufreq
        echo "Copying auto-cpufreq configuration."
        if [ -f "assets/auto-cpufreq.conf" ]; then
            sudo cp assets/auto-cpufreq.conf /etc/
            echo "auto-cpufreq config copied."
        else
            echo "Warning: 'assets/auto-cpufreq.conf' not found. Skipping config copy."
        fi
        echo "auto-cpufreq setup complete."
    else
        echo "auto-cpufreq setup skipped."
    fi
else
    echo "auto-cpufreq setup skipped (requires Yay)."
fi

echo ""
echo "Script finished."
echo "Reboot recommended."

exit 0
