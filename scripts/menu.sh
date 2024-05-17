#!/bin/bash

# Lista de scripts disponibles
options=("Script 1" "Script 2" "Script 3")

# Función para mostrar la lista de opciones y obtener la selección del usuario
select_scripts() {
    local selected_scripts=()
    while true; do
        local choice=$(whiptail --title "Seleccionar Scripts" --checklist "Seleccione los scripts para instalar:" 15 60 4 "${options[@]}" 3>&1 1>&2 2>&3)
        if [[ -z $choice ]]; then
            whiptail --title "Mensaje" --msgbox "No se seleccionaron scripts. Por favor, seleccione al menos uno." 8 60
        else
            selected_scripts=($choice)
            break
        fi
    done
    install_scripts "${selected_scripts[@]}"
}

# Función para instalar los scripts seleccionados
install_scripts() {
    local scripts=("$@")
    for script in "${scripts[@]}"; do
        case $script in
            "Script 1")
                echo "Instalando Script 1..."
                # Llamar al script 1
                ;;
            "Script 2")
                echo "Instalando Script 2..."
                # Llamar al script 2
                ;;
            "Script 3")
                echo "Instalando Script 3..."
                # Llamar al script 3
                ;;
        esac
    done
}

# Ejecutar la función para mostrar la lista de opciones
select_scripts
