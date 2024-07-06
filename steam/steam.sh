#!/bin/bash

# Get the machine hardware name
architecture=$(uname -m)

# Check if the architecture is x86_64 (AMD/Intel)
if [ "$architecture" != "x86_64" ]; then
    echo "This script only runs on AMD or Intel (x86_64) CPUs, not on $architecture."
    exit 1
fi

# Define URL base variable
# REPO_BASE_URL="${REPO_BASE_URL:-https://raw.githubusercontent.com/MacRimi/Super-Emulator/main/steam}"

# Define the options
OPTIONS=("1" "Instalar STEAM (a través de Arch Container)"
         "2" "Desinstalar STEAM"
         "3" "Actualizar accesos directos")

# Display the dialog and get the user choice
CHOICE=$(dialog --clear --backtitle "Arch Container Management" \
                --title "Main Menu" \
                --menu "Choose an option:" 20 90 3 \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear

# Act based on the user choice
case $CHOICE in
    1)
        echo "Installing Steam Container..."
        rm /tmp/runner 2>/dev/null
        wget -q --tries=30 --no-check-certificate --no-cache --no-cookies -O /tmp/runner "https://raw.githubusercontent.com/MacRimi/Super-Emulator/main/steam/install.sh"
        dos2unix /tmp/runner 2>/dev/null 
        chmod 777 /tmp/runner 2>/dev/null
        bash /tmp/runner
        ;;
    2)
        echo "Loading Uninstall script..."
        rm /tmp/runner 2>/dev/null
        wget -q --tries=30 --no-check-certificate --no-cache --no-cookies -O /tmp/runner "https://raw.githubusercontent.com/MacRimi/Super-Emulator/main/steam/uninstall.sh"
        dos2unix /tmp/runner 2>/dev/null 
        chmod 777 /tmp/runner 2>/dev/null
        bash /tmp/runner
        ;;
    3)  
        echo "Update EmulationStation Arch Container Launcher Shortcuts..."
        rm /tmp/runner 2>/dev/null
        wget -q --tries=30 --no-check-certificate --no-cache --no-cookies -O /tmp/runner "https://raw.githubusercontent.com/MacRimi/Super-Emulator/main/steam/update_shortcuts.sh"
        dos2unix /tmp/runner 2>/dev/null 
        chmod 777 /tmp/runner 2>/dev/null
        bash /tmp/runner
        ;;    
    *)
        echo "No valid option selected or cancelled. Exiting."
        ;;
esac
