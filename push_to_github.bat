@echo off
REM Замени USER и REPO на свои
set USER=akissed-lab
set REPO=capri-ios

git branch -M main
git remote remove origin 2>nul
git remote add origin https://github.com/%USER%/%REPO%.git
git push -u origin main
pause
