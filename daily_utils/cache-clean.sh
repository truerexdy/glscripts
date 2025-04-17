#!/bin/bash
rm -rf $HOME/.local/share/Trash/*
rm -rf $HOME/.cache/*
rm -rf $HOME/.tmp/*
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo rm -rf /var/cache/*
echo "Removed Cache and tmp files"
sudo pacman -Scc --noconfirm
yay -Scc --noconfirm
sudo pacman -Rs --noconfirm $(sudo pacman -Qtdq)
yay -Rs --noconfirm $(yay -Qtdq)
