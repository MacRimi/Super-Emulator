#!/bin/bash

# Variables
NAS_MOUNT_POINT="/mnt/nas"
BACKUP_DIR="$NAS_MOUNT_POINT/backups"
SHARE_SOURCE="/userdata"
BOOT_SOURCE="/boot"
TEMP_DEST="/mnt/temporal_restore"
BOOT_DEST="/boot"
FINAL_DEST="/userdata"

# Montar NAS
mount_nas() {
    sudo mkdir -p $NAS_MOUNT_POINT
    sudo mount -t cifs -o username=tu_usuario,password=tu_contraseña //IP_DEL_NAS/RUTA_COMPARTIDA $NAS_MOUNT_POINT
}

# Desmontar NAS
umount_nas() {
    sudo umount $NAS_MOUNT_POINT
}

# Crear copia de seguridad
backup() {
    echo "Selecciona la opción de copia de seguridad:"
    echo "1. Completa"
    echo "2. Partición Boot"
    echo "3. Partición Share"
    read backup_option

    case $backup_option in
        1)
            echo "Creando copia de seguridad completa..."
            tar -czvf "$BACKUP_DIR/batocera_share_backup_$(date +'%Y-%m-%d').tar.gz" $SHARE_SOURCE
            tar -czvf "$BACKUP_DIR/batocera_boot_backup_$(date +'%Y-%m-%d').tar.gz" $BOOT_SOURCE
            ;;
        2)
            echo "Creando copia de seguridad de la partición Boot..."
            tar -czvf "$BACKUP_DIR/batocera_boot_backup_$(date +'%Y-%m-%d').tar.gz" $BOOT_SOURCE
            ;;
        3)
            echo "Creando copia de seguridad de la partición Share..."
            tar -czvf "$BACKUP_DIR/batocera_share_backup_$(date +'%Y-%m-%d').tar.gz" $SHARE_SOURCE
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Restaurar copia de seguridad
restore() {
    echo "Selecciona la opción de restauración:"
    echo "1. Completa"
    echo "2. Partición Boot"
    echo "3. Partición Share"
    read restore_option

    case $restore_option in
        1)
            echo "Restaurando copia de seguridad completa..."
            echo "Archivos de respaldo disponibles en $BACKUP_DIR:"
            ls $BACKUP_DIR

            echo "Introduce el nombre del archivo de respaldo de la partición Boot (incluyendo la extensión):"
            read BOOT_BACKUP_FILE
            echo "Introduce el nombre del archivo de respaldo de la partición Share (incluyendo la extensión):"
            read SHARE_BACKUP_FILE

            if [ ! -f "$BACKUP_DIR/$BOOT_BACKUP_FILE" ] || [ ! -f "$BACKUP_DIR/$SHARE_BACKUP_FILE" ]; then
                echo "Uno o ambos archivos de respaldo no existen."
                return
            fi

            sudo mkdir -p $TEMP_DEST

            sudo mount -o remount,rw /boot
            sudo tar -xzvf "$BACKUP_DIR/$BOOT_BACKUP_FILE" -C $TEMP_DEST
            sudo mv $TEMP_DEST/* $BOOT_DEST

            sudo tar -xzvf "$BACKUP_DIR/$SHARE_BACKUP_FILE" -C $TEMP_DEST
            sudo mv $TEMP_DEST/* $FINAL_DEST

            sudo rm -rf $TEMP_DEST
            ;;
        2)
            echo "Restaurando copia de seguridad de la partición Boot..."
            echo "Archivos de respaldo disponibles en $BACKUP_DIR:"
            ls $BACKUP_DIR

            echo "Introduce el nombre del archivo de respaldo de la partición Boot (incluyendo la extensión):"
            read BOOT_BACKUP_FILE

            if [ ! -f "$BACKUP_DIR/$BOOT_BACKUP_FILE" ]; then
                echo "El archivo de respaldo $BOOT_BACKUP_FILE no existe."
                return
            fi

            sudo mkdir -p $TEMP_DEST

            sudo mount -o remount,rw /boot
            sudo tar -xzvf "$BACKUP_DIR/$BOOT_BACKUP_FILE" -C $TEMP_DEST
            sudo mv $TEMP_DEST/* $BOOT_DEST

            sudo rm -rf $TEMP_DEST
            ;;
        3)
            echo "Restaurando copia de seguridad de la partición Share..."
            echo "Archivos de respaldo disponibles en $BACKUP_DIR:"
            ls $BACKUP_DIR

            echo "Introduce el nombre del archivo de respaldo de la partición Share (incluyendo la extensión):"
            read SHARE_BACKUP_FILE

            if [ ! -f "$BACKUP_DIR/$SHARE_BACKUP_FILE" ]; then
                echo "El archivo de respaldo $SHARE_BACKUP_FILE no existe."
                return
            fi

            sudo mkdir -p $TEMP_DEST

            sudo tar -xzvf "$BACKUP_DIR/$SHARE_BACKUP_FILE" -C $TEMP_DEST
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

mount_nas

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

umount_nas
