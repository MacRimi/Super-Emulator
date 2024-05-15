https://github.com/raelgc/retropie_rpcs3-appImage

https://ericslenk.com/posts/running-steam-games-from-emulationstation

https://github.com/MizterB/RetroPie-Setup-Ubuntu

https://github.com/archtaurus/RetroPieBIOS

https://www.reddit.com/r/retroid/comments/1b7ugxj/upcoming_emulationstation_removes_yuzu_option/

```
wget https://raw.githubusercontent.com/MacRimi/SuperEmulator/main/scripts/yuzu.AppImage.sh -O ~/RetroPie-Setup/scriptmodules/emulators/yuzu.AppImage.sh
```

desactivar audio USB:
```
sudo nano /etc/modprobe.d/blacklist.conf
```
```
# Desactivar audio USB
blacklist snd_usb_audio
```

######### cemu ########
```
wget https://raw.githubusercontent.com/MacRimi/SuperEmulator/main/scripts/cemu.AppImage.sh -O ~/RetroPie-Setup/scriptmodules/emulators/cemu.AppImage.sh
```
