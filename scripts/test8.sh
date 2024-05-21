#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/MacRimi/Super-RetroPie/main/super-retropie.sh"
REPO_URL_FULL="https://github.com/MacRimi/Super-RetroPie.git"
GLOBAL_INSTALL_DIR="/opt/Super-RetroPie"
USER_HOME=$(eval echo ~$SUDO_USER)
USER_INSTALL_DIR="$USER_HOME/Super-RetroPie"
SCRIPT_NAME="super-retropie.sh"
USER_SCRIPT_PATH="$USER_INSTALL_DIR/$SCRIPT_NAME"

# Asegurarse de que el script se ejecute con permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit 1
fi

# Descargar y ejecutar el script si emulationstation no está instalado
if ! command -v emulationstation &> /dev/null; then
  echo "emulationstation no está instalado. Descargando y ejecutando $SCRIPT_NAME..."
  mkdir -p "$USER_INSTALL_DIR"
  wget -q "$REPO_URL" -O "$USER_SCRIPT_PATH"
  if [ $? -ne 0 ]; then
    echo "Error al descargar $SCRIPT_NAME en $USER_INSTALL_DIR."
    exit 1
  fi

  if [ -f "$USER_SCRIPT_PATH" ]; then
    echo "Ejecutando el script..."
    chmod +x "$USER_SCRIPT_PATH"
    exec "$USER_SCRIPT_PATH" "$@"
  else
    echo "Error: $USER_SCRIPT_PATH no existe."
    exit 1
  fi
else
  echo "emulationstation está instalado. Clonando el repositorio en $GLOBAL_INSTALL_DIR..."
  rm -rf "$GLOBAL_INSTALL_DIR"
  git clone "$REPO_URL_FULL" "$GLOBAL_INSTALL_DIR"
  if [ $? -ne 0 ]; then
    echo "Error al clonar el repositorio en $GLOBAL_INSTALL_DIR."
    exit 1
  fi

  SCRIPT_PATH="$GLOBAL_INSTALL_DIR/scripts/menu-super-retropie.sh"
  if [ -f "$SCRIPT_PATH" ]; then
    echo "Ejecutando el script de menú..."
    chmod +x "$SCRIPT_PATH"
    exec "$SCRIPT_PATH" "$@"
  else
    echo "Error: $SCRIPT_PATH no existe."
    exit 1
  fi
fi

# Función para verificar e instalar dependencias
install_if_missing() {
  PACKAGE_NAME=$1
  if ! command -v $PACKAGE_NAME &> /dev/null; then
    echo "El paquete '$PACKAGE_NAME' no está instalado. Instalándolo..."
    apt-get update
    apt-get install -y $PACKAGE_NAME
  fi
}

# Verificar e instalar dependencias necesarias
install_if_missing dialog
install_if_missing wget
install_if_missing git
install_if_missing lvm2
install_if_missing expect

# Función para comprobar si el volumen lógico está usando todo el espacio disponible
check_volume() {
  local LV_PATH=$(lvscan | grep "ACTIVE" | awk '{print $2}' | tr -d "'")
  if [ -z "$LV_PATH" ]; then
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

  if [ -z "$LV_PATH" ]; then
    echo "Error: No se pudo determinar la ruta del volumen lógico."
    return 1
  fi

  local CURRENT_SIZE=$(lvdisplay "$LV_PATH" | grep "Current LE" | awk '{print $3}')
  local MAX_SIZE=$(vgdisplay | grep "Total PE" | awk '{print $3}')

  if [ "$CURRENT_SIZE" -eq "$MAX_SIZE" ]; then
    echo "El volumen lógico ya está en su tamaño máximo."
    return 0
  fi

  lvextend -l +100%FREE "$LV_PATH"
  if [ $? -ne 0 ]; entonces
    echo "Error al extender el volumen lógico."
    return 1
  fi

  resize2fs "$LV_PATH"
  if [ $? -ne 0 ]; entonces
    echo "Error al redimensionar el sistema de archivos."
    return 1
  fi

  echo "El volumen lógico y el sistema de archivos se han extendido correctamente."
  return 0
}

# Función para instalar RetroPie con comprobación de volumen
install_retropie() {
  check_volume
  local volume_status=$?
  if [ "$volume_status" -eq 1 ]; entonces
    dialog --yesno "Se va a proceder a instalar RetroPie en un volumen de espacio reducido, esto podría hacer que te quedaras sin espacio pronto. ¿Desea continuar?" 10 60
    if [[ $? -ne 0 ]]; entonces
      echo "Instalación cancelada por el usuario."
      return
    fi
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

    if [[ $respuesta -eq 1 || $respuesta -eq 255 ]]; entonces
        clear
        echo "Instalación cancelada."
        exit 1
    fi

    if echo "$opciones" | grep -q "2"; entonces
        dialog --yesno "¿Desea continuar con la instalación de RetroPie?" 10 60
        if [[ $? -eq 0 ]]; entonces
            install_retropie
        else
            clear
        fi
    fi

    if echo "$opciones" | grep -q "1"; entonces
        dialog --yesno "Se va a proceder a dimensionar el volumen a su máxima capacidad, ¿seguro que quiere continuar?" 10 60
        if [[ $? -eq 0 ]]; entonces
            extend_volume
        else
            clear
        fi
    fi
  done
}

# Inicio del script
show_menu
