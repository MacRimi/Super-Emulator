#!/bin/bash

# Archivo de configuración para guardar los detalles del NAS
CONFIG_FILE="$HOME/.backup_restore_config"
RSYNC_BIN="/usr/bin/rsync"

# Función para verificar si rsync está instalado
check_rsync() {
    if ! command -v rsync &> /dev/null; then
        echo "rsync no está instalado. Por favor, instala rsync y vuelve a intentarlo."
        exit 1
    fi
}

# Variables generales
TEMP_DEST="/mnt/temporal_restore"
SHARE_SOURCE="/userdata"
BOOT_SOURCE="/boot"
FINAL_DEST="/userdata"
BOOT_DEST="/boot"
RSYNC_OPTIONS="-av --progress --partial --inplace --delete --numeric-ids --copy-links"

# Función para montar NAS con reintentos
mount_nas() {
    source $CONFIG_FILE
    mkdir -p $NAS_MOUNT_POINT
    
    # Verificar si ya está montado
    if mountpoint -q $NAS_MOUNT_POINT; then
        echo "El NAS ya está montado en $NAS_MOUNT_POINT."
        return
    fi

    ATTEMPTS=3
    SUCCESS=0

    for ((i=1; i<=ATTEMPTS; i++)); do
        echo "Intentando montar el NAS (Intento $i de $ATTEMPTS)..."
        mount -t cifs -o username=$NAS_USERNAME,password=$NAS_PASSWORD,mfsymlinks //$NAS_IP/$NAS_SHARE $NAS_MOUNT_POINT
        if [ $? -eq 0 ]; then
            echo "NAS montado correctamente."
            SUCCESS=1
            break
        else
            echo "Error al montar el NAS. Reintentando en 5 segundos..."
            sleep 5
        fi
    done

    if [ $SUCCESS -eq 0 ]; then
        echo "Error al montar el NAS después de $ATTEMPTS intentos."
        exit 1
    fi

    mkdir -p $BACKUP_DIR
}

# Función para desmontar NAS
umount_nas() {
    umount $NAS_MOUNT_POINT
}

# Función para verificar la opción nosymfollow en el montaje
check_nosymfollow() {
    MOUNT_OPTIONS=$(mount | grep $NAS_MOUNT_POINT | awk '{print $6}')
    if [[ $MOUNT_OPTIONS == *"nosymfollow"* ]]; then
        dialog --msgbox "La opción de montaje 'nosymfollow' está activa. Esto impedirá la copia de enlaces simbólicos. Por favor, remonta el NAS sin esta opción." 10 50
        exit 1
    fi
}

# Función para verificar el sistema de archivos
check_filesystem() {
    FILESYSTEM=$(df -T $NAS_MOUNT_POINT | tail -1 | awk '{print $2}')
    case $FILESYSTEM in
        ext4|btrfs|xfs|ntfs|apfs|cifs)
            echo "El sistema de archivos $FILESYSTEM es compatible con symlinks."
            ;;
        *)
            echo "El sistema de archivos $FILESYSTEM no es compatible con symlinks."
            dialog --msgbox "El sistema de archivos $FILESYSTEM en $LOCATION no soporta symlinks. Por favor, usa un sistema de archivos compatible como ext4, btrfs, xfs, ntfs o apfs." 10 50
            exit 1
            ;;
    esac
}

