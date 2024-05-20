#!/bin/bash

# Asegurarse de que el script se ejecute con permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit 1
fi

# Verificar si RetroPie está instalado
if command -v emulationstation &> /dev/null; then
    # RetroPie está instalado, proceder con la instalación adicional
    echo "RetroPie está instalado. Procediendo con la instalación de las funciones adicionales..."

    ##############################
    # Lógica de instalación aquí #
    ##############################

    # Descargar y ejecutar el otro script
    wget -qO- https://raw.githubusercontent.com/MacRimi/Super-RetroPie/main/scripts/menu-super-retropie.sh | sudo bash

    # Verificar si el usuario canceló la instalación adicional
    if [[ $? -eq 1 ]]; then
        # Si se cancela, salir del primer script también
        exit 1
    fi

else
    # RetroPie no está instalado, mostrar mensaje informativo
    echo "RetroPie no está instalado. Las siguientes opciones estarán disponibles:"
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

# Función para instalar RetroPie
install_retropie() {
  # Verificar si expect está instalado, si no, instalarlo
  if ! command -v expect &> /dev/null; then
    echo "El paquete expect no está instalado. Instalándolo..."
    apt-get update
    apt-get install -y expect
  fi

  # Descargar el script bootstrap.sh
  wget -q https://raw.githubusercontent.com/MizterB/RetroPie-Setup-Ubuntu/master/bootstrap.sh

  # Ejecutar el script bootstrap.sh
  bash ./bootstrap.sh

  # Simular presionar Enter para aceptar el disclaimer y continuar con la instalación (usando expect)
  expect << EOF
  spawn sudo ./RetroPie-Setup-Ubuntu/retropie_setup_ubuntu.sh
  expect {
      "Press any key to continue" { send "\r"; exp_continue }
      "RetroPie Setup" { send "\r"; exp_continue }
      "Exit" { send "\r" }
  }
EOF

  # Reboot del sistema
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

    # Si se seleccionó instalar RetroPie
    if echo "$opciones" | grep -q "2"; then
        dialog --yesno "¿Desea continuar con la instalación de RetroPie?" 10 60
        if [[ $? -eq 0 ]]; then
            install_retropie
            return
        else
            clear
        fi
    fi

    # Si se seleccionó extender el disco
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
