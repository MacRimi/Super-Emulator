#!/bin/bash

REPO_URL="https://github.com/MacRimi/Super-RetroPie"
GLOBAL_INSTALL_DIR="/opt/Super-RetroPie"
USER_HOME=$(eval echo ~$SUDO_USER)
USER_INSTALL_DIR="$USER_HOME/Super-RetroPie"
TMP_DIR=$(mktemp -d)

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

# Crear directorios y archivos necesarios en /opt/Super-RetroPie si no existen
mkdir -p "$GLOBAL_INSTALL_DIR/scripts"

# Crear directorios y archivos necesarios en /home/pi/Super-RetroPie si no existen
mkdir -p "$USER_INSTALL_DIR"

VERSION_FILE="$USER_INSTALL_DIR/version.txt"
USER_SCRIPT_PATH="$USER_INSTALL_DIR/super-retropie.sh"

# Función para actualizar el script
update_script() {
  echo "Verificando actualizaciones del script..."
  
  # Verificar si TMP_DIR está vacío
  if [ -z "$(ls -A $TMP_DIR)" ]; then
    echo "Directorio temporal está vacío. Clonando el repositorio..."
  else
    echo "Directorio temporal no está vacío. Contenido del directorio temporal:"
    ls -l "$TMP_DIR"
  fi
  
  git clone --depth=1 "$REPO_URL" "$TMP_DIR"
  if [ $? -ne 0 ]; then
    echo "Error al clonar el repositorio."
    rm -rf "$TMP_DIR"
    exit 1
  fi

  echo "Contenido del directorio clonado:"
  ls -lR "$TMP_DIR"  # Lista recursiva para ver todos los archivos y directorios

  if [ ! -f "$TMP_DIR/version.txt" ]; then
    echo "Error: El archivo version.txt no existe en el repositorio clonado."
    rm -rf "$TMP_DIR"
    exit 1
  fi

  NEW_VERSION=$(cat "$TMP_DIR/version.txt")
  if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
  else
    CURRENT_VERSION="0.0"
  fi

  if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    echo "Nueva versión disponible: $NEW_VERSION. Actualizando..."

    if command -v emulationstation &> /dev/null; then
      echo "emulationstation está instalado. Copiando archivos a $GLOBAL_INSTALL_DIR..."
      mkdir -p "$GLOBAL_INSTALL_DIR/scripts"
      chmod -R 755 "$GLOBAL_INSTALL_DIR"

      # Verificar si el directorio scripts existe y contiene archivos
      if [ -d "$TMP_DIR/scripts" ]; then
        echo "Copiando archivos del directorio $TMP_DIR/scripts a $GLOBAL_INSTALL_DIR/scripts/..."
        cp -r "$TMP_DIR/scripts/"* "$GLOBAL_INSTALL_DIR/scripts/"
        if [ $? -ne 0 ]; then
          echo "Error al copiar los archivos del directorio $TMP_DIR/scripts a $GLOBAL_INSTALL_DIR/scripts/"
          rm -rf "$TMP_DIR"
          exit 1
        fi
        chmod +x "$GLOBAL_INSTALL_DIR/scripts/"*
      else
        echo "Error: El directorio $TMP_DIR/scripts no existe."
        rm -rf "$TMP_DIR"
        exit 1
      fi

    else
      echo "emulationstation no está instalado. Copiando archivos a $USER_INSTALL_DIR..."
      if [ -f "$TMP_DIR/super-retropie.sh" ]; then
        echo "Copiando archivo $TMP_DIR/super-retropie.sh a $USER_INSTALL_DIR/"
        cp "$TMP_DIR/super-retropie.sh" "$USER_INSTALL_DIR/"
        if [ $? -ne 0 ]; then
          echo "Error al copiar $TMP_DIR/super-retropie.sh a $USER_INSTALL_DIR/"
          rm -rf "$TMP_DIR"
          exit 1
        fi
        chmod +x "$USER_SCRIPT_PATH"
      else
        echo "Error: $TMP_DIR/super-retropie.sh no existe."
        rm -rf "$TMP_DIR"
        exit 1
      fi
    fi

    echo "$NEW_VERSION" > "$VERSION_FILE"
    echo "Actualización completada."
  else
    echo "El script ya está actualizado."
  fi

  rm -rf "$TMP_DIR"
}

# Llamar a la función de actualización si es necesario y proceder con la ejecución del script principal
update_script

# Proceder con la ejecución del script
if command -v emulationstation &> /dev/null; then
  SCRIPT_PATH="$GLOBAL_INSTALL_DIR/scripts/menu-super-retropie.sh"
  if [ -f "$SCRIPT_PATH" ]; then
      echo "Procediendo con la ejecución del script..."
      exec "$SCRIPT_PATH" "$@"
  else
      echo "Error: $SCRIPT_PATH no existe."
      echo "Contenido de $GLOBAL_INSTALL_DIR/scripts/:"
      ls -l "$GLOBAL_INSTALL_DIR/scripts/"
      exit 1
  fi
else
  if [ -f "$USER_SCRIPT_PATH" ]; then
      echo "Procediendo con la ejecución del script del usuario..."
      exec "$USER_SCRIPT_PATH" "$@"
  else
      echo "Error: $USER_SCRIPT_PATH no existe."
      echo "Contenido de $USER_INSTALL_DIR/:"
      ls -l "$USER_INSTALL_DIR/"
      exit 1
  fi
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

  # Verificar si el volumen ya está extendido al máximo
  local EXTEND_STATUS=$(lvdisplay "$LV_PATH" | grep "Allocated to snapshot")
  if [[ -z "$EXTEND_STATUS" ]]; then
    echo "El volumen lógico ya está extendido al máximo."
    return
  fi

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
        if [[ $? -eq 0 ]];then
            install_retropie
            return
        else
            clear
        fi
    fi

    if echo "$opciones" | grep -q "1"; then
        dialog --yesno "Se va a proceder a dimensionar el volumen a su máxima capacidad, ¿seguro que quiere continuar?" 10 60
        if [[ $? -eq 0 ]];then
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
