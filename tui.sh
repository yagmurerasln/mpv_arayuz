#!/bin/bash
#############################################
# MP3 PLAYER - TUI (Whiptail)
# GUI (YAD) ile birebir mantık
#############################################

# ============== DEPENDENCY CHECK ==============
command -v whiptail >/dev/null || { echo "whiptail yok"; exit 1; }
command -v mpv >/dev/null || { echo "mpv yok"; exit 1; }

# ============== GLOBAL ========================
PLAYLIST="/tmp/mp3_tui_playlist_$$.txt"
PLAYER_PID=""
CURRENT_INDEX=1
PAUSED=0

DESKTOP="$HOME/Desktop"
[ ! -d "$DESKTOP" ] && DESKTOP="$HOME/Masaüstü"

cleanup() {
    kill "$PLAYER_PID" 2>/dev/null
    rm -f "$PLAYLIST"
    clear
}
trap cleanup EXIT

# ============== FILE PICKER ===================
pick_file() {
    local current_dir="$HOME"

    while true; do
        local menu=()

        # Üst dizin
        menu+=(".." "[Dizin Yukarı]")

        # Klasörler (SADECE basename)
        while IFS= read -r d; do
            base="$(basename "$d")"
            menu+=("$base/" "[Klasör]")
        done < <(
            find "$current_dir" -maxdepth 1 -type d ! -path "$current_dir" 2>/dev/null | sort
        )

        # Müzik dosyaları
        while IFS= read -r f; do
            base="$(basename "$f")"
            menu+=("$base" "[Müzik]")
        done < <(
            find "$current_dir" -maxdepth 1 -type f \
            \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.wav" \) \
            2>/dev/null | sort
        )

        choice=$(whiptail --title "Şarkı Seç" \
            --menu "Dizin: $current_dir" 20 80 15 \
            "${menu[@]}" \
            3>&1 1>&2 2>&3)

        ret=$?
        [ "$ret" -ne 0 ] && return 1

        # Yukarı çık
        if [ "$choice" = ".." ]; then
            current_dir="$(dirname "$current_dir")"
            continue
        fi

        # Klasör mü?
        if [[ "$choice" == */ ]]; then
            current_dir="$current_dir/${choice%/}"
            continue
        fi

        # Dosya seçildi
        if [ -f "$current_dir/$choice" ]; then
            echo "$current_dir/$choice"
            return 0
        fi
    done
}

pick_folder() {
    local current_dir="$HOME"

    while true; do
        local menu=()

        # ✅ Bu klasörü seç
        menu+=("__SELECT__" "✅ BU KLASÖRÜ SEÇ")

        # Yukarı çık
        menu+=(".." "[Dizin Yukarı]")

        # Alt klasörler
        while IFS= read -r d; do
            base="$(basename "$d")"
            menu+=("$base/" "[Klasör]")
        done < <(
            find "$current_dir" -maxdepth 1 -type d ! -path "$current_dir" 2>/dev/null | sort
        )

        choice=$(whiptail --title "Klasör Seç" \
            --menu "Dizin: $current_dir" 20 80 15 \
            "${menu[@]}" \
            3>&1 1>&2 2>&3)

        ret=$?
        [ "$ret" -ne 0 ] && return 1

        # ✅ Bu klasörü seç
        if [ "$choice" = "__SELECT__" ]; then
            echo "$current_dir"
            return 0
        fi

        # Yukarı
        if [ "$choice" = ".." ]; then
            current_dir="$(dirname "$current_dir")"
            continue
        fi

        # Alt klasöre gir
        if [[ "$choice" == */ ]]; then
            current_dir="$current_dir/${choice%/}"
            continue
        fi
    done
}



