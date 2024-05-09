#!/bin/bash

# Actualiza el sistema
if [[ "$(sudo apt-get update)" ]]; then
    sudo apt-get upgrade -y
else
    echo "No se pudo actualizar el sistema."
    exit 1
fi

# Añade soporte para arquitectura i386 (32 bits) si no está ya añadido
if ! dpkg --print-architecture | grep -q "i386"; then
    sudo dpkg --add-architecture i386
fi

# Instala dependencias para Steam y compatibilidad de arquitectura mixta
# Verifica si las dependencias ya están instaladas antes de intentar instalarlas
REQUIRED_PACKAGES=(
    "libc6:amd64" "libc6:i386"
    "libegl1:amd64" "libegl1:i386"
    "libgbm1:amd64" "libgbm1:i386"
    "libgl1-mesa-glx:amd64" "libgl1-mesa-glx:i386"
    "libgl1-mesa-dri:amd64" "libgl1-mesa-dri:i386"
    "steam-libs-amd64:amd64" "steam-libs-i386:i386"
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "$pkg"; then
        sudo apt-get install -y "$pkg"
    fi
done

# Crea el directorio para instalar Steam si no existe
if [[ ! -d "$md_inst/bin" ]]; then
    mkdir -p "$md_inst/bin"
fi

# Descarga e instala Steam si no está ya instalado
if [[ ! -f "$md_inst/bin/steam.deb" ]]; then
    wget --content-disposition "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" -O "$md_inst/bin/steam.deb"
fi

if ! which steam; then
    sudo apt install -y "$md_inst/bin/steam.deb"
    rm "$md_inst/bin/steam.deb"  # Borrar el archivo después de instalar
fi

# Crear directorios de ROMs para Steam y el directorio "ajustes"
# Solo si no existen
if [[ ! -d "$HOME/RetroPie/roms/steam" ]]; then
    mkRomDir "steam"
fi

if [[ ! -d "$HOME/RetroPie/roms/ajustes" ]]; then
    mkRomDir "ajustes"
fi

# Buscar la ruta correcta para es_systems.cfg
ES_SYSTEMS_PATHS=(
    "/etc/emulationstation/es_systems.cfg"
    "/opt/retropie/configs/all/emulationstation/es_systems.cfg"
)

ES_SYSTEMS_CFG=""

for path in "${ES_SYSTEMS_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        ES_SYSTEMS_CFG="$path"
        break
    fi
done

if [[ -z "$ES_SYSTEMS_CFG" ]]; then
    echo "No se encontró es_systems.cfg."
    exit 1
fi

# Añadir el sistema "steam" y "ajustes" solo si no están ya configurados
if ! grep -q '<name>steam</name>' "$ES_SYSTEMS_CFG"; then
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

# Agregar scripts a "ajustes" si no existen
if [[ ! -f "$HOME/RetroPie/roms/ajustes/lanzar_steam.sh" ]]; then
    cat <<EOF > "$HOME/RetroPie/roms/ajustes/lanzar_steam.sh"
#!/bin/bash
steam -noverifyfiles -bigpicture
wait
emulationstation
EOF
    chmod +x "$HOME/RetroPie/roms/ajustes/lanzar_steam.sh"
fi

if [[ ! -f "$HOME/RetroPie/roms/ajustes/importar_juegos_steam.sh" ]]; then
    cat <<'EOF' > "$HOME/RetroPie/roms/ajustes/importar_juegos_steam.sh"
#!/usr/bin/env bash

readonly ROMS_DIR="${HOME/RetroPie/roms/steam"
readonly OUTPUT_DIR="${ROMS_DIR}"

# Información de Steam
readonly STEAM_APPS_DIR="${HOME/.local/share/Steam/steamapps"
readonly STEAM_MANIFEST_EXT='.acf'

# Función para obtener propiedades del manifiesto de Steam
function getManifestProperty() {
    local app_manifest_path="$1"
    local property_name="$2"
    grep "${property_name}" "${app_manifest_path}" | cut -d '"' -f 4
}

# Función para generar script para lanzar un juego
function shellScriptTemplate() {
    local app_id="$1"
    local app_name="$2"

    cat <<EOF2
#!/bin/bash

# Lanza el juego desde Steam
steam -noverifyfiles -bigpicture steam://rungameid/${app_id} &

wait

emulationstation

EOF2
}

if [[ -d "${OUTPUT_DIR}" ]]; then
    rm -r "${OUTPUT_DIR}"
fi

mkdir -p "${OUTPUT_DIR}"

app_manifest_names=$(ls "${STEAM_APPS_DIR}" | grep "${STEAM_MANIFEST_EXT}")
for app_manifest_name in "${app_manifest_names}"; do
    app_manifest_path="${STEAM_APPS_DIR}/${app_manifest_name}"
    app_id=$(getManifestProperty("${app_manifest_path}", '"appid"')
    app_name=$(getManifestProperty("${app_manifest_path}", '"name"')

    sanitized_app_name=$(echo "${app_name}" | sed 's/&/and/g' | tr ' ' '_')
    shell_script_path="${OUTPUT_DIR}/${sanitized_app_name}.sh"
    shell_script_contents=$(shellScriptTemplate("${app_id}", "${app_name}")

    echo "${shell_script_contents}" > "${shell_script_path}")
    chmod +x("${shell_script_path}")
done
EOF
fi

echo "Configuración completada. Reinicia EmulationStation para aplicar los cambios."
