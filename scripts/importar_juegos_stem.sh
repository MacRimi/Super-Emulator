#!/usr/bin/env bash

# ##############################################################################
# Encuentra juegos de Steam en tu directorio de Steam y escribe scripts de shell para lanzar los juegos.
# ##############################################################################

# Configuración
readonly ROMS_DIR="${HOME}/RetroPie/roms/steam"
readonly OUTPUT_DIR="${ROMS_DIR}"

# Steam stuff"
readonly STEAM_APPS_DIR="${HOME}/.local/share/Steam/steamapps"
readonly STEAM_MANIFEST_EXT='.acf'

# ##############################################################################
# Obtiene la propiedad especificada del manifiesto de la aplicación de Steam.
#
# Argumentos:
#   app_manifest_path: la ruta completa al archivo de manifiesto de la aplicación.
#   property_name: el nombre de la propiedad que se desea obtener.
# ##############################################################################
function getManifestProperty() {
    local app_manifest_path="$1"
    local property_name="$2"

    # Utiliza grep y sed para extraer el valor de la propiedad del archivo de manifiesto
    grep "${property_name}" "${app_manifest_path}" | cut -d '"' -f 4 
}


# ##############################################################################
# Escribe el contenido de un script de shell para lanzar un juego de Steam.
#
# Argumentos:
#   app_id: el ID numérico para la aplicación de Steam.
#   app_name: el nombre de cadena de la aplicación de Steam.
# ##############################################################################
function shellScriptTemplate() {
    local app_id="$1"
    local app_name="$2"


    cat <<EOF
#!/bin/bash

# Lanza el juego desde Steam
steam -noverifyfiles  -bigpicture steam://rungameid/${app_id} &

# Esperar un poco para asegurarse de que el juego esté completamente cerrado antes de continuar
wait

# Una vez que el juego se cierra, cerrar Steam y reiniciar EmulationStation
#steam -shutdown
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
    app_id=$(getManifestProperty "${app_manifest_path}" '"appid"')
    app_name=$(getManifestProperty "${app_manifest_path}" '"name"')
    sanitized_app_name=$(echo "${app_name}" | sed 's/&/and/g' | tr ' ' '_')
    shell_script_path="${OUTPUT_DIR}/${sanitized_app_name}.sh"
    shell_script_contents=$(shellScriptTemplate "${app_id}" "${app_name}")

    echo "${shell_script_contents}" > "${shell_script_path}"
    chmod +x "${shell_script_path}"
done
