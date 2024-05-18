#!/bin/bash

# Asegúrate de que el script se está ejecutando con privilegios de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Reboot reminder
echo "Asegúrate de que has reiniciado el servidor Ubuntu después de la instalación del sistema operativo."
read -p "¿Has reiniciado el servidor y estás listo para continuar? (s/n): " respuesta
if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
  echo "Reinicia el servidor y vuelve a ejecutar este script."
  exit 1
fi

# Comando df para verificar el tamaño del sistema de archivos
echo "Ejecutando df -h para verificar el tamaño del sistema de archivos..."
df -h

# Determinar la ruta del volumen lógico
echo "Determinando la ruta del volumen lógico..."
LV_PATH=$(sudo lvscan | grep "ACTIVE" | awk '{print $4}' | tr -d "'")

if [ -z "$LV_PATH" ]; then
  echo "No se pudo determinar la ruta del volumen lógico. Asegúrate de que el volumen lógico está activo."
  exit 1
fi

echo "Ruta del volumen lógico encontrada: $LV_PATH"

# Extender el volumen lógico
echo "Extendiendo el volumen lógico..."
sudo lvextend -l +100%FREE "$LV_PATH"
if [ $? -ne 0 ]; then
  echo "Error al extender el volumen lógico."
  exit 1
fi

# Redimensionar el sistema de archivos
echo "Redimensionando el sistema de archivos..."
sudo resize2fs "$LV_PATH"
if [ $? -ne 0 ]; then
  echo "Error al redimensionar el sistema de archivos."
  exit 1
fi

echo "El volumen lógico y el sistema de archivos se han extendido correctamente."
