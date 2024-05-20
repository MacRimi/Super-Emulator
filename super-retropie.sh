#!/bin/bash

REPO_URL="https://github.com/MacRimi/Super-RetroPie"
GLOBAL_INSTALL_DIR="/opt/Super-RetroPie"
USER_HOME=$(eval echo ~$SUDO_USER)
USER_INSTALL_DIR="$USER_HOME/Super-RetroPie"

# Asegurarse de que el script se ejecute con permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit 1
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
install_if_missing git
install_if_missing lvextend
install_if_missing expect

# Función para clonar el repositorio y ejecutar el script adecuado
clone_and_execute() {
  local DEST_DIR=$1
  local SCRIPT_PATH=$2

  echo "Clonando el repositorio en $DEST_DIR..."
  rm -rf "$DEST_DIR"
  git clone "$REPO_URL" "$DEST_DIR"
  if [ $? -ne 0 ]; then
    echo "Error al clonar el repositorio en $DEST_DIR."
    exit 1
  fi

  if [ -f "$SCRIPT_PATH" ]; then
    echo "Ejecutando el script..."
    chmod +x "$SCRIPT_PATH"
    exec "$SCRIPT_PATH" "$@"
  else
    echo "Error: $SCRIPT_PATH no existe."
    exit 1
  fi
}

# Clonar el repositorio y ejecutar el script dependiendo de si emulationstation está instalado
if command -v emulationstation &> /dev/null; then
  clone_and_execute "$GLOBAL_INSTALL_DIR" "$GLOBAL_INSTALL_DIR/scripts/menu-super-retropie.sh"
else
  clone_and_execute "$USER_INSTALL_DIR" "$USER_INSTALL_DIR/super-retropie.sh"
fi

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

  echo "Extendiendo el volumen lógico..."
  lvextend -l +100%FREE "$LV_PATH"
  if [ $? -ne 0 ]; then
    echo "Error al extender el volumen lógico."
    exit 1
  fi

  echo "Redimensionando el sistema de archivos..."
  resize2fs "$LV_PATH"
  if [ $? -ne 0 ]; then
    echo "Error al redimensionar el sistema de archivos."
    exit 1
  fi

  echo "El volumen lógico y el sistema de archivos se han extendido correctamente."
}

# Función para instalar RetroPie con comprobación de volumen
install_retropie() {
  # Comprobar el estado del volumen antes de proceder
  check_volume
  local volume_status=$?
  if [ "$volume_status" -eq 1 ]; then
    # El volumen tiene espacio libre, advertir al usuario
    dialog --yesno "Se va a proceder a instalar RetroPie en un volumen de espacio reducido, esto podría hacer que te quedaras sin espacio pronto. ¿Desea continuar?" 10 60
    if [[ $? -eq 0 ]]; then
      echo "Instalando RetroPie..."
    else
      echo "Instalación cancelada por el usuario."
      return
    fi
  fi

  # Descargar y ejecutar el script de instalación de RetroPie
  wget -q https://raw.githubusercontent.com/MizterB/RetroPie-Setup-Ubuntu/master/bootstrap.sh
  bash ./bootstrap.sh

  # Automatizar la interacción con el script de instalación de RetroPie
  expect << EOF
  spawn sudo ./RetroPie-Setup-Ubuntu/retropie_setup_ubuntu.sh
  expect {
      "Press any key to continue" { send "\r"; exp_continue }
      "RetroPie Setup" { send "\r"; exp_continue }
      "Exit" { send "\r" }
  }
EOF

  # Reiniciar el sistema tras la instalación
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
        if [[ $? -eq 0 ]]; then
            install_retropie
            return
        else
            clear
        fi
    fi

    if echo "$opciones" | grep -q "1"; then
        dialog --yesno "Se va a proceder a dimensionar el volumen a su máxima capacidad, ¿seguro que quiere continuar?" 10 60
        if [[ $? -eq 0 ]]; then
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
