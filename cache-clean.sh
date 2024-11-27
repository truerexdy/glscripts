#!/bin/bash
cd $HOME/.cache/
rm -rf *
cd
sudo pacman -Scc
yay -Scc
sudo pacman -Rs $(sudo pacman -Qtdq)
yay -Rs $(yay -Qtdq)
