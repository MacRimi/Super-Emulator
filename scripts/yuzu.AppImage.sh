#!/usr/bin/env bash

# Variables del módulo RetroPie
rp_module_id="yuzu"
rp_module_desc="Nintendo Switch emulator Yuzu"
rp_module_help="ROM Extensions: .xci, .nsp\n\nCopy your Nintendo Switch game files to $romdir/switch\n\nVisit https://yuzu-emu.org/ for more information."
rp_module_licence="GPL3 https://raw.githubusercontent.com/yuzu-emu/yuzu/master/LICENSE"
rp_module_section="exp"
rp_module_flags="!arm"

# Funciones de instalación y configuración

function install_bin_yuzu() {
    mkdir -p "$md_inst/bin"
    cp "/home/pi/Descargas/yuzu.AppImage" "$md_inst/bin/yuzu.AppImage"
    chmod +x "$md_inst/bin/yuzu.AppImage"
}


#function install_bin_yuzu() {
#    mkdir -p "$md_inst/bin"
#    wget --content-disposition https://yuzu-emu.org/downloads/latest/ -O "$md_inst/bin/yuzu.AppImage"
#    chmod +x "$md_inst/bin/yuzu.AppImage"
#}

function configure_yuzu() {
    mkRomDir "switch"
    addEmulator 0 "$md_id" "switch" "$md_inst/bin/yuzu.AppImage %ROM%"
    addSystem "switch"
}
