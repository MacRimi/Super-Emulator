#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/MacRimi/Super-RetroPie/main/test_emulations2.sh"
USER_HOME=$(eval echo ~$SUDO_USER)
USER_INSTALL_DIR="$USER_HOME/Super-RetroPie"
SCRIPT_NAME="test_emulations2.sh"
USER_SCRIPT_PATH="$USER_INSTALL_DIR/$SCRIPT_NAME"

# Asegurarse de que el script se ejecute con permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit 1
fi

# Verificar la accesibilidad de la URL
echo "Verificando la URL de descarga..."
wget -q --spider "$REPO_URL"
if [ $? -ne 0 ]; then
  echo "La URL no es accesible. Verifique la URL de descarga: $REPO_URL"
  exit 1
fi

# Descargar y ejecutar el script si emulationstation_test no está instalado
echo "Verificando si emulationstation_test está instalado..."
if [ -x "$(command -v emulationstation_test)" ]; then
  echo "emulationstation_test está instalado."
else
  echo "emulationstation_test no está instalado. Descargando y ejecutando $SCRIPT_NAME..."
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
fi
