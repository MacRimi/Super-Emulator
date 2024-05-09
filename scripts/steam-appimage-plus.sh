#!/bin/bash

# Define el directorio base del usuario estándar para evitar errores relacionados con el usuario root
HOME_DIR=$(eval echo ~$SUDO_USER)

# Define mkRomDir para crear directorios si no está ya definido
mkRomDir() {
    mkdir -p "$1"
}

# Actualiza el sistema con permisos de administrador
sudo apt-get update && sudo apt-get upgrade -y

# Añade soporte para arquitectura i386 si no está ya añadido
if ! dpkg --print-architecture | grep -q "i386"; then
    sudo dpkg --add-architecture i386
fi

# Instala las dependencias necesarias para Steam y compatibilidad entre arquitecturas
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

# Crea el directorio para instalar Steam
# Si el directorio no existe, lo crea
mkRomDir "$HOME_DIR/RetroPie/roms/ajustes"

# Descarga Steam si no se ha descargado antes
if [[ ! -f "$HOME_DIR/RetroPie/roms/ajustes/steam.deb" ]]; then
    wget --content-disposition "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" -O "$HOME_DIR/RetroPie/roms/ajustes/steam.deb"
fi

# Instala Steam si no está ya instalado
if ! which steam; then
    sudo apt-get install -y "$HOME_DIR/RetroPie/roms/ajustes/steam.deb"
    rm "$HOME_DIR/RetroPie/roms/ajustes/steam.deb"  # Borrar el archivo después de la instalación
fi

# Crear directorios de ROMs para Steam y "ajustes" si no existen
mkRomDir "$HOME_DIR/RetroPie/roms/steam"
mkRomDir "$HOME_DIR/RetroPie/roms/ajustes"

# Buscar la ruta correcta para es_systems.cfg
ES_SYSTEMS_PATHS=(
    "/etc/emulationstation/es_systems.cfg"
    "/opt/retropie/configs/all/emulationstation/es_systems.cfg"
)

ES_SYSTEMS_CFG=""

# Encuentra la ruta correcta para es_systems.cfg
for path in "${ES_SYSTEMS_PATHS[@]}"; do
    if [[ -f "$path" ]]; entonces
        ES_SYSTEMS_CFG="$path"
        break
    fi
done

# Si no se encontró es_systems.cfg, muestra un error
if [[ -z "$ES_SYSTEMS_CFG" ]]; entonces
    echo "No se encontró es_systems.cfg."
    exit 1
fi

# Añadir el sistema "steam" y "ajustes" a es_systems.cfg solo si no están ya configurados
if ! grep -q '<name>steam</name>' "$ES_SYSTEMS_CFG"; entonces
    cat <<EOF >> "$ES_SYSTEMS_CFG"
<system>
    <name>ajustes</name>
    <fullname>Configuraciones</fullname>
    <path>$HOME_DIR/RetroPie/roms/ajustes</path>
    <extension>.sh</extension>
    <command>%ROM%</command>
    <platform>config</platform>
    <theme>ajustes</theme>
</system>
<system>
    <name>steam</name>
    <fullname>Steam</fullname>
    <path>$HOME_DIR/RetroPie/roms/steam</path>
    <extension>.sh</extension>
    <command>%ROM%</command>
    <platform>pc</platform>
    <theme>steam</theme>
</system>
EOF
fi

# Agregar scripts para "ajustes" solo si no existen
if [[ ! -f "$HOME_DIR/RetroPie/roms/ajustes/lanzar_steam.sh" ]]; entonces
    cat <<EOF > "$HOME_DIR/RetroPie/roms/ajustes/lanzar_steam.sh"
#!/bin/bash
steam -noverifyfiles -bigpicture
wait
emulationstation
EOF
    chmod +x "$HOME_DIR/RetroPie/roms/ajustes/lanzar_steam.sh"
fi

if [[ ! -f "$HOME_DIR/RetroPie/roms/ajustes/importar_juegos_steam.sh" ]]; entonces
    cat <<'EOF' > "$HOME_DIR/RetroPie/roms/ajustes/importar_juegos_steam.sh"
#!/usr/bin/env bash

readonly ROMS_DIR="${HOME_DIR/RetroPie/roms/steam"
readonly OUTPUT_DIR="${ROMS_DIR}"

# Información de Steam
readonly STEAM_APPS_DIR="${HOME_DIR/.local/share/Steam/steamapps"
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

    cat <<EOF2
#!/bin/bash

steam -noverifyfiles -bigpicture steam://rungameid/${app_id} &

wait

emulationstation

EOF2
}

# Crear el directorio si es necesario
mkRomDir "${OUTPUT_DIR}"

app_manifest_names=$(ls "${STEAM_APPS_DIR}" | grep "${STEAM_MANIFEST_EXT}")
for app_manifest_name in "${app_manifest_names}"; entonces
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

echo "Configuración completada. Por favor, reinicie EmulationStation para aplicar los cambios."
