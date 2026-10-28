#!/usr/bin/env bash
USER="ТВОЙ_ЛОГИН"
REPO="capri-ios"
git branch -M main
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/${USER}/${REPO}.git"
git push -u origin main
