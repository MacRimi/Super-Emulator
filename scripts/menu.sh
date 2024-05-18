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

# Mostrar el menú y capturar la selección
opciones=$(dialog --checklist "Seleccione los scripts a ejecutar:" 20 60 4 \
    1 "Instalar RPCS3 (Play Station 3)" off \
    2 "Instalar Yuzu (Nintendo Switch)" off \
    3 "Instalar Steam" off \
    4 "Ajustes Emuladores" off 3>&1 1>&2 2>&3 3>&-)

# Capturar el código de retorno
respuesta=$?

# Acciones basadas en la respuesta del usuario
case $respuesta in
    0) # OK fue seleccionado
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
        ;;
    1) # Cancelar fue seleccionado
        clear
        echo "Instalación cancelada."
        ;;
    255) # Salir fue seleccionado (Esc o cerrar ventana)
        clear
        echo "Ha salido del script."
        ;;
esac
