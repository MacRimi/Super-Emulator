#!/bin/bash

REPO_URL="https://github.com/MacRimi/Super-RetroPie"
GLOBAL_INSTALL_DIR="/opt/Super-RetroPie"
USER_HOME=$(eval echo ~$USER)
USER_INSTALL_DIR="$USER_HOME/Super-RetroPie"
TMP_DIR=$(mktemp -d)

# Asegurarse de que el script se ejecute con permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit 1
fi

# Función para instalar dependencias
install_dependencies() {
    local dependencies=("git" "wget" "dialog" "expect" "lvm2")
    echo "Verificando e instalando dependencias necesarias..."
    for pkg in "${dependencies[@]}"; do
        if ! command -v $pkg &> /dev/null; then
            echo "Instalando $pkg..."
            apt-get install -y $pkg
        fi
    done
}

# Instalar dependencias antes de proceder
install_dependencies

# Comprobación de RetroPie instalado y configuración de directorios
if command -v emulationstation &> /dev/null; then
    INSTALL_DIR="$GLOBAL_INSTALL_DIR"
    echo "RetroPie está instalado. Usando el directorio global: $INSTALL_DIR"
else
    INSTALL_DIR="$USER_INSTALL_DIR"
    echo "RetroPie no está instalado. Configurando en el directorio del usuario: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/scripts"
    touch "$INSTALL_DIR/version.txt"
    echo "0.0" > "$INSTALL_DIR/version.txt"
fi

SCRIPT_PATH="$INSTALL_DIR/scripts/menu-super-retropie.sh"
VERSION_FILE="$INSTALL_DIR/version.txt"
