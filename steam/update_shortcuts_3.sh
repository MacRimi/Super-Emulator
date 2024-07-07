#!/bin/bash

echo
echo "Updating shortcuts/launchers..."
echo

github_url="https://github.com/uureel/batocera.pro/raw/main/steam/shortcuts/"
target_directory="/userdata/roms/conty/"

# List of .sh files to download
sh_files=(
    "Steam Big Picture Mode.sh"
    "Steam Diagnostic.sh"
    "Steam.sh"
    "SteamTinker Launch (settings).sh"
)

# List of .sh files to remove
old_sh_files=(
    "Steam Big Picture Mode.sh"
    "Steam Diagnostic.sh"
    "Steam.sh"
    "SteamTinker Launch (settings).sh"
)

# Create target directory if it doesn't exist
mkdir -p "$target_directory"

# Remove old version .sh files
for file in "${old_sh_files[@]}"; do
    rm "${target_directory}${file}" 2>/dev/null
done

# Download new .sh files
for file in "${sh_files[@]}"; do
    # Replace spaces with '%20' for URL encoding
    encoded_file=$(echo "$file" | sed 's/ /%20/g')
    echo "Downloading $file..."
    curl --progress-bar --retry 50 --retry-delay 5 --max-time 600 --connect-timeout 30 --insecure --location --output "${target_directory}${file}" "${github_url}${encoded_file}"
    if [ $? -ne 0 ]; then
        echo "Error downloading $file"
    fi
    sleep 0.1
done

# Convert line endings and set execute permissions
dos2unix "${target_directory}"/*.sh 2>/dev/null
chmod 777 "${target_directory}"/*.sh 2>/dev/null

echo "Downloaded shortcuts."
echo
sleep 1

# Prepare directories and remove old configuration files
mkdir -p /userdata/system/configs/evmapy 2>/dev/null
rm /userdata/system/configs/emulationstation/es_features_steam2.cfg 2>/dev/null

echo "Downloading parsers and custom systems..."
curl --progress-bar --retry 50 --retry-delay 5 --max-time 600 --connect-timeout 30 --insecure --location --output /userdata/roms/conty/+UPDATE-STEAM-SHORTCUTS.sh "https://raw.githubusercontent.com/MacRimi/Super-Emulator/main/steam/shortcuts/%2BUPDATE-STEAM-SHORTCUTS.sh"
dos2unix /userdata/roms/conty/+UPDATE-STEAM-SHORTCUTS.sh 2>/dev/null
chmod 777 /userdata/roms/conty/+UPDATE-STEAM-SHORTCUTS.sh 2>/dev/null

echo "Downloading configuration files..."
config_files=(
    "es_systems_arch.cfg"
    "es_features_arch.cfg"
    "es_systems_steam2.cfg"
    "es_features_steam2.cfg"
)

for file in "${config_files[@]}"; do
    echo "Downloading $file..."
    curl --progress-bar --retry 50 --retry-delay 5 --max-time 600 --connect-timeout 30 --insecure --location --output "/userdata/system/configs/emulationstation/${file}" "https://github.com/uureel/batocera.pro/raw/main/steam/shortcuts/es_configs/${file}"
    if [ $? -ne 0 ]; then
        echo "Error downloading $file"
    fi
    sleep 0.1
done

echo "Downloading key mappings..."
key_files=(
    "Arch.keys"
    "steam2.keys"
    "steam.keys"
)

for file in "${key_files[@]}"; do
    echo "Downloading $file..."
    curl --progress-bar --retry 50 --retry-delay 5 --max-time 600 --connect-timeout 30 --insecure --location --output "/userdata/system/configs/evmapy/${file}" "https://github.com/uureel/batocera.pro/raw/main/steam/shortcuts/es_configs/keys/${file}"
    if [ $? -ne 0 ]; then
        echo "Error downloading $file"
    fi
    sleep 0.1
done

echo "Downloading patcher script..."
curl --progress-bar --retry 50 --retry-delay 5 --max-time 600 --connect-timeout 30 --insecure --location --output /userdata/system/pro/steam/batocera-conty-patcher.sh "https://raw.githubusercontent.com/uureel/batocera.pro/main/steam/build/batocera-conty-patcher.sh"
if [ $? -ne 0 ]; then
    echo "Error downloading patcher script"
fi

# Convert line endings and set execute permissions
dos2unix /userdata/system/configs/emulationstation/*.cfg 2>/dev/null
dos2unix /userdata/system/configs/evmapy/*.keys 2>/dev/null
dos2unix /userdata/system/pro/steam/batocera-conty-patcher.sh 2>/dev/null
chmod 777 /userdata/system/pro/steam/batocera-conty-patcher.sh 2>/dev/null

# Cleanup old scripts
rm /userdata/system/pro/steam/prepare.sh 2>/dev/null
dos2unix /userdata/roms/conty/*.sh 2>/dev/null
chmod 777 /userdata/roms/conty/*.sh 2>/dev/null

# Download gamelist.xml
echo "Downloading gamelist.xml..."
curl --progress-bar --retry 50 --retry-delay 5 --max-time 600 --connect-timeout 30 --insecure --location --output "${target_directory}gamelist.xml" "https://raw.githubusercontent.com/MacRimi/Super-Emulator/main/steam/shortcuts/gamelist.xml"
if [ $? -ne 0 ]; then
    echo "Error downloading gamelist.xml"
fi

# Create images directory
images_directory="${target_directory}images/"
mkdir -p "$images_directory"

# List of image files to download
image_files=(
    "+UPDATE-STEAM-SHORTCUTS-image.png"
    "Steam Big Picture Mode-image.png"
    "Steam-image.png"
    "Steam Diagnostic-image.png"
    "SteamTinker Launch (settings)-image.png"
)

# Download image files
for image in "${image_files[@]}"; do
    # Replace spaces with '%20' for URL encoding
    encoded_image=$(echo "$image" | sed 's/ /%20/g')
    echo "Downloading $image..."
    curl --progress-bar --retry 50 --retry-delay 5 --max-time 600 --connect-timeout 30 --insecure --location --output "${images_directory}${image}" "https://raw.githubusercontent.com/MacRimi/Super-Emulator/main/steam/shortcuts/images/${encoded_image}"
    if [ $? -ne 0 ]; then
        echo "Error downloading $image"
    fi
    sleep 0.1
done

sleep 1
echo "Done."
sleep 1

# Reload emulationstation
curl http://127.0.0.1:1234/reloadgames
