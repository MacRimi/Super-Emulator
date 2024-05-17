#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md

rp_module_id="steam"
rp_module_desc="Steam - Plataforma de distribución de videojuegos"
rp_module_help="Instrucciones: Este script instalará Steam en tu sistema. Para lanzar Steam, utiliza el acceso directo en RetroPie."
rp_module_licence="Proprietary https://store.steampowered.com/subscriber_agreement/"
rp_module_section="exp"
rp_module_flags="!all 64bit"

function depends_steam() {
    local depends=(curl wget)
    getDepends "${depends[@]}"
    
    # Añade la arquitectura i386
    sudo dpkg --add-architecture i386

    # Actualiza la lista de paquetes
    sudo apt update

    # Instala dependencias para Steam y compatibilidad de arquitectura mixta
    sudo apt install -y libc6:amd64 libc6:i386 \
                        libegl1:amd64 libegl1:i386 \
                        libgbm1:amd64 libgbm1:i386 \
                        libgl1-mesa-glx:amd64 libgl1-mesa-glx:i386 \
                        libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 \
                        steam-libs-amd64:amd64 steam-libs-i386:i386
}

function install_bin_steam() {
    mkdir -p "$md_inst/bin"
    wget --content-disposition https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb -O "$md_inst/bin/steam.deb"
    sudo dpkg -i "$md_inst/bin/steam.deb" || sudo apt -f install -y
    rm "$md_inst/bin/steam.deb"
    chmod +x "$md_inst/bin/steam"
}

function configure_steam() {
    mkRomDir "steam"
    addEmulator 1 "$md_id" "steam" "$md_inst/bin/steam %ROM%"
    addSystem "steam"

    # Agregar nueva entrada al archivo es_systems.cfg
    echo "<system>" >> /etc/emulationstation/es_systems.cfg
    echo "    <name>steam</name>" >> /etc/emulationstation/es_systems.cfg
    echo "    <fullname>Steam</fullname>" >> /etc/emulationstation/es_systems.cfg
    echo "    <path>$HOME/RetroPie/roms/steam</path>" >> /etc/emulationstation/es_systems.cfg
    echo "    <extension>.sh .SH</extension>" >> /etc/emulationstation/es_systems.cfg
    echo "    <command>%ROM%</command>" >> /etc/emulationstation/es_systems.cfg
    echo "    <platform>steam</platform>" >> /etc/emulationstation/es_systems.cfg
    echo "    <theme>steam</theme>" >> /etc/emulationstation/es_systems.cfg
    echo "</system>" >> /etc/emulationstation/es_systems.cfg
}

depends_steam
install_bin_steam
configure_steam
