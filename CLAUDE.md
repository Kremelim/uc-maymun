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

## Durum (2026-10-21)

- Faz 1: konsept + kağıt prototip (`docs/gdd/kurallar-v0.3.md`).
- Motor: ADR-0001 önerildi (Godot 4.7, teknik spike'a bağlı).
- M1 spike: Bölüm A (yerel ağ, gizli gelir, beyan) çalışıyor; Kerem 4 pencereyle Windows'ta doğruladı.
  Bölüm B: Steam lobisi iki ayrı evden 2 kişiyle doğrulandı (B1, B2). Steam daveti/overlay kendi App ID'mize kadar ertelendi.
  B3 (ses, `net/voice_chat.gd`): kod hazır, Windows'ta test bekliyor. Bkz. `docs/spike-m1.md`.
- Kural motoru (`core/match_state.gd`) ve simülatör (`sim/`) hazır. Oyun `data/rules_v0_3.tres` kullanır.
- M2 online gri kutu: kuralların tamamı online (`core/night.gd` gece akışı, `net/session.gd` host, `features/table/` arayüz).
  Boş koltuklara ve çıkanların yerine bot (`sim/seat_bot.gd`). Mimari: `docs/adr/0002-online-mac-mimarisi.md`, kullanım: `docs/m2-gri-kutu.md`.
  İlk denemede (Kerem, botlarla) oyun anlaşılmadı. Anlaşılırlık turu yapıldı: nasıl oynanır ekranı, eylem kartı, büyük duyurular,
  masada jeton ve beyan kartları, temel kurallarla ilk maç. Görünüş (karakter, ortam) M3'te. Ekip testi bekliyor.
- M3 planı (taslak, kararlar ekipte): `docs/m3-plan.md`. Önerilen yön: stilize karikatür, gazino arka odası, orta bütçe, karakter siparişi.
  Ücretli varlıklar repoya girerse repo özel kalmalı (lisanslar dağıtımı yasaklıyor).
- M3a teknik hazırlık bitti (ADR-0003 önerildi): tek `Monkey` sınıfı (`features/monkey/`), hangi koltukta hangi model
  `assets/monkeys/cast.tres`'te. Modelin kuralları `docs/sanatci-sartnamesi.md` (sanatçıya İngilizcesi `docs/artist-spec.en.md`).
  Gerçek modeller gelene kadar masada Blender betiğiyle üretilen ücretsiz test maymunu (`tools/blender/make_test_monkey.py`).
- Kurallar v0.3 (2026-10-21, Kerem Ataç kabul etti): v0.2 (denetçinin kartı açık, asgari katkı beyanın %60'ı ve beyanlar açılınca ödenir,
  son tur dükkanı kapalı, fazla beyan da yalan, en az 3 oyuncu) + ödenemeyen ceza senet olur + gece 4 maç, ilk denetçi her maç kayar.
  Açık sorular ve Kerem Gönç'ün kararını bekleyenler: `docs/sim/bulgular-v0.3.md`. Kağıt prototip henüz oynanmadı.
- Takvim: sabit tarih yok; kilometre taşlarıyla ilerleniyor (`docs/yol-haritasi.md`).

## Geliştirme ortamı

- Ekip Windows kullanıyor. Godot sürümü: **4.7.2-stable** (herkes aynı sürümü kullanır).
- Claude'un bulut oturumunda Godot 4.7.2 ekransız (`--headless`) çalışıyor. Testler ve simülasyonlar orada koşturulur.
- Steam'e bağlı her şey (lobi, ses, overlay) sadece ekibin Windows makinelerinde test edilebilir.
- GodotSteam 4.22.1 (GDExtension) `game/addons/godotsteam/` altında; DLL/SO dosyaları LFS'te.
  Steam'e `Engine.get_singleton("Steam")` ile erişilir (eklenti yüklenemezse oyun yerel ağa düşsün diye `Steam` global'i kullanılmaz).
- Godot projesi `game/` altında. Komutlar (repo kökünden):
  - Önbelleksiz ilk import'tan önce eklentiyi kaydet, yoksa import çıkışta çöker (SIGABRT):
    `mkdir -p game/.godot && echo "res://addons/godotsteam/godotsteam.gdextension" > game/.godot/extension_list.cfg`
  - İçe aktar (class cache için, testlerden önce şart): `godot --headless --path game --import`
  - Uyarı kontrolü (editörün gösterdiği GDScript uyarıları ekransız çalışmada görünmez; bu onları hata yapar):
    `godot --headless --path game --script res://tests/lint_warnings.gd`
  - Unit testler: `godot --headless --path game --script res://tests/run_unit_tests.gd`
    (autoload'lar yüklendikten sonra çalışır; test sırasında motor hatası olursa test başarısız sayılır)
  - E2E (host + 2 istemci + 1 bot gerçek ENet üzerinden bir gece oynar; sonuç simülatörle birebir aynı olmalı; `--fake-voice` ile ses dahil):
    `GODOT=godot game/tests/e2e/run_e2e.sh`. Gece ortasında çıkan oyuncu senaryosu: `LEAVER=1` ile.
    (loglarda motor hatası ya da sızıntı uyarısı varsa, testler geçse bile başarısız sayılır)
  - Simülatör (botlarla deneyler, Markdown rapor yazar; 2000 maçlık tam rapor ~2,5 dakika sürer, seed sabit olduğu için her seferinde aynı çıkar):
    `godot --headless --path game --script res://sim/simulate.gd -- --matches=2000 --out=$(pwd)/docs/sim/sonuclar-v0.3.md`
    Kural sürümü değişince: yeni `data/rules_vX.tres`, `simulate.gd`'de `RULES` ve deneyler, yeni `sonuclar-`/`bulgular-` dosyaları.
    Eski raporlar, onları üreten commit not edilerek kalır.
  - Görsel kontrol (botlar bir geceyi istenen aşamaya kadar oynar, masa Xvfb altında çizilip PNG kaydedilir): kullanımı
    `game/tests/visual/render_table.gd` başında. Arayüz değiştiğinde birkaç aşamayı (`STATE=`, tam kurallar için `MATCH=1`,
    kurallar ekranı için `HOWTO=1`) çizip görüntülere bak.
  - Maymun modeli kontrolü (şartnameye uyuyor mu; `--model=` olmadan cast'teki bütün modeller):
    `godot --headless --path game --script res://tools/check_monkey_model.gd -- --model=res://assets/monkeys/x.glb`.
    Tek maymunun yakın plan görüntüsü: `game/tests/visual/render_monkey.gd` (kullanımı başında).
  - Test maymununu yeniden üretmek (Blender 4.5 LTS, ekransız; bulut oturumunda kurulu değil, indirilir):
    `blender -b --factory-startup --python tools/blender/make_test_monkey.py -- --out game/assets/monkeys/test_monkey.glb`.
    Çıktı her seferinde bayt bayt aynı değil; sadece betik değişince üret.
- CI (`.github/workflows/ci.yml`) her PR'da import, uyarı kontrolü, unit, kısa bir simülatör çalıştırması ve E2E çalıştırır.
- Sahne düğümü uyarıları (ör. autowrap'li Label'a minimum genişlik) bu kontrole girmez; .tscn yazarken dikkat.

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
