#!/bin/bash

# Asegurarse de que el script se ejecute con permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit 1
fi

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
