#!/bin/bash

# Define el directorio base del usuario estándar
HOME_DIR=$(eval echo ~$SUDO_USER)

# Define mkRomDir para crear directorios si no está ya definido
mkRomDir() {
    mkdir -p "$1"
}

# Actualiza el sistema con permisos de administrador
sudo apt-get update && sudo apt-get upgrade -y

# Añade soporte para arquitectura i386 si no está ya añadido
sudo dpkg --add-architecture i386

# Instalar dependencias necesarias para Steam
REQUIRED_PACKAGES=(
    "libc6:amd64" "libc6:i386"
    "libegl1:amd64" "libegl1:i386"
    "libgbm1:amd64" "libgbm1:i386"
    "libgl1-mesa-glx:amd64" "libgl1-mesa-glx:i386"
    "libgl1-mesa-dri:amd64" "libgl1-mesa-dri:i386"
    "steam-libs-amd64:amd64" "steam-libs-i386:i386"
)

# Instalar las dependencias
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    sudo apt-get install -y "$pkg"
done

# Crear el directorio para instalar Steam
mkRomDir "$HOME_DIR/RetroPie/roms/steam"

# Crear el directorio "ajustes"
mkRomDir "$HOME_DIR/RetroPie/roms/ajustes"

# Descargar e instalar Steam
wget --content-disposition "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" -O "$HOME_DIR/RetroPie/roms/steam/steam.deb"
sudo apt-get install -y "$HOME_DIR/RetroPie/roms/steam/steam.deb"
rm "$HOME_DIR/RetroPie/roms/steam/steam.deb"  # Eliminar el archivo después de instalar

# Ruta a es_systems.cfg
ES_SYSTEMS_CFG="/etc/emulationstation/es_systems.cfg"

# Agregar sistemas a es_systems.cfg
# Agregar el sistema "ajustes" antes de </systemList>
sudo sed -i "/<\/systemList>/i \
<system>\
    <name>ajustes</name>\
    <fullname>Configuraciones</fullname>\
    <path>$HOME_DIR/RetroPie/roms/ajustes</path>\
    <extension>.sh</extension>\
    <command>%ROM%</command>\
    <platform>config</platform>\
    <theme>ajustes</theme>\
</system>" "$ES_SYSTEMS_CFG"

# Agregar el sistema "steam" antes de </systemList>
sudo sed -i "/<\/systemList>/i \
<system>\
    <name>steam</name>\
    <fullname>Steam</fullname>\
    <path>$HOME_DIR/RetroPie/roms/steam</path>\
    <extension>.sh</extension>\
    <command>%ROM%</command>\
    <platform>pc</platform>\
    <theme>steam</theme>\
</system>" "$ES_SYSTEMS_CFG"
