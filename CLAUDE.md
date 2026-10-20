# CLAUDE.md — Üç Maymun

## Proje

Çalışma adı "Üç Maymun". 4 oyunculu online sosyal blöf oyunu, PC/Steam, 3D tek oda.

- Vizyon: `docs/vision.md`
- Kurallar: `docs/gdd/`
- Kararlar: `docs/adr/`

## Ekip

- **Kerem Ataç:** geliştirme (Claude ile birlikte), teknik kararlar.
  - Daha önce Unity ile 2D bir mobil oyun yaptı; editör, asset ve sahne kurulumunu biliyor. Kodlamada kendini başlangıç seviyesinde görüyor ama hızlı öğreniyor.
  - Bu yüzden kararların ve kodun "neden"ini kısaca açıkla, editörde yapılacak adımları tek tek yaz.
- **Kerem Gönç:** oyun fikrinin sahibi, tasarım. Kural değişikliklerinde onayı alınır.
- **Abdulalim Çiftçi:** fikir ve destek; somut sorumluluk alanı belirlenecek.
- **Ulaş Uzun:** fikir ve destek; somut sorumluluk alanı belirlenecek.

## Durum (2026-10-20)

- Faz 1: konsept + kağıt prototip (`docs/gdd/kurallar-v0.1.md`).
- Motor: ADR-0001 önerildi (Godot 4.7, teknik spike'a bağlı). Henüz oyun kodu yok.
- Takvim: sabit tarih yok; kilometre taşlarıyla ilerleniyor (`docs/yol-haritasi.md`).

## Geliştirme ortamı

- Ekip Windows kullanıyor. Godot sürümü: **4.7.2-stable** (herkes aynı sürümü kullanır).
- Claude'un bulut oturumunda Godot 4.7.2 ekransız (`--headless`) çalışıyor. Testler ve simülasyonlar orada koşturulur.
- Steam'e bağlı her şey (lobi, ses, overlay) sadece ekibin Windows makinelerinde test edilebilir.

## Çalışma kuralları

- Dokümanlar Türkçe. Kod, tanımlayıcılar ve commit mesajları İngilizce.
- Önemli teknik ve tasarım kararları `docs/adr/NNNN-baslik.md` olarak yazılır.
- Kural değişince `docs/gdd/` güncellenir. Oyun sayıları (gelir, borç, fiyatlar) kodda sabit değil, veri dosyalarında durur.
- Playtest notları `docs/playtests/YYYY-AA-GG-baslik.md` olarak, `_sablon.md` kullanılarak yazılır.
- `main` her zaman çalışır durumda olur. Değişiklikler kısa ömürlü dallar ve PR ile gelir.
- Gizli bilgi (Steam kimlik bilgileri vb.) asla repoya girmez; GitHub Secrets kullanılır.

## Mimari ilkeleri

- **Kural motoru:** saf, deterministik ve seed'li. Sunumdan (node'lar, animasyon, ses) ve ağdan ayrıdır. Ekransız test edilir, botlarla simüle edilir.
- **Ağ:** host otoriterdir; istemciler sadece niyet gönderir, host doğrular.
- **Gizli bilgi:** Her istemciye yalnızca görmeye hakkı olan durum gönderilir. Gelirler ve cepler hiçbir zaman başkasına gitmez.
- **Ağ taşıma katmanı soyutlanır:** geliştirmede ENet, yayında Steam.
