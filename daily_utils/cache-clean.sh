#!/bin/bash

set -euo pipefail

clean_user_cache_and_tmp() {
    echo "Cleaning user cache and temporary files in $HOME/..."
    find "$HOME"/.local/share/Trash/ -mindepth 1 -delete 2>/dev/null || true
    find "$HOME"/.cache/ -mindepth 1 -delete 2>/dev/null || true
    find "$HOME"/.tmp/ -mindepth 1 -delete 2>/dev/null || true
    echo "User cache and temporary files cleaned."
}

clean_system_cache_and_tmp() {
    echo "Cleaning system cache and temporary files (requires sudo)..."
    sudo find /tmp/ -mindepth 1 -delete 2>/dev/null || true
    sudo find /var/tmp/ -mindepth 1 -delete 2>/dev/null || true
    sudo find /var/cache/ -mindepth 1 -delete 2>/dev/null || true
    echo "System cache and temporary files cleaned."
}

clean_package_cache_pacman() {
    echo "Cleaning Pacman cache (requires sudo)..."
    sudo pacman -Scc --noconfirm
    echo "Pacman cache cleaned."
}

clean_package_cache_yay() {
    if command -v yay &> /dev/null; then
        echo "Cleaning Yay cache..."
        yay -Scc --noconfirm
        echo "Yay cache cleaned."
    else
        echo "Yay not found. Skipping Yay cache cleanup."
    fi
}

remove_orphaned_packages_pacman() {
    echo "Removing orphaned Pacman packages (requires sudo)..."
    if sudo pacman -Qtdq &> /dev/null; then
        ORPHANED_PACKAGES=$(sudo pacman -Qtdq)
        echo "Found orphaned Pacman packages: $ORPHANED_PACKAGES"
        sudo pacman -Rs --noconfirm $ORPHANED_PACKAGES
        echo "Orphaned Pacman packages removed."
    else
        echo "No orphaned Pacman packages found."
    fi
}

remove_orphaned_packages_yay() {
    if command -v yay &> /dev/null; then
        echo "Removing orphaned Yay packages..."
        if yay -Qtdq &> /dev/null; then
            ORPHANED_PACKAGES=$(yay -Qtdq)
            echo "Found orphaned Yay packages: $ORPHANED_PACKAGES"
            yay -Rs --noconfirm $ORPHANED_PACKAGES
            echo "Orphaned Yay packages removed."
        else
            echo "No orphaned Yay packages found by Yay."
        fi
    else
        echo "Yay not found. Skipping orphaned Yay package removal."
    fi
}

main() {
    echo "Starting system cleanup..."

    clean_user_cache_and_tmp
    clean_package_cache_yay
    remove_orphaned_packages_yay

    clean_system_cache_and_tmp
    clean_package_cache_pacman
    remove_orphaned_packages_pacman

    echo "System cleanup completed."
}

main

exit 0
