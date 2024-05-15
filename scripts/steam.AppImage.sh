#!/bin/bash

# Define el directorio base del usuario estándar
HOME_DIR=$(eval echo ~$SUDO_USER)

# Define mkRomDir para crear directorios si no está ya definido
mkRomDir() {
    mkdir -p "$1"
}

# Añade soporte para arquitectura i386 si no está ya añadido
sudo dpkg --add-architecture i386

# Instalar dependencias necesarias para Steam
REQUIRED_PACKAGES=(
    "libc6:amd64" "libc6:i386"
    "libegl1:amd64" "libegl1:i386"
    "libgbm1:amd64" "libgbm1:i386"
    "libgl1-mesa-glx:amd64" "libgl1-mesa-glx:i386"
    "libgl1-mesa-dri:amd64" "libgl1-mesa-dri:i386"
    "steam-libs-amd64:amd64" "steam-libs-i386:i386"
)

# Instalar las dependencias
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    sudo apt-get install -y "$pkg"
done

# Crear el directorio para instalar Steam
mkRomDir "$HOME_DIR/RetroPie/roms/steam"

# Crear el directorio "ajustes"
mkRomDir "$HOME_DIR/RetroPie/roms/ajustes"

# Descargar e instalar Steam
wget --content-disposition "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" -O "$HOME_DIR/RetroPie/roms/steam/steam.deb"
sudo apt-get install -y "$HOME_DIR/RetroPie/roms/steam/steam.deb"
rm "$HOME_DIR/RetroPie/roms/steam/steam.deb"  # Eliminar el archivo después de instalar

# Ruta a es_systems.cfg
ES_SYSTEMS_CFG="/etc/emulationstation/es_systems.cfg"

# Agregar sistemas a es_systems.cfg
# Agregar el sistema "ajustes" antes de </systemList>
sudo sed -i "/<\/systemList>/i \
<system>\
    <name>ajustes</name>\
    <fullname>Configuraciones</fullname>\
    <path>$HOME_DIR/RetroPie/roms/ajustes</path>\
    <extension>.sh</extension>\
    <command>%ROM%</command>\
    <platform>config</platform>\
    <theme>ajustes</theme>\
</system>" "$ES_SYSTEMS_CFG"

# Agregar el sistema "steam" antes de </systemList>
sudo sed -i "/<\/systemList>/i \
<system>\
    <name>steam</name>\
    <fullname>Steam</fullname>\
    <path>$HOME_DIR/RetroPie/roms/steam</path>\
    <extension>.sh</extension>\
    <command>%ROM%</command>\
    <platform>pc</platform>\
    <theme>steam</theme>\
</system>" "$ES_SYSTEMS_CFG"

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


