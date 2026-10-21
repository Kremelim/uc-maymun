# Üç Maymun (çalışma adı)

Dört maymun, tek masa, ortak bir borç: borcu birlikte ödeyin, cebe en çok parayı siz atın.
4 oyunculu online sosyal blöf oyunu, PC / Steam.

**Durum:** Konsept + kağıt prototip aşaması.

## Dokümanlar

- [Vizyon](docs/vision.md)
- [Yol haritası](docs/yol-haritasi.md)
- [Kurallar v0.3 (kağıt prototip)](docs/gdd/kurallar-v0.3.md)
- [Simülasyon bulguları](docs/sim/bulgular-v0.3.md)
- [ADR-0001: Oyun motoru](docs/adr/0001-oyun-motoru.md)
- [M1 teknik spike](docs/spike-m1.md)
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
3. Repoyu **OneDrive'ın senkronize etmediği** bir klasöre klonlayın (ör. `C:\Users\<ad>\game-project\`).
   OneDrive ile senkronize olan Belgeler veya Masaüstü klasörleri Git ve Godot'un `.godot/` önbelleğiyle çakışır.
   ```
   git clone https://github.com/Kremelim/uc-maymun
   ```
4. Godot'u açın, Project Manager'da **Import** → `uc-maymun/game/project.godot` → **Import & Edit**.

Teknik spike'ı 4 pencereyle denemek için: [docs/spike-m1.md](docs/spike-m1.md).