# Función para seleccionar ubicación de backup o restauración
select_location() {
    LOCATION=$(dialog --stdout --menu "Selecciona la ubicación:" 15 50 3 \
        1 "Disco duro extra" \
        2 "Dispositivo USB" \
        3 "Ubicación de red (NAS)")

    case $LOCATION in
        1)
            DISK=$(lsblk -nd -o NAME,SIZE | grep -v $(lsblk -n -o NAME,MOUNTPOINT | grep '/$' | cut -d ' ' -f 1) | awk '{print $1, $2}' | dialog --stdout --menu "Discos duros disponibles:" 15 50 6)
            LOCATION="/mnt/$DISK"
            ;;
        2)
            USB=$(lsblk -nd -o NAME,SIZE | grep -v $(lsblk -n -o NAME,MOUNTPOINT | grep '/$' | cut -d ' ' -f 1) | awk '{print $1, $2}' | dialog --stdout --menu "Dispositivos USB disponibles:" 15 50 6)
            LOCATION="/mnt/$USB"
            ;;
        3)
            if [ -f $CONFIG_FILE ]; then
                source $CONFIG_FILE
                dialog --yesno "Usar la configuración guardada del NAS?\nIP: $NAS_IP\nCarpeta compartida: $NAS_SHARE\nUsuario: $NAS_USERNAME" 15 50
                if [ $? -ne 0 ]; then
                    NAS_IP=$(dialog --stdout --inputbox "IP del NAS:" 8 40)
                    NAS_SHARE=$(dialog --stdout --inputbox "Carpeta compartida del NAS:" 8 40)
                    NAS_USERNAME=$(dialog --stdout --inputbox "Usuario del NAS:" 8 40)
                    NAS_PASSWORD=$(dialog --stdout --passwordbox "Contraseña del NAS:" 8 40)

                    # Guardar configuración
                    echo "NAS_IP=$NAS_IP" > $CONFIG_FILE
                    echo "NAS_SHARE=$NAS_SHARE" >> $CONFIG_FILE
                    echo "NAS_USERNAME=$NAS_USERNAME" >> $CONFIG_FILE
                    echo "NAS_PASSWORD=$NAS_PASSWORD" >> $CONFIG_FILE
                    echo "NAS_MOUNT_POINT=/mnt/nas" >> $CONFIG_FILE
                fi
            else
                NAS_IP=$(dialog --stdout --inputbox "IP del NAS:" 8 40)
                NAS_SHARE=$(dialog --stdout --inputbox "Carpeta compartida del NAS:" 8 40)
                NAS_USERNAME=$(dialog --stdout --inputbox "Usuario del NAS:" 8 40)
                NAS_PASSWORD=$(dialog --stdout --passwordbox "Contraseña del NAS:" 8 40)

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
            check_nosymfollow
            check_filesystem
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Función para crear copia de seguridad
backup() {
    BACKUP_OPTION=$(dialog --stdout --menu "Selecciona la opción de copia de seguridad:" 15 50 3 \
        1 "Completa" \
        2 "Partición Boot" \
        3 "Partición Share")

    BACKUP_DIR_NAME="backup_$(date +'%Y-%m-%d')"
    mkdir -p "$LOCATION/$BACKUP_DIR_NAME"

    case $BACKUP_OPTION in
        1)
            echo "Creando copia de seguridad completa..."
            rsync $RSYNC_OPTIONS $SHARE_SOURCE "$LOCATION/$BACKUP_DIR_NAME/share" 2>&1 | tee "$LOCATION/$BACKUP_DIR_NAME/backup_share.log"
            rsync $RSYNC_OPTIONS $BOOT_SOURCE "$LOCATION/$BACKUP_DIR_NAME/boot" 2>&1 | tee "$LOCATION/$BACKUP_DIR_NAME/backup_boot.log"
            ;;
        2)
            echo "Creando copia de seguridad de la partición Boot..."
            rsync $RSYNC_OPTIONS $BOOT_SOURCE "$LOCATION/$BACKUP_DIR_NAME/boot" 2>&1 | tee "$LOCATION/$BACKUP_DIR_NAME/backup_boot.log"
            ;;
        3)
            echo "Creando copia de seguridad de la partición Share..."
            rsync $RSYNC_OPTIONS $SHARE_SOURCE "$LOCATION/$BACKUP_DIR_NAME/share" 2>&1 | tee "$LOCATION/$BACKUP_DIR_NAME/backup_share.log"
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Función para verificar espacio libre
check_space() {
    REQUIRED_SPACE=$(du -s "$LOCATION/$BACKUP_DIR_NAME/$1" | awk '{print $1}')
    AVAILABLE_SPACE=$(df "$FINAL_DEST" | tail -1 | awk '{print $4}')

    if [ "$REQUIRED_SPACE" -gt "$AVAILABLE_SPACE" ]; then
        echo "No hay suficiente espacio libre en el destino para restaurar $1."
        echo "Espacio requerido: $REQUIRED_SPACE KB, Espacio disponible: $AVAILABLE_SPACE KB."
        exit 1
    fi
}

