#!/bin/bash

APP_NAME="MP3 Player (YAD)"
BIN_NAME="mp3-player-gui"
INSTALL_PATH="/usr/local/bin/$BIN_NAME"
DESKTOP_FILE="$HOME/Desktop/mp3-player.desktop"
PLAYER_SCRIPT="./player.sh"

# ---- root kontrol ----
if [ "$EUID" -ne 0 ]; then
    yad --error --title="$APP_NAME" --text="Bu kurulum root yetkisi ister.\n\nLütfen:\nsudo ./install.sh"
    exit 1
fi

# ---- player script var mı ----
if [ ! -f "$PLAYER_SCRIPT" ]; then
    yad --error --title="$APP_NAME" --text="player.sh bulunamadı!\nInstaller ile aynı klasörde olmalı."
    exit 1
fi

# ---- progress gui ----
(
echo "10"; sleep 0.3
echo "# Gerekli paketler kontrol ediliyor..."

apt update -y >/dev/null 2>&1

echo "30"; sleep 0.3
echo "# mpv ve yad kuruluyor..."
apt install -y mpv yad >/dev/null 2>&1

echo "60"; sleep 0.3
echo "# Player sisteme kopyalanıyor..."
cp "$PLAYER_SCRIPT" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "80"; sleep 0.3
echo "# Masaüstü kısayolu oluşturuluyor..."

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=MP3 Player
Exec=$INSTALL_PATH
Icon=multimedia-player
Terminal=false
Categories=Audio;Music;
EOF

chmod +x "$DESKTOP_FILE"

echo "100"; sleep 0.3
echo "# Kurulum tamamlandı"
) | yad --progress \
    --title="$APP_NAME Kurulumu" \
    --width=420 \
    --auto-close \
    --auto-kill

yad --info \
    --title="$APP_NAME" \
    --text="✅ Kurulum başarılı!\n\n• Menüden veya masaüstünden çalıştırabilirsin.\n• Komut satırı: mp3-player-gui"
