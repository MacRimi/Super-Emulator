#!/bin/bash

# Actualiza el sistema
sudo apt update && sudo apt upgrade -y

# Añade soporte para arquitectura i386 (32 bits)
sudo dpkg --add-architecture i386

# Instala dependencias para Steam y compatibilidad de arquitectura mixta
sudo apt install -y libc6:amd64 libc6:i386 \
                    libegl1:amd64 libegl1:i386 \
                    libgbm1:amd64 libgbm1:i386 \
                    libgl1-mesa-glx:amd64 libgl1-mesa-glx:i386 \
                    libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 \
                    steam-libs-amd64:amd64 steam-libs-i386:i386

# Instala un entorno gráfico ligero (si es necesario)
sudo apt install -y xorg xinit openbox

# Descarga e instala Steam
wget -O steam.deb https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb
sudo apt install -y ./steam.deb

# Limpia el archivo descargado
rm steam.deb

echo "Steam se ha instalado correctamente"
