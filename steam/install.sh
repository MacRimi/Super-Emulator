#!/bin/bash

# Get the machine hardware name
architecture=$(uname -m)

# Check if the architecture is x86_64 (AMD/Intel)
if [ "$architecture" != "x86_64" ]; then
    echo "This script only runs on AMD or Intel (x86_64) CPUs, not on $architecture."
    exit 1
fi

MESSAGE="Este contenedor es compatible únicamente con particiones EXT4 o BTRFS. NTFS/EXFat no son compatibles. ¿Desea continuar?"

# Use dialog to create a yes/no box
if dialog --title "Compatibility Warning" --yesno "$MESSAGE" 10 70; then
    # If the user chooses 'Yes', continue the installation
    echo "Continuing installation..."
    # Add your installation commands here
else
    # If the user chooses 'No', exit the script
    echo "Installation aborted by user."
    exit 1
fi

MESSAGE="Desde la versión 39 de Batocera, aparentemente debido a cambios en el kernel y/o SDL, xinput sobre bluetooth no funciona en Steam en el contenedor de Arch. Los controladores Xbox One/S/X funcionan únicamente a través de USB con cable o adaptador inalámbrico de Xbox. Los usuarios de controladores 8bitDO pueden cambiar su modo de entrada a d-input o entrada de switch. ¿Deseas continuar?"

# Use dialog to create a yes/no box
if dialog --title "Compatibility Warning" --yesno "$MESSAGE" 10 70; then
    # If the user chooses 'Yes', continue the installation
    echo "Continuing installation..."
    # Add your installation commands here
else
    # If the user chooses 'No', exit the script
    echo "Installation aborted by user."
    exit 1
fi

# Clear the screen after the dialog is closed
clear

echo "Iniciando el script del instalador de Steam..."

sleep 2

clear 

# Function to display animated title
animate_title() {
    local text="Steam container installer"
    local delay=0.1
    local length=${#text}

    for (( i=0; i<length; i++ )); do
        echo -n "${text:i:1}"
        sleep $delay
    done
    echo
}

display_controls() {
    echo 
    echo "instalando Steam..."
    echo "un nuevo sistema aparecerá llamado Arch Container Linux o"
    echo "Arch Container, dependiendo de tu tema, en ~/pro/steam" 
    echo 
    sleep 10  # Delay for 10 seconds
}

###############

# Main script execution
clear
animate_title
display_controls

# Define URL base variable
REPO_BASE_URL="${REPO_BASE_URL:-https://raw.githubusercontent.com/MacRimi/Super-Emulator/main/steam}"

# Define variables
BASE_DIR="/userdata/system/pro/steam"
HOME_DIR="$BASE_DIR/home"
DOWNLOAD_URL="batocera.pro/app/conty.sh"
DOWNLOAD_FILE="$BASE_DIR/conty.sh"
ROMS_DIR="/userdata/roms/ports"

###############

# Step 1: Create base folder if not exists
mkdir -p "$BASE_DIR"
if [ ! -d "$BASE_DIR" ]; then
  # Handle error or exit if necessary
  echo "Error creating BASE_DIR."
  exit 1
fi

###############

# Step 2: Create home folder if not exists
if [ ! -d "$HOME_DIR" ]; then
  mkdir -p "$HOME_DIR"
fi

########
#make steam2 folder for steam shortcuts
mkdir -p /userdata/roms/steam2
###############

###############
# Step 3: Download conty.sh with download percentage indicator
# rm /userdata/system/pro/steam/prepare.sh 2>/dev/null
# rm /userdata/system/pro/steam/conty.s* 2>/dev/null
# curl -L aria2c.batocera.pro | bash && ./aria2c -x 5 -d /userdata/system/pro/steam http://batocera.pro/app/conty.sh && rm aria2c
# chmod 777 /userdata/system/pro/steam/conty.sh 2>/dev/null
###############

###############

# Paso 3: Descargar conty.sh con indicador de progreso
rm /userdata/system/pro/steam/prepare.sh 2>/dev/null
rm /userdata/system/pro/steam/conty.s* 2>/dev/null
curl -L -o /userdata/system/pro/steam/conty.sh https://github.com/Kron4ek/Conty/releases/latest/download/conty.sh
chmod 777 /userdata/system/pro/steam/conty.sh 2>/dev/null

###############

# Step 4: Make conty.sh executable
chmod +x "$DOWNLOAD_FILE"

###############

echo "Conty files have been downloaded a to $target_directory"

###############

# Update shortcuts
wget -q --tries=30 --no-check-certificate --no-cache --no-cookies --tries=50 -O /tmp/update_shortcuts.sh "${REPO_BASE_URL}/update_shortcuts.sh"
dos2unix /tmp/update_shortcuts.sh 2>/dev/null
chmod 777 /tmp/update_shortcuts.sh 2>/dev/null
bash /tmp/update_shortcuts.sh 
sleep 1

###############

#echo "Launching Steam"
#dos2unix "/userdata/roms/conty/Steam Big Picture Mode.sh" 2>/dev/null
#chmod 777 "/userdata/roms/conty/Steam Big Picture Mode.sh" 2>/dev/null
#bash "/userdata/roms/conty/Steam Big Picture Mode.sh"

###############

MSG="Instalación completada. Deberías ver un nuevo sistema en EmulationStation llamado Linux o Arch Linux, dependiendo del tema.

Usuarios de NVIDIA: Los controladores se descargarán en segundo plano durante el primer inicio de la aplicación y pueden tardar un tiempo."
dialog --title "Arch Container Steam Setup Complete" --msgbox "$MSG" 20 70

###############

curl http://127.0.0.1:1234/reloadgames
