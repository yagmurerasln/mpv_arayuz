#!/bin/bash

#############################################
# MP3 PLAYER - GUI (YAD)
# Pause / Resume + Index-based playlist
#############################################

# ================= DEPENDENCY CHECK =================
check_dependencies() {
    command -v yad >/dev/null || exit 1
    command -v mpv >/dev/null || {
        yad --error --text="mpv bulunamadı"
        exit 1
    }
}

# ================= GLOBAL =================
PLAYER_PID=""
CURRENT_PLAYLIST="/tmp/mp3player_playlist_$$.txt"
CONTROL_FIFO="/tmp/mp3player_control_$$.fifo"

SUPPORTED_FORMATS="*.mp3 *.m4a *.flac *.aac *.ogg *.wav *.wma *.opus"

DESKTOP_DIR="$HOME/Desktop"
[ ! -d "$DESKTOP_DIR" ] && DESKTOP_DIR="$HOME/Masaüstü"

# ================= PLAYER CORE =================
pause_music() {
    if [ -n "$PLAYER_PID" ] && kill -0 "$PLAYER_PID" 2>/dev/null; then
        kill -SIGSTOP "$PLAYER_PID" 2>/dev/null
    fi
}

resume_music() {
    if [ -n "$PLAYER_PID" ] && kill -0 "$PLAYER_PID" 2>/dev/null; then
        kill -SIGCONT "$PLAYER_PID" 2>/dev/null
    fi
}

stop_music() {
    if [ -n "$PLAYER_PID" ] && kill -0 "$PLAYER_PID" 2>/dev/null; then
        kill "$PLAYER_PID" 2>/dev/null
        wait "$PLAYER_PID" 2>/dev/null
    fi
    PLAYER_PID=""
}

# ================= FILE PICKERS =================
select_single_file() {
    yad --file-selection \
        --filename="$DESKTOP_DIR/" \
        --file-filter="Music|$SUPPORTED_FORMATS"
}

select_folder() {
    yad --file-selection --directory \
        --filename="$DESKTOP_DIR/"
}

# ================= PLAYLIST BUILDERS =================
add_songs_manually() {
    > "$CURRENT_PLAYLIST"
    while true; do
        file=$(select_single_file)
        [ -z "$file" ] && break
        echo "$file" >> "$CURRENT_PLAYLIST"
        yad --question --text="Başka şarkı ekle?" || break
    done
}

create_playlist() {
    choice=$(yad --list --radiolist \
        --title="Çalma Listesi Oluştur" \
        --column="Seç" --column="Yöntem" \
        TRUE "Tek Tek Şarkı Seç" \
        FALSE "Sadece Klasör" \
        --width=400 --height=300)

    [ $? -ne 0 ] && return

    method=$(echo "$choice" | cut -d'|' -f2)

    case "$method" in
        "Tek Tek Şarkı Seç")
            add_songs_manually
            ;;
        "Sadece Klasör")
            folder=$(select_folder)
            [ -n "$folder" ] && \
                find "$folder" -type f \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.wma" -o -iname "*.opus" \) \
                > "$CURRENT_PLAYLIST"
            ;;
    esac

    [ ! -s "$CURRENT_PLAYLIST" ] && yad --error --text="Liste boş!"
}