# ============== PLAYLIST ======================
create_playlist() {
    > "$PLAYLIST"

    choice=$(whiptail --menu "Playlist Oluştur" 15 60 2 \
        "1" "Tek tek şarkı seç" \
        "2" "Klasör seç " \
        3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && return

    case "$choice" in
        1)
            while true; do
                file=$(pick_file) || break
                echo "$file" >> "$PLAYLIST"
                whiptail --yesno "Başka şarkı ekle?" 8 40 || break
            done
            ;;
        2)
            folder=$(pick_folder) || return
            find "$folder" -type f \
                \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.wav" \) \
                >> "$PLAYLIST"
            ;;
    esac

    [ ! -s "$PLAYLIST" ] && whiptail --msgbox "Liste boş!" 8 30
}


# ============== PLAYER CORE ===================
play_song() {
    mpv --no-video --quiet "$1" &
    PLAYER_PID=$!
    PAUSED=0
}

pause_music() {
    kill -SIGSTOP "$PLAYER_PID" 2>/dev/null
    PAUSED=1
}

resume_music() {
    kill -SIGCONT "$PLAYER_PID" 2>/dev/null
    PAUSED=0
}

stop_music() {
    kill "$PLAYER_PID" 2>/dev/null
    wait "$PLAYER_PID" 2>/dev/null
    PLAYER_PID=""
}

# ============== PLAY PLAYLIST =================
play_playlist() {
    [ ! -s "$PLAYLIST" ] && {
        whiptail --msgbox "Önce playlist oluştur" 8 40
        return
    }

    mapfile -t SONGS < "$PLAYLIST"
    total=${#SONGS[@]}
    CURRENT_INDEX=1

    while true; do
        song="${SONGS[$((CURRENT_INDEX-1))]}"
        title="$(basename "$song")"

        mpv --no-video --quiet --really-quiet \
            --msg-level=all=no \
            "$song" >/dev/null 2>&1 &
        PLAYER_PID=$!
        PAUSED=0

        while true; do
            # 🎯 ŞARKI BİTTİ Mİ? → OTOMATİK GEÇ
            if ! kill -0 "$PLAYER_PID" 2>/dev/null; then
                PLAYER_PID=""
                break
            fi

            STATUS="▶️ ÇALIYOR"
            [ "$PAUSED" -eq 1 ] && STATUS="⏸ DURAKLATILDI"

            choice=$(whiptail --title "MP3 Player ($CURRENT_INDEX/$total)" \
  --menu "$STATUS\n\n$title" 15 60 4 \
  "1" "⏭ Sonraki" \
  "2" "⏸ Duraklat" \
  "3" "▶️ Devam" \
  "4" "❌ Çıkış" \
  3>&1 1>&2 2>&3)

ret=$?

# ⛔ İPTAL / ESC
if [ "$ret" -ne 0 ]; then
    kill "$PLAYER_PID" 2>/dev/null
    return
fi

case "$choice" in
    1)
        kill "$PLAYER_PID" 2>/dev/null
        PLAYER_PID=""
        break
        ;;
    2)
        kill -SIGSTOP "$PLAYER_PID" 2>/dev/null
        PAUSED=1
        ;;
    3)
        kill -SIGCONT "$PLAYER_PID" 2>/dev/null
        PAUSED=0
        ;;
    4)
        kill "$PLAYER_PID" 2>/dev/null
        return
        ;;
esac

        done

        # 🎯 OTOMATİK NEXT
        ((CURRENT_INDEX++))
        [ "$CURRENT_INDEX" -gt "$total" ] && CURRENT_INDEX=1
    done
}




# ============== SINGLE FILE ===================
play_single() {
    file=$(pick_file) || return
    mpv --no-video "$file"
}

# ============== MAIN MENU =====================
while true; do
    choice=$(whiptail --menu "🎵 MP3 Player (TUI)" 15 60 4 \
        "1" "Tek Dosya Çal" \
        "2" "Çalma Listesi Oluştur" \
        "3" "Çalma Listesini Çal" \
        "4" "Çıkış" \
        3>&1 1>&2 2>&3)

    case "$choice" in
        1) play_single ;;
        2) create_playlist ;;
        3) play_playlist ;;
        4) break ;;
    esac
done
