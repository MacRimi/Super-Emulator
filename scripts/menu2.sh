#!/bin/bash

# Comprobar si 'dialog' está instalado
if ! command -v dialog &> /dev/null; then
    echo "'dialog' no está instalado. Instalando 'dialog'..."
    sudo apt-get update
    sudo apt-get install -y dialog
fi

# Función para instalar RPCS3
instalar_rpcs3() {
    ./script_instalar_rpcs3.sh
}

# Función para instalar Yuzu
instalar_yuzu() {
    if [ ! -f ~/Descargas/yuzu.AppImage ]; then
        dialog --msgbox "Para poder instalar Yuzu necesitas previamente tener yuzu.AppImage descargado en la carpeta de Descargas de tu equipo." 10 60
        return 1
    fi
    ./script_instalar_yuzu.sh
}

# Función para instalar Steam
instalar_steam() {
    ./script_instalar_steam.sh
}

# Función para ajustes de emuladores
ajustes_emuladores() {
    ./script_ajustes_emuladores.sh
}

# Función para mostrar el menú y capturar la selección
mostrar_menu() {
    opciones=$(dialog --checklist "Seleccione los scripts a ejecutar:" 20 60 4 \
        1 "Instalar RPCS3 (Play Station 3)" off \
        2 "Instalar Yuzu (Nintendo Switch)" off \
        3 "Instalar Steam" off \
        4 "Ajustes Emuladores" off 3>&1 1>&2 2>&3 3>&-)
    respuesta=$?
    echo $respuesta $opciones
}

while true; do
    # Mostrar el menú de selección
    respuesta_opciones=$(mostrar_menu)
    respuesta=$(echo $respuesta_opciones | awk '{print $1}')
    opciones=$(echo $respuesta_opciones | cut -d' ' -f2-)

    # Verificar si se seleccionó la opción 2 (Yuzu)
    if echo "$opciones" | grep -q "2"; then
        dialog --msgbox "Para poder instalar Yuzu necesitas previamente tener yuzu.AppImage descargado en la carpeta de Descargas de tu equipo." 10 60
    fi

    # Confirmar la selección
    confirmacion=$(dialog --yesno "¿Desea continuar con la instalación de los scripts seleccionados?" 10 60 3>&1 1>&2 2>&3 3>&-)
    if [[ $? -eq 0 ]]; then
        break
    fi
done

# Acciones basadas en la selección del usuario
clear
for opcion in $opciones; do
    case $opcion in
        1)
            echo "Instalando RPCS3..."
            instalar_rpcs3
            ;;
        2)
            echo "Instalando Yuzu..."
            instalar_yuzu
            ;;
        3)
            echo "Instalando Steam..."
            instalar_steam
            ;;
        4)
            echo "Ajustando Emuladores..."
            ajustes_emuladores
            ;;
    esac
done
echo "Instalación completada."
