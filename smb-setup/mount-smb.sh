#!/bin/bash
set -e
sudo mount -t cifs //192.168.1.0/share/ $HOME/rexdynas -o username=rexdy
