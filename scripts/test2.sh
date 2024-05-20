#!/bin/bash

REPO_URL="https://github.com/MacRimi/Super-RetroPie"
INSTALL_DIR="/opt/Super-RetroPie"
SCRIPT_PATH="$INSTALL_DIR/scripts/menu-super-retropie.sh"
VERSION_FILE="$INSTALL_DIR/version.txt"
TMP_DIR=$(mktemp -d)

# Asegurarse de que el script se ejecute con permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit 1
fi

# Función para actualizar el script
update_script() {
  echo "Verificando actualizaciones del script..."
  
  # Clonar temporalmente el repositorio
  git clone --depth=1 "$REPO_URL" "$TMP_DIR"
  
  # Verificar si la clonación fue exitosa
  if [ $? -ne 0 ]; then
    echo "Error al clonar el repositorio para la actualización. Saliendo..."
    rm -rf "$TMP_DIR"
    exit 1
  fi

  # Comparar versiones
  NEW_VERSION=$(cat "$TMP_DIR/version.txt")
  CURRENT_VERSION=$(cat "$VERSION_FILE")

  if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    echo "Nueva versión disponible: $NEW_VERSION. Actualizando..."
    # Copiar nuevos archivos
    cp -r "$TMP_DIR/scripts" "$INSTALL_DIR"
    echo "$NEW_VERSION" > "$VERSION_FILE"
    chmod +x "$SCRIPT_PATH"
    echo "Actualización completada. Reiniciando script..."
    rm -rf "$TMP_DIR"
    exec "$SCRIPT_PATH" "$@"
    exit 0
  else
    echo "El script ya está actualizado."
  fi

  # Limpiar el directorio temporal
  rm -rf "$TMP_DIR"
}

# Llamar a la función de actualización al inicio del script
update_script

# Verificar si RetroPie está instalado
if command -v emulationstation &> /dev/null; then
    echo "RetroPie está instalado. Procediendo con la descarga del repositorio y ejecución del nuevo script..."
    
    # Crear el directorio de instalación si no existe
    mkdir -p "$INSTALL_DIR"
    
    # Clonar el repositorio
    git clone "$REPO_URL" "$INSTALL_DIR"
    
    # Verificar si la clonación fue exitosa
    if [ $? -ne 0 ]; then
        echo "Error al clonar el repositorio. Saliendo..."
        exit 1
    fi

    # Dar permisos de ejecución al script descargado
    chmod +x "$SCRIPT_PATH"

    # Ejecutar el nuevo script
    exec "$SCRIPT_PATH"

    # Salir del script actual
    exit 0
else
    echo "RetroPie no está instalado. Las siguientes opciones estarán disponibles:"
fi

# Función para comprobar si el volumen lógico está usando todo el espacio disponible
check_volume() {
  local LV_PATH=$(lvscan | grep "ACTIVE" | awk '{print $2}' | tr -d "'")
  if [ -z "$LV_PATH" ];hen
    echo "No se pudo determinar la ruta del volumen lógico. Asegúrate de que el volumen lógico está activo."
    exit 1
  fi

  local FREE_SPACE=$(vgdisplay | grep "Free  PE / Size" | awk '{print $5}')
  if [ "$FREE_SPACE" -gt 0 ]; then
    return 1
  else
    return 0
  fi
}

# Función para extender el volumen lógico
extend_volume() {
  local LV_PATH=$(lvscan | grep "ACTIVE" | awk '{print $2}' | tr -d "'")
  
  # Verificar si el volumen ya está extendido al máximo
  local EXTEND_STATUS=$(lvdisplay "$LV_PATH" | grep "Allocated to snapshot")
  if [[ -z "$EXTEND_STATUS" ]]; then
    echo "El volumen lógico ya está extendido al máximo."
    return
  fi

  echo "Extendiendo el volumen lógico..."
  lvextend -l +100%FREE "$LV_PATH"
  if [ $? -ne 0 ];hen
    echo "Error al extender el volumen lógico."
    exit 1
  fi

  echo "Redimensionando el sistema de archivos..."
  resize2fs "$LV_PATH"
  if [ $? -ne 0 ];hen
    echo "Error al redimensionar el sistema de archivos."
    exit 1
  fi

  echo "El volumen lógico y el sistema de archivos se han extendido correctamente."
}

# Función para instalar RetroPie
install_retropie() {
  if ! command -v expect &> /dev/null; then
    echo "El paquete expect no está instalado. Instalándolo..."
    apt-get update
    apt-get install -y expect
  fi

  wget -q https://raw.githubusercontent.com/MizterB/RetroPie-Setup-Ubuntu/master/bootstrap.sh
  bash ./bootstrap.sh

  expect << EOF
  spawn sudo ./RetroPie-Setup-Ubuntu/retropie_setup_ubuntu.sh
  expect {
      "Press any key to continue" { send "\r"; exp_continue }
      "RetroPie Setup" { send "\r"; exp_continue }
      "Exit" { send "\r" }
  }
EOF

  reboot
}

# Función para mostrar el menú y capturar la selección del usuario
show_menu() {
  while true; do
    opciones=$(dialog --checklist "Seleccione los scripts a ejecutar:" 20 60 2 \
        1 "Extender disco a su máxima capacidad" off \
        2 "Instalar RetroPie" off 3>&1 1>&2 2>&3 3>&-)

    respuesta=$?

    if [[ $respuesta -eq 1 || $respuesta -eq 255 ]]; then
        clear
        echo "Instalación cancelada."
        exit 1
    fi

    if echo "$opciones" | grep -q "2"; then
        dialog --yesno "¿Desea continuar con la instalación de RetroPie?" 10 60
        if [[ $? -eq 0 ]];hen
            install_retropie
            return
        else
            clear
        fi
    fi

    if echo "$opciones" | grep -q "1"; then
        dialog --yesno "Se va a proceder a dimensionar el volumen a su máxima capacidad, ¿seguro que quiere continuar?" 10 60
        if [[ $? -eq 0 ]];hen
            extend_volume
            return
        else
            clear
        fi
    fi
  done
}

# Inicio del script
show_menu
