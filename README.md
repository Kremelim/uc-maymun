# Üç Maymun (çalışma adı)

Dört maymun, tek masa, ortak bir borç: borcu birlikte ödeyin, cebe en çok parayı siz atın.
4 oyunculu online sosyal blöf oyunu, PC / Steam.

**Durum:** Konsept + kağıt prototip aşaması.

## Dokümanlar

- [Vizyon](docs/vision.md)
- [Yol haritası](docs/yol-haritasi.md)
- [Kurallar v0.1 (kağıt prototip)](docs/gdd/kurallar-v0.1.md)
- [ADR-0001: Oyun motoru](docs/adr/0001-oyun-motoru.md)
- [Playtest şablonu](docs/playtests/_sablon.md)
- [Ekip sözleşmesi kontrol listesi](docs/ekip-sozlesmesi.md)

## Ekip

- Kerem Ataç — geliştirme
- Kerem Gönç — oyun fikri, tasarım
- Abdulalim Çiftçi
- Ulaş Uzun

## Geliştirici kurulumu (Windows)

1. [Git for Windows](https://git-scm.com/download/win) kurun. Git LFS içinde gelir. Sonra her makinede bir kez:
   ```
   git lfs install
   ```
   Komut satırı yerine arayüz isterseniz [GitHub Desktop](https://desktop.github.com/) da kullanılabilir.
2. [Godot 4.7.2-stable](https://godotengine.org/download/archive/4.7.2-stable/) indirin. Standart sürümü seçin, .NET sürümünü değil. Kurulum yok; zip'i açıp çalıştırmak yeterli.
   Herkes aynı sürümü kullanmalı.
3. Repoyu klonlayın:
   ```
   git clone https://github.com/Kremelim/uc-maymun
   ```
