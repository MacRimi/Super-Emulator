#!/bin/bash

# Obtener el directorio del script
script_dir=$(dirname "$(realpath "$0")")

# Archivo de la base de datos
db_file="$script_dir/wiitdb.xml"  # Especifica la ruta completa al archivo de la base de datos local

# Verificar si el archivo de la base de datos existe
if [ ! -f "$db_file" ]; then
  echo "Database file not found! Please ensure $db_file is in the same directory as the script."
  exit 1
fi

# Función para obtener el nombre del juego desde la base de datos local
get_game_name() {
  local serial="$1"
  local game_name=""

  # Intentar obtener el título en varios idiomas, preferiblemente en español primero
  for lang in ES EN; do
    game_name=$(xmlstarlet sel -t -m "//game[id='$serial']/locale[@lang='$lang']" -v 'title' -n "$db_file")
    if [ -n "$game_name" ]; then
      break
    fi
  done

  # Depuración para verificar si se encuentran los nodos del juego y los títulos en varios idiomas
  local game_node=$(xmlstarlet sel -t -c "//game[id='$serial']" "$db_file")
  if [ -z "$game_node" ]; then
    echo "No game node found for serial $serial"
  else
    echo "Game node found for serial $serial: $game_node"
  fi

  if [ -z "$game_name" ]; then
    echo "No game name found for serial $serial"
  else
    echo "Game name found: $game_name"
  fi

  echo "$game_name"
}

# Directorio de origen donde se encuentran los juegos de rpcs3
rpcs3_game_dir="$HOME/.config/rpcs3/dev_hdd0/game"

# Directorio de destino donde se crearán los enlaces simbólicos en RetroPie
retropie_roms_dir="$HOME/RetroPie/roms/ps3"

# Iterar sobre cada subdirectorio en el directorio de juegos de rpcs3
for game_dir in "$rpcs3_game_dir"/*; do
  if [ -d "$game_dir" ]; then
    # Obtener el serial del juego (nombre del subdirectorio)
    serial=$(basename "$game_dir")
    
    # Verificar que el serial no contenga caracteres inesperados
    if [[ "$serial" =~ [^a-zA-Z0-9_] ]]; then
      echo "Serial inválido: $serial"
      continue
    fi

    # Obtener el nombre del juego usando la base de datos local
    game_name=$(get_game_name "$serial")

    # Si no se encuentra el nombre del juego, usar el serial como nombre
    if [ -z "$game_name" ]; then
      echo "No se encontró el nombre del juego para el serial $serial. Usando el serial como nombre." # Línea de depuración
      game_name=$serial
    fi

    # Crear el nombre del enlace simbólico
    symlink_name="$retropie_roms_dir/${game_name// /_}.PS3/PS3_GAME"

    # Crear el directorio destino si no existe
    mkdir -p "$(dirname "$symlink_name")"

    # Crear el enlace simbólico
    ln -sf "$game_dir" "$symlink_name"
    
    echo "Enlace simbólico creado: $symlink_name -> $game_dir"
  fi
done

echo "Todos los enlaces simbólicos se han creado correctamente."