# ================= PLAY PLAYLIST =================
play_playlist() {
    [ ! -s "$CURRENT_PLAYLIST" ] && yad --error --text="Önce liste oluştur" && return

    mapfile -t PLAYLIST < "$CURRENT_PLAYLIST"
    [ "${#PLAYLIST[@]}" -eq 0 ] && return

    # FIFO oluştur
    rm -f "$CONTROL_FIFO"
    mkfifo "$CONTROL_FIFO"

    total=${#PLAYLIST[@]}
    CURRENT_INDEX=1
    PAUSED=0

    # Arka planda şarkı takip edici
    (
        while true; do
            if [ -n "$PLAYER_PID" ] && ! kill -0 "$PLAYER_PID" 2>/dev/null && [ "$PAUSED" -eq 0 ]; then
                echo "NEXT" > "$CONTROL_FIFO"
            fi
            sleep 0.5
        done
    ) &
    WATCHER_PID=$!

    while true; do
        song="$(basename "${PLAYLIST[$((CURRENT_INDEX-1))]}" | sed 's/\.[^.]*$//')"




        # Yeni şarkı başlat
        if [ -z "$PLAYER_PID" ] || ! kill -0 "$PLAYER_PID" 2>/dev/null; then
            mpv --no-video --quiet --audio-device=pipewire --playlist="$CURRENT_PLAYLIST" --playlist-start=$((CURRENT_INDEX-1)) &


            PLAYER_PID=$!
            PAUSED=0
        fi

        # GUI durumunu güncelle
        if [ "$PAUSED" -eq 1 ]; then
            STATUS_TEXT="⏸ DURAKLATILDI"song
        else
            STATUS_TEXT="▶️ ÇALIYOR"
        fi

        # GUI'yi göster (arka planda)
        (
            yad --form \
  --title="🎵 MP3 Player" \
  --wrap \
  --text="$STATUS_TEXT\n\nŞarkı:\n$song\n\n($CURRENT_INDEX / $total)" \
  --button="⏭ Sonraki:0" \
  --button="⏸ Duraklat:1" \
  --button="▶️ Devam:2" \
  --button="❌ Çıkış:252" \
  --width=420 --height=180

            
            echo "BTN:$?" > "$CONTROL_FIFO"
        ) &
        YAD_PID=$!

        # FIFO'dan komut bekle
        read -r cmd < "$CONTROL_FIFO"
        
        # YAD'ı temizle
        kill "$YAD_PID" 2>/dev/null
        wait "$YAD_PID" 2>/dev/null

        # Komutu işle
        case "$cmd" in
            "NEXT")
                # Otomatik geçiş
                PLAYER_PID=""
                ((CURRENT_INDEX++))
                [ "$CURRENT_INDEX" -gt "$total" ] && CURRENT_INDEX=1
                ;;
            "BTN:0")
                # Sonraki butonu
                stop_music
                PAUSED=0
                ((CURRENT_INDEX++))
                [ "$CURRENT_INDEX" -gt "$total" ] && CURRENT_INDEX=1
                ;;
            "BTN:1")
                # Duraklat
                pause_music
                PAUSED=1
                ;;
            "BTN:2")
                # Devam
                resume_music
                PAUSED=0
                ;;
            "BTN:252")
                # Çıkış
                stop_music
                kill "$WATCHER_PID" 2>/dev/null
                rm -f "$CONTROL_FIFO"
                return
                ;;
        esac
    done
}

# ================= SINGLE FILE =================
play_single_file() {
    file=$(select_single_file)
    [ -z "$file" ] && return
    mpv --no-video --quiet "$file"
}

# ================= MAIN MENU =================
main_menu() {
    while true; do
        choice=$(yad --list --radiolist \
            --title="🎵 MP3 Player" \
            --column="Seç" --column="İşlem" \
            TRUE "Tek Dosya Çal" \
            FALSE "Çalma Listesi Oluştur" \
            FALSE "Çalma Listesini Çal" \
            FALSE "Çıkış" \
            --width=350 --height=300)

        [ $? -ne 0 ] && break
        action=$(echo "$choice" | cut -d'|' -f2)

        case "$action" in
            "Tek Dosya Çal") play_single_file ;;
            "Çalma Listesi Oluştur") create_playlist ;;
            "Çalma Listesini Çal") play_playlist ;;
            "Çıkış") break ;;
        esac
    done
}

# ================= START =================
check_dependencies
main_menu
rm -f "$CURRENT_PLAYLIST" "$CONTROL_FIFO"
exit 0