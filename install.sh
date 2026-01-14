#!/bin/bash

#############################################
# MP3 Player Kurulum Scripti
# Pardus Linux için otomatik kurulum
#############################################

echo "╔═══════════════════════════════════════════╗"
echo "║   MP3 Player Kurulum Scripti              ║"
echo "║   Pardus Linux için                       ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# Root kontrolü
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Bu scripti root olarak çalıştırmayın!"
    echo "   Normal kullanıcı ile çalıştırın, sudo şifreniz istenecektir."
    exit 1
fi

# İşletim sistemi kontrolü
echo "📋 Sistem kontrolü yapılıyor..."
if [ -f /etc/pardus-release ]; then
    echo "✅ Pardus Linux tespit edildi!"
elif [ -f /etc/debian_version ]; then
    echo "⚠️  Debian tabanlı sistem tespit edildi."
    echo "   Pardus değil ama çalışması bekleniyor."
else
    echo "❌ Desteklenmeyen işletim sistemi!"
    echo "   Bu script Pardus/Debian tabanlı sistemler için tasarlanmıştır."
    exit 1
fi

echo ""
echo "📦 Bağımlılıklar kontrol ediliyor..."

# Bağımlılık kontrolü
MISSING_PACKAGES=""

if ! command -v yad &> /dev/null; then
    MISSING_PACKAGES="$MISSING_PACKAGES yad"
fi

if ! command -v mpg123 &> /dev/null; then
    MISSING_PACKAGES="$MISSING_PACKAGES mpg123"
fi

if ! command -v whiptail &> /dev/null; then
    MISSING_PACKAGES="$MISSING_PACKAGES whiptail"
fi

# Eksik paketler
if [ -n "$MISSING_PACKAGES" ]; then
    echo "📥 Eksik paketler yükleniyor:$MISSING_PACKAGES"
    echo ""
    
    sudo apt update
    
    if sudo apt install -y $MISSING_PACKAGES; then
        echo "✅ Bağımlılıklar başarıyla yüklendi!"
    else
        echo "❌ Paket yüklemesi başarısız!"
        echo "   Manuel olarak deneyin: sudo apt install$MISSING_PACKAGES"
        exit 1
    fi
else
    echo "✅ Tüm bağımlılıklar zaten yüklü!"
fi

echo ""
echo "🔧 Scriptler yapılandırılıyor..."

# Çalıştırma izinleri
if [ -f "gui.sh" ]; then
    chmod +x gui.sh
    echo "✅ gui.sh çalıştırılabilir yapıldı"
else
    echo "⚠️  gui.sh bulunamadı!"
fi

if [ -f "tui.sh" ]; then
    chmod +x tui.sh
    echo "✅ tui.sh çalıştırılabilir yapıldı"
else
    echo "⚠️ tui.sh bulunamadı!"
fi

echo ""
echo "🎵 Test yapılıyor..."

# mpg123 testi
if mpg123 --version &> /dev/null; then
    echo "✅ mpg123 çalışıyor ($(mpg123 --version 2>&1 | head -n1))"
else
    echo "❌ mpg123 testi başarısız!"
fi

# YAD testi
if yad --version &> /dev/null; then
    echo "✅ YAD çalışıyor ($(yad --version))"
else
    echo "❌ YAD testi başarısız!"
fi

# Whiptail testi
if whiptail --version &> /dev/null; then
    echo "✅ Whiptail çalışıyor"
else
    echo "❌ Whiptail testi başarısız!"
fi

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║   ✅ KURULUM TAMAMLANDI!                  ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
echo "📖 Kullanım:"
echo ""
echo "   GUI versiyonu için:"
echo "   ./gui.sh"
echo ""
echo "   TUI versiyonu için:"
echo "   ./tui.sh"
echo ""

# Kullanıcıya seçenek sun
read -p "Şimdi GUI versiyonunu başlatmak ister misiniz? (e/h): " choice
case "$choice" in
    e|E|evet|EVET)
        echo ""
        echo "🚀 GUI başlatılıyor..."
        sleep 1
        ./gui.sh
        ;;
    *)
        echo "👋 Kurulum tamamlandı. İyi günler!"
        ;;
esac

exit 0