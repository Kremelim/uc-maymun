# M1 — Teknik spike

> Amaç: [ADR-0001](adr/0001-oyun-motoru.md)'deki 5 kriteri Godot 4.7.2 ile doğrulamak.
> Son güncelleme: 2026-10-20

## Durum

| # | Kriter | Durum |
|---|---|---|
| 1 | Steam lobisi, arkadaş daveti, 4 istemci | Yerel ağda (ENet) çalışıyor. **Steam: Bölüm B** |
| 2 | Steam Voice ile 4 kişi konumsal ses | **Bölüm B** |
| 3 | Host otoriter senkron, herkese sadece kendi geliri | ✅ Çalışıyor ve otomatik testle kanıtlandı |
| 4 | 3D masa + 4 yer tutucu maymun, sese göre ağız | Masa ve maymunlar var. Ağız animasyonu: **Bölüm B** |
| 5 | Windows export + Steam overlay | **Bölüm B** |

## Bölüm A — yerel ağ (tamam)

Ne var:
- **Lobi:** masa kur (host) veya masaya katıl, oyuncu listesi, "Oyunu başlat".
- **3D masa:** her oyuncu kendi koltuğundan bakıyor (birinci şahıs), diğerleri kutu-maymun.
- **Gizli gelir:** host her tur bir dağıtım seti çekip karıştırıyor ve her oyuncuya sadece kendi gelirini gönderiyor.
- **Beyan:** oyuncu beyanını gönderiyor, host doğruluyor. Kurallardaki kağıtlar gibi:
  - herkes beyanını verene kadar diğerleri sadece "beyanını verdi" bilgisini görüyor;
  - son beyan gelince hepsi aynı anda açılıyor ve kilitleniyor;
  - açılıştan sonra "KAYIP JETON" (ya da eksiye düşerse "BEYAN FAZLASI") görünüyor.

### Kod nerede

| Klasör | Ne | Kural |
|---|---|---|
| `game/core/` | Saf oyun mantığı (`TableState`, `RulesConfig`) | Node yok, ağ yok. Test edilebilir. |
| `game/data/` | Oyun sayıları (`rules_v0_1.tres`) | Kurallar dokümanıyla aynı. Sayılar burada değişir, kodda değil. |
| `game/net/` | `Network` (bağlantı, lobi), `Session` (maç), `PeerFactory` (ENet ↔ Steam) | Host otoriter. İstemci sadece "şunu yapmak istiyorum" der. |
| `game/features/` | Ekranlar: `lobby/`, `table/` | Sadece görüntü. Kural kodu yok. |
| `game/tests/` | Unit testler ve 4 süreçli E2E testi | Her PR'da GitHub Actions'ta otomatik çalışır. |

### Kendi bilgisayarında 4 pencereyle denemek

1. Godot 4.7.2'yi aç. Project Manager'da **Import**'a bas ve
   `C:\Users\kerem\game-project\uc-maymun\game\project.godot` dosyasını seç → **Import & Edit**.
2. Üst menüden **Debug → Customize Run Instances…** aç.
3. **Enable Multiple Instances**'ı işaretle, sayıyı **4** yap.
4. Her satırın **Launch Arguments** alanına sırayla yaz:
   - 1: `-- --auto-host --auto-start=4 --win=0 --name=Kerem`
   - 2: `-- --auto-join --win=1 --name=Gonc`
   - 3: `-- --auto-join --win=2 --name=Abdulalim`
   - 4: `-- --auto-join --win=3 --name=Ulas`
5. **OK**, sonra **F5** (Run Project). 4 pencere ekranı 2×2 bölerek açılır. Dördü bağlanınca oyun kendiliğinden başlar.
6. Her pencerede farklı bir gelir görmelisin. Bir sayı seçip **Beyan et**'e bas. Dördü de beyan edince
   "KAYIP JETON" görünür. Yeni tur için ilk penceredeki **Yeni tur dağıt (host)** düğmesini kullan.

İlk seferde Windows Güvenlik Duvarı izin isteyebilir; **Özel ağlar** için izin ver.

Elle denemek istersen argümanları boş bırak. Bir pencerede **Masa kur**, diğerlerinde **Masaya katıl** de; adres `127.0.0.1` kalsın.

### Testleri çalıştırmak

Testler her PR'da GitHub'da otomatik çalışır. Elle çalıştırmak için (Linux/Git Bash):

```
godot --headless --path game --import
godot --headless --path game --script res://tests/run_unit_tests.gd
GODOT=godot game/tests/e2e/run_e2e.sh
```

E2E testi gerçek bir ağ bağlantısıyla 1 host + 3 istemci başlatır. Her istemci yalan beyan verir ve
ne aldığını raporlar. Host kontrol eder:
- her istemci sadece kendi gelirini mi aldı;
- herkese açık durumda gelir sızıntısı var mı;
- beyanlar masaya ulaştı mı;
- kayıp jeton doğru mu.

Ayrıca açılıştan önce kimsenin başkasının beyan miktarını görmediğini de kontrol eder.
Test, bilerek bozulmuş iki sürümde sızıntıyı yakalıyor: gelirlerin herkese gönderildiği bir sürüm ve beyanların erken açıldığı bir sürüm.

### Görsel kontrol

`tests/visual/render_table.gd`, masayı sahte verilerle bir koltuktan çizip PNG olarak kaydeder.
Arayüz değişikliklerini 4 pencere açmadan kontrol etmek için. Kullanımı dosyanın başında.

## Bölüm B — Steam (sıradaki)

Bunu Kerem'in Windows bilgisayarında, en az 2 Steam hesabıyla birlikte yapacağız.

- [ ] GodotSteam'in Godot 4.7.2 ile uyumlu GDExtension sürümünü `game/addons/` altına kurmak
- [ ] Test AppID 480 ile Steam'i başlatmak (geliştirme sırasında kendi App ID'mize gerek yok)
- [ ] `PeerFactory`'ye `SteamMultiplayerPeer` eklemek; Steam lobisi kurmak, arkadaş davet etmek
- [ ] SteamVoice ile 4 kişi konumsal ses
- [ ] Ses şiddetine göre maymunun ağzının açılıp kapanması
- [ ] Windows export'u ve Steam overlay

Farklı evlerden internet üzerinden bağlanmayı ENet ile denemeye gerek yok. Port yönlendirme gerektirir,
Steam bunu bizim yerimize hallediyor.

## Bilinen sınırlar (bilerek ertelendi)

- Bir oyuncu oyun sırasında ayrılırsa maç biter ve herkes lobiye döner. Bot devralması ya da duraklatma M2'de.
- Arayüz metinleri kodda Türkçe yazılı. Çeviri sistemi (TR/EN) M2'de.
- Host her şeyi bilir; arkadaşlar arasında kabul edilebilir. Açık lobiler için yeniden değerlendirilecek.
- Kurallardan sadece gelir ve beyan var. Katkı, denetim, rüşvet ve kefil M2'de, kağıt prototipten sonra.
- **Fazla beyan serbest** (aldığından fazlasını beyan etmek). İlk 4 pencereli denemede hemen yaşandı.
  Kurallarda açık bir uç durum; Kerem Gönç karar verene kadar oyun buna izin veriyor ve "BEYAN FAZLASI" diye gösteriyor.