# Función para restaurar copia de seguridad
restore() {
    RESTORE_OPTION=$(dialog --stdout --menu "Selecciona la opción de restauración:" 15 50 3 \
        1 "Completa" \
        2 "Partición Boot" \
        3 "Partición Share")

    # Generar lista de archivos de respaldo disponibles
    BACKUP_LIST=$(ls $LOCATION | awk '{print $1 " " $1}')
    BACKUP_DIR_NAME=$(dialog --stdout --menu "Archivos de respaldo disponibles en $LOCATION:" 15 50 10 $BACKUP_LIST)

    echo "Seleccionado respaldo: $BACKUP_DIR_NAME"
    echo "Contenido del directorio de respaldo seleccionado:"
    ls "$LOCATION/$BACKUP_DIR_NAME"

    case $RESTORE_OPTION in
        1)
            echo "Restaurando copia de seguridad completa..."

            if [ ! -d "$LOCATION/$BACKUP_DIR_NAME/boot" ] || [ ! -d "$LOCATION/$BACKUP_DIR_NAME/share" ]; then
                echo "Una o ambas carpetas de respaldo no existen en $LOCATION/$BACKUP_DIR_NAME."
                return
            fi

            check_space "boot"
            check_space "share"

            mkdir -p $TEMP_DEST

            mount -o remount,rw /boot
            rsync $RSYNC_OPTIONS "$LOCATION/$BACKUP_DIR_NAME/boot/" $BOOT_DEST 2>&1 | tee restore_boot.log

            rsync $RSYNC_OPTIONS "$LOCATION/$BACKUP_DIR_NAME/share/" $FINAL_DEST 2>&1 | tee restore_share.log

            rm -rf $TEMP_DEST
            ;;
        2)
            echo "Restaurando copia de seguridad de la partición Boot..."

            if [ ! -d "$LOCATION/$BACKUP_DIR_NAME/boot" ]; then
                echo "La carpeta de respaldo $LOCATION/$BACKUP_DIR_NAME/boot no existe."
                return
            fi

            check_space "boot"

            mkdir -p $TEMP_DEST

            mount -o remount,rw /boot
            rsync $RSYNC_OPTIONS "$LOCATION/$BACKUP_DIR_NAME/boot/" $BOOT_DEST 2>&1 | tee restore_boot.log

            rm -rf $TEMP_DEST
            ;;
        3)
            echo "Restaurando copia de seguridad de la partición Share..."

            if [ ! -d "$LOCATION/$BACKUP_DIR_NAME/share" ]; then
                echo "La carpeta de respaldo $LOCATION/$BACKUP_DIR_NAME/share no existe."
                return
            fi

            check_space "share"

            mkdir -p $TEMP_DEST

            rsync $RSYNC_OPTIONS "$LOCATION/$BACKUP_DIR_NAME/share/" $FINAL_DEST 2>&1 | tee restore_share.log

            rm -rf $TEMP_DEST
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Limpiar caché del shell
hash -r

# Verificar si rsync está instalado
check_rsync

# Menú principal
MAIN_OPTION=$(dialog --stdout --menu "Selecciona una opción:" 15 50 2 \
    1 "Crear copia de seguridad" \
    2 "Restaurar copia de seguridad")

select_location

case $MAIN_OPTION in
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

if [ "$LOCATION" == "$NAS_MOUNT_POINT" ]; then
    umount_nas
fi
