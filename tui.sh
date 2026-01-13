#!/bin/bash

#############################################
# MP3 PLAYER - TUI (Whiptail) Versiyonu
# Pardus Linux için mpg123 ön yüzü
# Geliştirici: [İsminiz]
# Tarih: Ocak 2026
#############################################

# Gerekli komutların kontrolü
check_dependencies() {
    local missing=""
    
    if ! command -v whiptail &> /dev/null; then
        missing="${missing}whiptail "
    fi
    
    if ! command -v mpg123 &> /dev/null; then
        missing="${missing}mpg123 "
    fi
    
    if [ -n "$missing" ]; then
        echo "HATA: Eksik bağımlılıklar: $missing"
        echo "Kurulum için: sudo apt install $missing"
        exit 1
    fi
}

# Global değişkenler
CURRENT_PLAYLIST="/tmp/mp3player_tui_playlist_$$.txt"
CURRENT_DIR="$HOME"
MPG123_PID=""

# Temizlik işlemi
cleanup() {
    if [ -n "$MPG123_PID" ]; then
        kill $MPG123_PID 2>/dev/null
    fi
    rm -f "$CURRENT_PLAYLIST"
    clear
}

trap cleanup EXIT

# Dosya tarayıcısı fonksiyonu
file_browser() {
    local current_dir="${1:-$HOME}"
    local title="$2"
    
    while true; do
        # Dizindeki dosya ve klasörleri listele
        local items=()
        
        # Üst dizin seçeneği
        if [ "$current_dir" != "/" ]; then
            items+=(".." "Üst Dizin")
        fi
        
        # Klasörleri ekle
        while IFS= read -r dir; do
            [ -z "$dir" ] && continue
            items+=("$(basename "$dir")" "[KLS]")
        done < <(find "$current_dir" -maxdepth 1 -type d ! -path "$current_dir" 2>/dev/null | sort)
        
        # Müzik dosyalarını ekle
        while IFS= read -r file; do
            [ -z "$file" ] && continue
            items+=("$(basename "$file")" "[MP3]")
        done < <(find "$current_dir" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.wav" \) 2>/dev/null | sort)
        
        if [ ${#items[@]} -eq 0 ]; then
            whiptail --msgbox "Bu klasörde dosya bulunamadı!" 8 50
            return 1
        fi
        
        local selection
        selection=$(whiptail --title "$title" \
            --menu "Dizin: $current_dir\n\nSeçim yapın:" \
            20 70 12 \
            "${items[@]}" \
            3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return 1
        fi
        
        if [ "$selection" = ".." ]; then
            current_dir=$(dirname "$current_dir")
        elif [ -d "$current_dir/$selection" ]; then
            current_dir="$current_dir/$selection"
        else
            # Dosya seçildi
            echo "$current_dir/$selection"
            return 0
        fi
    done
}

# Çalma listesi oluşturma
create_playlist() {
    local choice
    choice=$(whiptail --title "Çalma Listesi Oluştur" \
        --menu "Yöntem seçin:" 15 60 3 \
        "1" "Klasör Seç (tüm müzikler)" \
        "2" "Tek Dosya Ekle" \
        "3" "İptal" \
        3>&1 1>&2 2>&3)
    
    case "$choice" in
        1)
            # Klasör seçimi
            local folder
            folder=$(file_browser "$HOME" "Müzik Klasörü Seçin")
            if [ -n "$folder" ] && [ -d "$folder" ]; then
                find "$folder" -type f \( -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.wav" \) > "$CURRENT_PLAYLIST" 2>/dev/null
                local count=$(wc -l < "$CURRENT_PLAYLIST")
                whiptail --msgbox "$count adet müzik dosyası eklendi!" 8 50
                return 0
            else
                whiptail --msgbox "Geçersiz klasör!" 8 40
                return 1
            fi
            ;;
        2)
            # Tek dosya ekleme
            > "$CURRENT_PLAYLIST"  # Listeyi temizle
            while true; do
                local file
                file=$(file_browser "$CURRENT_DIR" "Müzik Dosyası Seçin")
                if [ -n "$file" ] && [ -f "$file" ]; then
                    echo "$file" >> "$CURRENT_PLAYLIST"
                    CURRENT_DIR=$(dirname "$file")
                    
                    if ! whiptail --yesno "Dosya eklendi!\n\nBaşka dosya eklemek ister misiniz?" 10 50; then
                        break
                    fi
                else
                    break
                fi
            done
            
            local count=$(wc -l < "$CURRENT_PLAYLIST" 2>/dev/null || echo 0)
            if [ "$count" -gt 0 ]; then
                whiptail --msgbox "$count adet dosya eklendi!" 8 50
                return 0
            else
                whiptail --msgbox "Hiç dosya eklenmedi!" 8 40
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# Tek dosya çalma
play_single_file() {
    local file
    file=$(file_browser "$CURRENT_DIR" "Çalınacak Müzik Dosyasını Seçin")
    
    if [ -n "$file" ] && [ -f "$file" ]; then
        CURRENT_DIR=$(dirname "$file")
        whiptail --title "Şimdi Çalıyor" \
            --infobox "$(basename "$file")\n\nÇalıyor... (CTRL+C ile durdurun)" 8 60
        mpg123 -q "$file"
        sleep 1
    else
        whiptail --msgbox "Dosya seçilmedi!" 8 40
    fi
}

# Çalma listesini çalma
play_playlist() {
    if [ ! -f "$CURRENT_PLAYLIST" ] || [ ! -s "$CURRENT_PLAYLIST" ]; then
        whiptail --msgbox "Önce bir çalma listesi oluşturun!" 8 50
        return 1
    fi
    
    local total=$(wc -l < "$CURRENT_PLAYLIST")
    local current=0
    
    while IFS= read -r file; do
        ((current++))
        
        whiptail --title "Çalıyor ($current/$total)" \
            --infobox "$(basename "$file")\n\nDosya: $file\n\n(CTRL+C ile durdurun)" 10 70
        
        mpg123 -q "$file"
        
    done < "$CURRENT_PLAYLIST"
    
    whiptail --msgbox "Çalma listesi tamamlandı!" 8 40
}

# Çalma listesini göster
show_playlist() {
    if [ ! -f "$CURRENT_PLAYLIST" ] || [ ! -s "$CURRENT_PLAYLIST" ]; then
        whiptail --msgbox "Henüz bir çalma listesi yok!" 8 50
        return 1
    fi
    
    local content=""
    local index=1
    
    while IFS= read -r file; do
        content="${content}${index}. $(basename "$file")\n"
        ((index++))
    done < "$CURRENT_PLAYLIST"
    
    whiptail --title "Çalma Listesi ($(($index - 1)) dosya)" \
        --msgbox "$content" 20 70
}

# Hakkında
show_about() {
    whiptail --title "Hakkında" --msgbox \
        "MP3 Player TUI\n\nPardus Linux için mpg123 ön yüzü\n\nShell Script ile geliştirilmiştir.\nWhiptail kullanılarak oluşturulmuştur.\n\n© 2026" \
        15 50
}

# Ana menü
main_menu() {
    while true; do
        local choice
        choice=$(whiptail --title "MP3 Player - Ana Menü" \
            --menu "Bir işlem seçin:" 18 60 7 \
            "1" "Tek Dosya Çal" \
            "2" "Çalma Listesi Oluştur" \
            "3" "Çalma Listesini Çal" \
            "4" "Çalma Listesini Göster" \
            "5" "Hakkında" \
            "6" "Çıkış" \
            3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            break
        fi
        
        case "$choice" in
            1)
                play_single_file
                ;;
            2)
                create_playlist
                ;;
            3)
                play_playlist
                ;;
            4)
                show_playlist
                ;;
            5)
                show_about
                ;;
            6)
                break
                ;;
        esac
    done
}

# Program başlangıcı
check_dependencies
main_menu
cleanup

exit 0