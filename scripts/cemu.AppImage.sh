#!/usr/bin/env bash

# Variables del módulo RetroPie
rp_module_id="cemu"
rp_module_desc="Wii U emulator CEMU"
rp_module_help="ROM Extensions: .wud .wux\n\nCopy your Wii U game files to $romdir/wiiu\n\nDon't forget to set up the required BIOS files and keys!"
rp_module_licence="Custom license"
rp_module_section="exp"
rp_module_flags="!arm"

# Funciones de instalación y configuración

function install_bin_cemu() {
    mkdir -p "$md_inst/bin"
    cp "/home/pi/Descargas/cemu.AppImage" "$md_inst/bin/cemu"  
    chmod +x "$md_inst/bin/cemu"
}

function configure_cemu() {
    mkRomDir "wiiu"
    addEmulator 0 "$md_id" "wiiu" "$md_inst/bin/cemu %ROM%"
    addSystem "wiiu" ".wud .wux"  
}
