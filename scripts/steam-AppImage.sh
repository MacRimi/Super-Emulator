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

    sudo dpkg --add-architecture i386

    sudo apt update

    sudo apt install -y libc6:amd64 libc6:i386 \
                        libegl1:amd64 libegl1:i386 \
                        libgbm1:amd64 libgbm1:i386 \
                        libgl1-mesa-glx:amd64 libgl1-mesa-glx:i386 \
                        libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 \
                        steam-libs-amd64:amd64 steam-libs-i386:i386
}

function install_bin_steam() {
    mkdir -p "$md_inst/bin"
    wget -O steam.deb https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb
    sudo apt install -y ./steam.deb || sudo apt -f install -y
    rm steam.deb
}

function configure_steam() {
    mkRomDir "steam"
    addEmulator 1 "$md_id" "steam"
    addSystem "steam"

}

####################################################
# crear y añadir scripts
####################################################

# Agregar script para lanzar Steam al directorio "ajustes"
cat <<EOF > "$HOME_DIR/RetroPie/roms/ajustes/lanzar_steam.sh"
#!/bin/bash
steam
wait
emulationstation
EOF

chmod +x "$HOME_DIR/RetroPie/roms/ajustes/lanzar_steam.sh"

####################################################################

# Agregar script para importar juegos de Steam al directorio "ajustes" solo si no existe
cat <<'EOF' > "$HOME_DIR/RetroPie/roms/ajustes/importar_juegos_steam.sh"
#!/usr/bin/env bash
# Configuración
readonly ROMS_DIR="${HOME}/RetroPie/roms/steam"
readonly OUTPUT_DIR="${ROMS_DIR}"

# Steam stuff"
readonly STEAM_APPS_DIR="${HOME}/.local/share/Steam/steamapps"
readonly STEAM_MANIFEST_EXT='.acf'


function getManifestProperty() {
    local app_manifest_path="$1"
    local property_name="$2"

    # Utiliza grep y sed para extraer el valor de la propiedad del archivo de manifiesto
    grep "${property_name}" "${app_manifest_path}" | cut -d '"' -f 4 
}


function shellScriptTemplate() {
    local app_id="$1"
    local app_name="$2"


cat <<EOF2
#!/bin/bash

# Lanza el juego desde Steam
steam steam://rungameid/${app_id} &

wait

# Una vez que el juego se cierra, cerrar Steam y reiniciar EmulationStation
emulationstation

EOF2
}


app_manifest_names=$(ls "${STEAM_APPS_DIR}" | grep "${STEAM_MANIFEST_EXT}")
for app_manifest_name in ${app_manifest_names}; do
    app_manifest_path="${STEAM_APPS_DIR}/${app_manifest_name}"
    app_id=$(getManifestProperty "${app_manifest_path}" '"appid"')
    app_name=$(getManifestProperty "${app_manifest_path}" '"name"')
    sanitized_app_name=$(echo "${app_name}" | sed 's/&/and/g' | tr ' ' '_')
    shell_script_path="${OUTPUT_DIR}/${sanitized_app_name}.sh"
    shell_script_contents=$(shellScriptTemplate "${app_id}" "${app_name}")

    echo "${shell_script_contents}" > "${shell_script_path}"
    chmod +x "${shell_script_path}"
  
done

emulationstation --quit  # Cerrar EmulationStation
emulationstation         # Reiniciar EmulationStation

EOF

    chmod +x "$HOME_DIR/RetroPie/roms/ajustes/importar_juegos_steam.sh"


