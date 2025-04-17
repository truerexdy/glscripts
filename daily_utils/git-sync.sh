#!/bin/bash

git add .
git status
git commit -m "$(date +'%d %B %Y %H:%M:%S')"
git push -f origin main
