# Crea la carpeta para el nuevo módulo en el directorio de RetroPie Setup
mkdir -p ~/RetroPie-Setup/scriptmodules/exp

# Crea un nuevo archivo de script para el módulo de Steam
cat << 'EOF' > ~/RetroPie-Setup/scriptmodules/exp/steam-appimage.sh
#!/usr/bin/env bash

rp_module_id="steam-appimage"
rp_module_desc="Steam via AppImage"
rp_module_help="Instala Steam como un AppImage para su uso en RetroPie."
rp_module_licence="Proprietary"
rp_module_section="exp"
rp_module_flags="!arm"

function install_bin_steam-appimage() {
    # Crea el directorio para instalar Steam
    mkdir -p "$md_inst/bin"

    # Descarga Steam AppImage
    wget --content-disposition "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" -O "$md_inst/bin/steam.deb"

    # Instala Steam desde el archivo descargado
    sudo apt install -y "$md_inst/bin/steam.deb"
}

function configure_steam-appimage() {
    # Crear el directorio de ROMs para Steam
    mkRomDir "steam"

    # Agregar Steam como emulador en RetroPie/EmulationStation
    addEmulator 0 "$md_id" "steam" "steam -noverifyfiles  -bigpicture"

    # Agregar el sistema "steam" a RetroPie
    addSystem "steam"

    # Asegúrate de que el archivo es_systems.cfg exista y ábrelo para editar
    ES_SYSTEMS_CFG="/opt/retropie/configs/all/emulationstation/es_systems.cfg"

    # Verifica si el sistema "steam" ya está definido para evitar duplicados
    if ! grep -q '<name>steam</name>' "$ES_SYSTEMS_CFG"; then
        # Si no existe, agrega la definición del sistema "steam"
        cat <<EOF2 >> "$ES_SYSTEMS_CFG"
<system>
    <name>steam</name>
    <fullname>Steam</fullname>
    <path>$HOME/RetroPie/roms/steam</path>
    <extension>.sh</extension>
    <command>%ROM%</command>
    <platform>pc</platform>
    <theme>steam</theme>
</system>
EOF2
    fi

    echo "Configuración completada. Reinicia EmulationStation para aplicar los cambios."
}
EOF
