#!/bin/bash
sudo pacman -Syu
sudo pacman -S gnome-shell gnome-control-center gnome-keyring gnome-shell nautilus eog
sudo pacman -Rs thunar
sudo pacman -Scc
exit
