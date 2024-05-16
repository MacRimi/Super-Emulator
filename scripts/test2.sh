#!/bin/sh

APP=steam

# CREATE A TEMPORARY DIRECTORY
mkdir -p tmp
cd tmp

# DOWNLOADING THE DEPENDENCIES
if test -f ./appimagetool; then
    echo " appimagetool already exists" 1> /dev/null
else
    echo " Downloading appimagetool..."
    wget -q $(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | grep -v zsync | grep -i continuous | grep -i appimagetool | grep -i x86_64 | grep browser_download_url | cut -d '"' -f 4 | head -1) -O appimagetool
fi
if test -f ./pkg2appimage; then
    echo " pkg2appimage already exists" 1> /dev/null
else
    echo " Downloading pkg2appimage..."
    wget -q https://raw.githubusercontent.com/ivan-hc/AM-application-manager/main/tools/pkg2appimage
fi
chmod a+x ./appimagetool ./pkg2appimage
rm -f ./recipe.yml

# CREATING THE APPIMAGE: APPDIR FROM A RECIPE...
echo "app: steam
binpatch: true

ingredients:
  dist: stable
  script:
    - wget https://cdn.akamai.steamstatic.com/client/installer/steam.deb
  sources:
    - deb http://ftp.debian.org/debian/ stable main contrib non-free
  packages:
    - steam
    - coreutils
    - curl
    - grep
    - libc6-i386
    - python3
    - sed
    - steam-libs
    - tar
    - util-linux
    - xz-utils
    - zenity
    - zenity-common" >> recipe.yml;

./pkg2appimage ./recipe.yml;

# ...REPLACING THE EXISTING APPRUN WITH A CUSTOM ONE...
rm -R -f ./$APP/$APP.AppDir/AppRun
cat >> ./$APP/$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export UNION_PRELOAD=/:"${HERE}"
#export LD_PRELOAD="${HERE}"/libunionpreload.so
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:"${HERE}"/usr/bin/:"${HERE}"/usr/games/:"${HERE}"/bin/:"${HERE}"/sbin/:"${PATH}"
export LD_LIBRARY_PATH=/lib/:/lib64/:/lib/x86_64-linux-gnu/:/usr/lib/:"${HERE}"/usr/lib/:"${HERE}"/usr/lib/i386-linux-gnu/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib32/:"${HERE}"/lib/i386-linux-gnu/:"${HERE}"/usr/lib32/:"${HERE}"/lib/x86_64-linux-gnu/:"${LD_LIBRARY_PATH}"
export PYTHONPATH="${HERE}"/usr/share/pyshared/:"${HERE}"/usr/lib/python*/:"${PYTHONPATH}"
export PYTHONHOME="${HERE}"/usr/:"${HERE}"/usr/lib/python*/
export XDG_DATA_DIRS="${HERE}"/usr/share/:"${HERE}"/usr/share/steam/:"${XDG_DATA_DIRS}"
export PERLLIB="${HERE}"/usr/share/perl5/:"${HERE}"/usr/lib/perl5/:"${PERLLIB}"
export GSETTINGS_SCHEMA_DIR="${HERE}"/usr/share/glib-2.0/schemas/:"${GSETTINGS_SCHEMA_DIR}"
export QT_PLUGIN_PATH="${HERE}"/usr/lib/qt4/plugins/:"${HERE}"/usr/lib/steam/:"${HERE}"/usr/lib64/steam/:"${HERE}"/usr/lib32/steam/:"${HERE}"/usr/lib/i386-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib32/qt4/plugins/:"${HERE}"/usr/lib64/qt4/plugins/:"${HERE}"/usr/lib/qt5/plugins/:"${HERE}"/usr/lib/i386-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib32/qt5/plugins/:"${HERE}"/usr/lib64/qt5/plugins/:"${QT_PLUGIN_PATH}"
EOF
chmod a+x ./$APP/$APP.AppDir/AppRun

# Eliminar cualquier archivo steam.desktop que pueda haberse creado accidentalmente
rm -f ./$APP/$APP.AppDir/*.desktop

# ...EXPORT THE APPDIR TO AN APPIMAGE!
ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./$APP/$APP.AppDir > /dev/null 2>&1
cd ..;
mv ./tmp/*.AppImage ./steam.AppImage

echo "Steam has been packaged as steam.AppImage"
