#!/bin/bash

# Crea el directorio para instalar Steam
mkdir -p "$md_inst/bin"

# Descarga e instala Steam
wget --content-disposition "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" -O "$md_inst/bin/steam.deb"
sudo apt install -y "$md_inst/bin/steam.deb"

# Crear el directorio de ROMs para Steam y el directorio "ajustes"
mkRomDir "steam"
mkRomDir "ajustes"

# Añadir Steam como emulador en RetroPie/EmulationStation
addEmulator 0 "$md_id" "steam" "steam"
addSystem "steam"

# Asegurarse de que el archivo es_systems.cfg esté configurado
ES_SYSTEMS_CFG="/opt/retropie/configs/all/emulationstation/es_systems.cfg"

if ! grep -q '<name>steam</name>' "$ES_SYSTEMS_CFG"; then
    # Agregar la configuración para el sistema Steam
    cat <<EOF >> "$ES_SYSTEMS_CFG"
<system>
    <name>ajustes</name>
    <fullname>Configuraciones</fullname>
    <path>$HOME/RetroPie/roms/ajustes</path>
    <extension>.sh</extension>
    <command>%ROM%</command>
    <platform>config</platform>
    <theme>ajustes</theme>
</system>
<system>
    <name>steam</name>
    <fullname>Steam</fullname>
    <path>$HOME/RetroPie/roms/steam</path>
    <extension>.sh</extension>
    <command>%ROM%</command>
    <platform>pc</platform>
    <theme>steam</theme>
</system>
EOF
fi

# Agregar script para lanzar Steam en Big Picture al directorio "ajustes"
cat <<EOF > "$HOME/RetroPie/roms/ajustes/lanzar_steam.sh"
#!/bin/bash
steam -noverifyfiles -bigpicture
EOF

chmod +x "$HOME/RetroPie/roms/ajustes/lanzar_steam.sh"

# Agregar script para importar juegos de Steam al directorio "ajustes"
cat <<'EOF' > "$HOME/RetroPie/roms/ajustes/importar_juegos_steam.sh"
#!/usr/bin/env bash

readonly ROMS_DIR="${HOME}/RetroPie/roms/steam"
readonly OUTPUT_DIR="${ROMS_DIR}"

# Steam info
readonly STEAM_APPS_DIR="${HOME}/.local/share/Steam/steamapps"
readonly STEAM_MANIFEST_EXT='.acf'

# Funcion para obtener propiedades del manifiesto de Steam
function getManifestProperty() {
    local app_manifest_path="$1"
    local property_name="$2"
    grep "${property_name}" "${app_manifest_path}" | cut -d '"' -f 4
}

# Funcion para generar script para lanzar un juego
function shellScriptTemplate() {
    local app_id="$1"
    local app_name="$2"

    cat <<EOF
#!/bin/bash

# Lanza el juego desde Steam
steam -noverifyfiles -bigpicture steam://rungameid/${app_id} &

# Esperar un poco para asegurarse de que el juego esté completamente cerrado
wait

# Reiniciar EmulationStation una vez que el juego se cierra
emulationstation

EOF
}

if [[ -d "${OUTPUT_DIR}" ]]; then
    rm -r "${OUTPUT_DIR}"
fi
mkdir -p "${OUTPUT_DIR}"

app_manifest_names=$(ls "${STEAM_APPS_DIR}" | grep "${STEAM_MANIFEST_EXT}")
for app_manifest_name in ${app_manifest_names}; do
    app_manifest_path="${STEAM_APPS_DIR}/${app_manifest_name}"
    app_id=$(getManifestProperty("${app_manifest_path}", '"appid"')
    app_name=$(getManifestProperty("${app_manifest_path}", '"name"')

    sanitized_app_name=$(echo "${app_name}" | sed 's/&/and/g' | tr ' ' '_')
    shell_script_path="${OUTPUT_DIR}/${sanitized_app_name}.sh"
    shell_script_contents=$(shellScriptTemplate("${app_id}", "${app_name}")

    echo "${shell_script_contents}" > "${shell_script_path}"
    chmod +x "${shell_script_path}"
done
EOF
EOF

chmod +x "$HOME/RetroPie/roms/ajustes/importar_juegos_steam.sh"

echo "Configuración completada. Reinicia EmulationStation para aplicar los cambios."
