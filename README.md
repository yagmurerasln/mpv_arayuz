# 🎵 MP3 Player – GUI & TUI (Shell Script)\n\n

## Proje Tanıtımı\n
Bu proje, **Linux Scriptleri ve Araçları** dersi kapsamında geliştirilmiş bir **MP3 Müzik Çalar** uygulamasıdır. \n 
Uygulama, komut satırı tabanlı bir müzik oynatıcı olan **mpv** için hem **Grafiksel Kullanıcı Arayüzü (GUI)** hem de **Terminal Tabanlı Kullanıcı Arayüzü (TUI)** sunmaktadır.\n

Projenin temel amacı, Linux ortamında kullanılan CLI tabanlı araçlara **kullanıcı dostu arayüzler** kazandırmak ve bu arayüzlerin **Pardus Linux** üzerinde sorunsuz çalışmasını sağlamaktır.
\n\n

## Projenin Amacı\n
- Shell Script (Bash) kullanarak gerçek bir Linux aracına arayüz geliştirmek\n  
- Aynı uygulamanın GUI (YAD) ve TUI (Whiptail) sürümlerini oluşturmak  \n
- Pardus Linux üzerinde çalışabilirlik sağlamak  \n
- Kullanıcı deneyimini (UX) artırmak  \n
- Playlist yönetimi ve müzik kontrolünü kolaylaştırmak  

\n\n

## Kullanılan Teknolojiler\n
| Programlama Dili | Bash (Shell Script) |\n
| GUI | YAD (Yet Another Dialog) |\n
| TUI | Whiptail |\n
| Müzik Oynatıcı | mpv |\n
| İşletim Sistemi | Pardus Linux (Debian tabanlı) |

\n\n

## Proje Dosya Yapısı\n
| gui.sh # Grafik arayüzlü MP3 Player (YAD) |\n
| tui.sh # Terminal arayüzlü MP3 Player (Whiptail) |\n
| install.sh # Otomatik kurulum ve bağımlılık scripti |\n
| README.md # Proje dokümantasyonu |\n\n

## Sistem Gereksinimleri\n
- Pardus Linux (önerilen)\n
- Debian tabanlı Linux dağıtımı\n
- Gerekli paketler:\n
  - `mpv`\n
  - `yad`\n
  - `whiptail\n\n`

> Tüm bağımlılıklar **install.sh** tarafından otomatik olarak yüklenmektedir.\n\n

## Kurulum\n
### Depoyu Klonla\n
```bash\n
git clone https://github.com/kullanici-adi/mp3-player.git\n
cd mp3-player\n

### Kurulum Scriptini Çalıştır\n
chmod +x install.sh\n
./install.sh\n\n

Kurulum scripti aşağıdaki işlemleri otomatik olarak gerçekleştirir:\n
İşletim sistemi kontrolü (Pardus / Debian)\n
Gerekli paketlerin yüklenmesi (mpv, yad, whiptail)\n
Script dosyalarına çalıştırma izni verilmesi\n
İsteğe bağlı olarak GUI sürümünün başlatılması\n
\n

##Kullanım\n
###GUI (Grafik Arayüz – YAD)\n
./gui.sh\n\n
####GUI Özellikleri\n
Tek dosya çalma\n
Playlist oluşturma\n
Tek tek şarkı seçme\n
Klasör bazlı playlist\n
Otomatik sonraki şarkıya geçiş\n
Duraklat / Devam\”
Şarkı adı ve playlist sıra bilgisinin gösterimi\n\n

###TUI (Terminal Arayüz – Whiptail)\n
./tui.sh\n\n
####TUI Özellikleri\n
Terminal içinden dosya ve klasör gezme\n
Playlist oluşturma\n
Otomatik şarkı geçişi\n
Duraklat / Devam\n
Menü tabanlı kontrol sistemi\n
TUI sürümü, whiptail kütüphanesinin sınırlamaları nedeniyle GUI sürümüne göre daha sade bir yapıya sahiptir.\n\n


##Ekran Görüntüleri\n\n

##Tanıtım Videosu\n


