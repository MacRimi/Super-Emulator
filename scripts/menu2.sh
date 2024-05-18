#!/bin/bash

# Comprobar si 'dialog' está instalado
if ! command -v dialog &> /dev/null; then
    echo "'dialog' no está instalado. Instalando 'dialog'..."
    sudo apt-get update
    sudo apt-get install -y dialog
fi

#############################
# Función para añadir RPCS3
#############################
instalar_rpcs3() {
  local script_path=~/RetroPie-Setup/scriptmodules/emulators/rpcs3-appImage.sh
    local platforms_cfg=/opt/retropie/configs/all/platforms.cfg


    echo "Añadir script de instalación de RPCS3..."
    wget -q --show-progress https://raw.githubusercontent.com/raelgc/retropie_rpcs3-appImage/master/rpcs3-appImage.sh -O "$script_path"
    chmod +x "$script_path"

    # Verificar si existe platforms.cfg
    if [ -f "$platforms_cfg" ]; then
        # Agregar las líneas al final del archivo
        echo "Añadiendo configuración de RPCS3 a platforms.cfg..."
        echo "ps3_exts=\".ps3\"" >> "$platforms_cfg"
        echo "ps3_fullname=\"PlayStation 3\"" >> "$platforms_cfg"
    else
        # Crear platforms.cfg y agregar las líneas
        echo "Creando platforms.cfg y añadiendo configuración de RPCS3..."
        echo "ps3_exts=\".ps3\"" > "$platforms_cfg"
        echo "ps3_fullname=\"PlayStation 3\"" >> "$platforms_cfg"
    fi
}

############################
# Función para añadir Yuzu
############################
instalar_yuzu() {
     local script_path=~/RetroPie-Setup/scriptmodules/emulators/yuzu-AppImage.sh
    local platforms_cfg=/opt/retropie/configs/all/platforms.cfg
    if [ ! -f ~/Descargas/yuzu.AppImage ]; then
        dialog --msgbox "Para poder instalar Yuzu necesitas previamente tener yuzu.AppImage descargado en la carpeta de Descargas de tu equipo." 10 60
        return 1
    fi
    echo "Descargando o actualizando script de instalación de Yuzu..."
    wget -q --show-progress https://raw.githubusercontent.com/MacRimi/SuperEmulator/main/scripts/yuzu-AppImage.sh -O "$script_path"
    chmod +x "$script_path"

    # Verificar si existe platforms.cfg
    if [ -f "$platforms_cfg" ]; then
        # Agregar las líneas al final del archivo
        echo "Añadiendo configuración de Yuzu a platforms.cfg..."
        echo "yuzu_exts=\".nsp .xci\"" >> "$platforms_cfg"
        echo "yuzu_fullname=\"Nintendo Switch\"" >> "$platforms_cfg"
    else
        # Crear platforms.cfg y agregar las líneas
        echo "Creando platforms.cfg y añadiendo configuración de Yuzu..."
        echo "yuzu_exts=\".nsp .xci\"" > "$platforms_cfg"
        echo "yuzu_fullname=\"Nintendo Switch\"" >> "$platforms_cfg"
    fi
}

###########################
# Función para añadir Steam
###########################
instalar_steam() {
    local script_path=~/RetroPie-Setup/scriptmodules/emulators/steam-AppImage.sh
    local platforms_cfg=/opt/retropie/configs/all/platforms.cfg
    
    # Descargar o actualizar el script de instalación de Steam
    echo "Descargando o actualizando script de instalación de Steam..."
    wget -q --show-progress https://raw.githubusercontent.com/MacRimi/SuperEmulator/main/scripts/steam-AppImage.sh -O "$script_path"
    chmod +x "$script_path"

        # Verificar si existe platforms.cfg
    if [ -f "$platforms_cfg" ]; then
        # Agregar las líneas al final del archivo
        echo "Añadiendo configuración de Steam a platforms.cfg..."
        echo "steam_exts=\".sh\"" >> "$platforms_cfg"
        echo "steam_fullname=\"Steam\"" >> "$platforms_cfg"
        echo "steam_command=\"%ROM%\"" >> "$platforms_cfg"
        # Añadir ajustes
        echo "ajustes_exts=\".sh\"" >> "$platforms_cfg"
        echo "ajustes_fullname=\"Ajustes\"" >> "$platforms_cfg"
        echo "ajustes_command=\"%ROM%\"" >> "$platforms_cfg"
        echo "ajustes_platform=\"config\"" >> "$platforms_cfg"
    else
        # Crear platforms.cfg y agregar las líneas
        echo "Creando platforms.cfg y añadiendo configuración de Yuzu..."
        echo "steam_exts=\".nsp .xci\"" > "$platforms_cfg"
        echo "steam_fullname=\"Steam\"" >> "$platforms_cfg"
        echo "steam_command=\"%ROM%\"" >> "$platforms_cfg"
         # Añadir ajustes
        echo "ajustes_exts=\".sh\"" >> "$platforms_cfg"
        echo "ajustes_fullname=\"Ajustes\"" >> "$platforms_cfg"
        echo "ajustes_command=\"%ROM%\"" >> "$platforms_cfg"
        echo "ajustes_platform=\"config\"" >> "$platforms_cfg"
    fi
}

#################################
# Función para ajustar emuladores 
#################################
ajustes_emuladores() {
    local emulators_dir=/opt/retropie/emulators
    local ajustes_dir=~/RetroPie/roms/ajustes

    mkdir -p "$ajustes_dir"

    for emulador in "$emulators_dir"/*; do
        emulador_name=$(basename "$emulador")

        if [[ "$emulador_name" != "retroarch" && "$emulador_name" != "mupen64plus" ]]; then
            script_path="$ajustes_dir/$emulador_name.sh"

            echo "Creando script para el emulador $emulador_name..."
            echo "#!/bin/bash" > "$script_path"
            echo "cd $emulador" >> "$script_path"
            echo "./$emulador_name" >> "$script_path"

            chmod +x "$script_path"
        fi
    done

    echo "Ajustes de emuladores completados."
}

# Mostrar el menú y capturar la selección
while true; do
    opciones=$(dialog --checklist "Seleccione los scripts a ejecutar:" 20 60 4 \
        1 "Instalar RPCS3 (Play Station 3)" off \
        2 "Instalar Yuzu (Nintendo Switch)" off \
        3 "Instalar Steam" off \
        4 "Ajustes Emuladores" off 3>&1 1>&2 2>&3 3>&-)

    respuesta=$?

    if [[ $respuesta -eq 1 || $respuesta -eq 255 ]]; then
        clear
        echo "Instalación cancelada o salida del script."
        exit 1
    fi

    # Mostrar advertencia si se selecciona Yuzu
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
