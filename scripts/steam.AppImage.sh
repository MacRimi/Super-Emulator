#!/usr/bin/env bash

# Variables del módulo RetroPie
rp_module_id="steam"
rp_module_desc="Steam"
rp_module_help="ROM Extensions: .sh\n\nCopy your Wii U game files to $romdir/wiiu\n\nDon't forget to set up the required BIOS files and keys!"
rp_module_licence="Custom license"
rp_module_section="exp"
rp_module_flags="!arm"

# Funciones de instalación y configuración

function install_bin_steam() {
    mkdir -p "$md_inst/bin"
    cp "/home/pi/Descargas/Steam.AppImage" "$md_inst/bin/steam"  
    chmod +x "$md_inst/bin/steam"
}

function configure_steam() {
    mkRomDir "steam"
    addEmulator 0 "$md_id" "steam" "$md_inst/bin/steam %ROM%"
    addSystem "steam"  
}
