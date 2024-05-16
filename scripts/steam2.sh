#!/usr/bin/env bash

# Variables del módulo RetroPie
rp_module_id="steam"
rp_module_desc="Steam Emulator"
rp_module_help="Description of how to use Steam emulator"
rp_module_licence="Custom license"
rp_module_section="exp"
rp_module_flags="!arm"

# Funciones de instalación y configuración

function install_steam() {
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

    # Descarga e instala Steam
    wget -O steam.deb https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb
    sudo apt install -y ./steam.deb

    # Limpia el archivo descargado
    rm steam.deb
}

function configure_steam() {
    # Aquí puedes agregar la configuración necesaria para Steam en RetroPie, como la creación de directorios de ROM y la configuración del emulador
    
    # Por ejemplo, crear un directorio para juegos de Steam
    mkRomDir "steam"

    # Agregar emulador Steam
    addEmulator 0 "$rp_module_id" "steam" "steam"
    
    # Agregar sistema Steam
    addSystem "steam"
}

# Manejar la entrada de los comandos
md_ret_require="$md_inst/bin/steam"  # Ruta al ejecutable de Steam para el modo de ejecución
md_mode="$1"  # Modo de instalación (install, remove, configure, etc.)

case "$md_mode" in
    install)
        install_steam
        ;;
    configure)
        configure_steam
        ;;
    *)
        echo "Uso: $0 [install | configure | ...]"
        exit 1
        ;;
esac

exit 0
