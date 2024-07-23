#!/bin/bash

# Archivo de configuración para guardar los detalles del NAS
CONFIG_FILE="$HOME/.backup_restore_config"

# Variables generales
TEMP_DEST="/mnt/temporal_restore"
SHARE_SOURCE="/userdata"
BOOT_SOURCE="/boot"
FINAL_DEST="/userdata"
BOOT_DEST="/boot"

# Función para montar NAS
mount_nas() {
    source $CONFIG_FILE
    sudo mkdir -p $NAS_MOUNT_POINT
    sudo mount -t cifs -o username=$NAS_USERNAME,password=$NAS_PASSWORD //$NAS_IP/$NAS_SHARE $NAS_MOUNT_POINT
}

# Función para desmontar NAS
umount_nas() {
    sudo umount $NAS_MOUNT_POINT
}

# Función para seleccionar ubicación de backup o restauración
select_location() {
    echo "Selecciona la ubicación:"
    echo "1. Disco duro extra"
    echo "2. Dispositivo USB"
    echo "3. Ubicación de red (NAS)"
    read location_option

    case $location_option in
        1)
            echo "Discos duros disponibles:"
            lsblk -nd -o NAME,SIZE | grep -v $(lsblk -n -o NAME,MOUNTPOINT | grep '/$' | cut -d ' ' -f 1)
            echo "Introduce la ruta del disco duro extra (e.g., /mnt/extradrive):"
            read LOCATION
            ;;
        2)
            echo "Dispositivos USB disponibles:"
            lsblk -nd -o NAME,SIZE | grep -v $(lsblk -n -o NAME,MOUNTPOINT | grep '/$' | cut -d ' ' -f 1)
            echo "Introduce la ruta del dispositivo USB (e.g., /mnt/usbdrive):"
            read LOCATION
            ;;
        3)
            if [ -f $CONFIG_FILE ]; then
                source $CONFIG_FILE
                echo "Usando la configuración guardada del NAS:"
                echo "IP: $NAS_IP"
                echo "Carpeta compartida: $NAS_SHARE"
                echo "Usuario: $NAS_USERNAME"
            else
                echo "Introduce los detalles del NAS:"
                echo "IP del NAS:"
                read NAS_IP
                echo "Carpeta compartida del NAS:"
                read NAS_SHARE
                echo "Usuario del NAS:"
                read NAS_USERNAME
                echo "Contraseña del NAS:"
                read -s NAS_PASSWORD

                # Guardar configuración
                echo "NAS_IP=$NAS_IP" > $CONFIG_FILE
                echo "NAS_SHARE=$NAS_SHARE" >> $CONFIG_FILE
                echo "NAS_USERNAME=$NAS_USERNAME" >> $CONFIG_FILE
                echo "NAS_PASSWORD=$NAS_PASSWORD" >> $CONFIG_FILE
                echo "NAS_MOUNT_POINT=/mnt/nas" >> $CONFIG_FILE
            fi

            NAS_MOUNT_POINT="/mnt/nas"
            BACKUP_DIR="$NAS_MOUNT_POINT/backups"
            LOCATION=$BACKUP_DIR
            mount_nas
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Función para crear copia de seguridad
backup() {
    echo "Selecciona la opción de copia de seguridad:"
    echo "1. Completa"
    echo "2. Partición Boot"
    echo "3. Partición Share"
    read backup_option

    case $backup_option in
        1)
            echo "Creando copia de seguridad completa..."
            tar -czvf "$LOCATION/batocera_share_backup_$(date +'%Y-%m-%d').tar.gz" $SHARE_SOURCE
            tar -czvf "$LOCATION/batocera_boot_backup_$(date +'%Y-%m-%d').tar.gz" $BOOT_SOURCE
            ;;
        2)
            echo "Creando copia de seguridad de la partición Boot..."
            tar -czvf "$LOCATION/batocera_boot_backup_$(date +'%Y-%m-%d').tar.gz" $BOOT_SOURCE
            ;;
        3)
            echo "Creando copia de seguridad de la partición Share..."
            tar -czvf "$LOCATION/batocera_share_backup_$(date +'%Y-%m-%d').tar.gz" $SHARE_SOURCE
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Función para restaurar copia de seguridad
restore() {
    echo "Selecciona la opción de restauración:"
    echo "1. Completa"
    echo "2. Partición Boot"
    echo "3. Partición Share"
    read restore_option

    case $restore_option in
        1)
            echo "Restaurando copia de seguridad completa..."
            echo "Archivos de respaldo disponibles en $LOCATION:"
            ls $LOCATION

            echo "Introduce el nombre del archivo de respaldo de la partición Boot (incluyendo la extensión):"
            read BOOT_BACKUP_FILE
            echo "Introduce el nombre del archivo de respaldo de la partición Share (incluyendo la extensión):"
            read SHARE_BACKUP_FILE

            if [ ! -f "$LOCATION/$BOOT_BACKUP_FILE" ] || [ ! -f "$LOCATION/$SHARE_BACKUP_FILE" ]; then
                echo "Uno o ambos archivos de respaldo no existen."
                return
            fi

            sudo mkdir -p $TEMP_DEST

            sudo mount -o remount,rw /boot
            sudo tar -xzvf "$LOCATION/$BOOT_BACKUP_FILE" -C $TEMP_DEST
            sudo mv $TEMP_DEST/* $BOOT_DEST

            sudo tar -xzvf "$LOCATION/$SHARE_BACKUP_FILE" -C $TEMP_DEST
            sudo mv $TEMP_DEST/* $FINAL_DEST

            sudo rm -rf $TEMP_DEST
            ;;
        2)
            echo "Restaurando copia de seguridad de la partición Boot..."
            echo "Archivos de respaldo disponibles en $LOCATION:"
            ls $LOCATION

            echo "Introduce el nombre del archivo de respaldo de la partición Boot (incluyendo la extensión):"
            read BOOT_BACKUP_FILE

            if [ ! -f "$LOCATION/$BOOT_BACKUP_FILE" ]; then
                echo "El archivo de respaldo $BOOT_BACKUP_FILE no existe."
                return
            fi

            sudo mkdir -p $TEMP_DEST

            sudo mount -o remount,rw /boot
            sudo tar -xzvf "$LOCATION/$BOOT_BACKUP_FILE" -C $TEMP_DEST
            sudo mv $TEMP_DEST/* $BOOT_DEST

            sudo rm -rf $TEMP_DEST
            ;;
        3)
            echo "Restaurando copia de seguridad de la partición Share..."
            echo "Archivos de respaldo disponibles en $LOCATION:"
            ls $LOCATION

            echo "Introduce el nombre del archivo de respaldo de la partición Share (incluyendo la extensión):"
            read SHARE_BACKUP_FILE

            if [ ! -f "$LOCATION/$SHARE_BACKUP_FILE" ]; then
                echo "El archivo de respaldo $SHARE_BACKUP_FILE no existe."
                return
            fi

            sudo mkdir -p $TEMP_DEST

            sudo tar -xzvf "$LOCATION/$SHARE_BACKUP_FILE" -C $TEMP_DEST
            sudo mv $TEMP_DEST/* $FINAL_DEST

            sudo rm -rf $TEMP_DEST
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Menú principal
echo "Selecciona una opción:"
echo "1. Crear copia de seguridad"
echo "2. Restaurar copia de seguridad"
read main_option

select_location

case $main_option in
    1)
        backup
        ;;
    2)
        restore
        ;;
    *)
        echo "Opción no válida."
        ;;
esac

if [ "$location_option" -eq 3 ]; then
    umount_nas
fi
