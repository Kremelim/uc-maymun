# M1 — Teknik spike

> Amaç: [ADR-0001](adr/0001-oyun-motoru.md)'deki 5 kriteri Godot 4.7.2 ile doğrulamak.
> Son güncelleme: 2026-10-20

## Durum

| # | Kriter | Durum |
|---|---|---|
| 1 | Steam lobisi, arkadaş daveti, 4 istemci | ✅ Steam üzerinden 2 kişi, iki ayrı evden (lobi koduyla). 4 kişi Steam'de henüz denenmedi. Steam daveti kendi App ID'mize kadar ertelendi |
| 2 | Steam Voice ile 4 kişi konumsal ses | Kod hazır, sahte mikrofonla otomatik test ediliyor. **Windows'ta test bekliyor (B3)** |
| 3 | Host otoriter senkron, herkese sadece kendi geliri | ✅ Çalışıyor ve otomatik testle kanıtlandı |
| 4 | 3D masa + 4 yer tutucu maymun, sese göre ağız | Ağız sesin şiddetine göre açılıyor, konuşanın adı sarıya dönüyor. **B3'te test edilecek** |
| 5 | Windows export + Steam overlay | ✅ Windows export. Overlay kendi App ID'mize kadar ertelendi (aşağıda) |

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
- kayıp jeton doğru mu;
- herkes diğer herkesin sesini duydu mu, kimse kendi sesini geri almadı mı.
  Testte mikrofon yerine `--fake-voice` ile bir test tonu kullanılıyor.

Ayrıca açılıştan önce kimsenin başkasının beyan miktarını görmediğini de kontrol eder.
Test, bilerek bozulmuş iki sürümde sızıntıyı yakalıyor: gelirlerin herkese gönderildiği bir sürüm ve beyanların erken açıldığı bir sürüm.

### Görsel kontrol

`tests/visual/render_table.gd`, masayı sahte verilerle bir koltuktan çizip PNG olarak kaydeder.
Arayüz değişikliklerini 4 pencere açmadan kontrol etmek için. Kullanımı dosyanın başında.

## Bölüm B — Steam

- [x] GodotSteam GDExtension **4.22.1** `game/addons/godotsteam/` altında (sadece Windows ve Linux dosyaları, LFS ile)
- [x] Test App ID 480 ile Steam'i başlatma; Steam yoksa yerel ağ moduna düşme
- [x] Steam lobisi kurma, lobi koduyla katılma, Steam davetini kabul etme (`SteamMultiplayerPeer`)
- [x] **B1:** tek başına Windows'ta test. Steam başlıyor, lobi kuruluyor, kod çıkıyor. Overlay editörden açılmadı (beklenen, aşağıda).
- [x] **B2:** bir arkadaşla, iki ayrı evden test. Lobi koduyla katılma, gizli gelir, beyan çalışıyor.
  Oyuncu ya da host oyun sırasında ayrılınca diğer taraf lobiye dönüyor. Steam daveti ve overlay açılmadı (beklenen, aşağıda).
- [ ] **B3:** Steam sesiyle konumsal sesli sohbet + ağız animasyonu. Kod hazır, test adımları aşağıda.

### Nasıl çalışıyor

- **Steam masası kur:** arkadaşlara açık (friends-only) bir Steam lobisi kurar, sonra host olarak dinlemeye başlar. Ekranda **lobi kodu** çıkar.
- **Kodla katıl:** lobi koduyla Steam lobisine girer ve lobinin sahibine bağlanır.
- **Arkadaş davet et:** Steam overlay'inin davet penceresini açar. Davet oyun açıkken kabul edilirse oyun kendiliğinden katılır.
- Steam açık değilse ya da eklenti yüklenemediyse oyun çökmez; lobide sebebi yazar ve sadece yerel ağ bölümü görünür.
- Bağlantıdan sonraki her şey (koltuklar, gizli gelir, beyan) yerel ağ moduyla birebir aynı kodla çalışır.

### Projeyi güncelledikten sonra

1. `git pull` yap. Eklentinin DLL dosyaları **Git LFS** ile geliyor. `git lfs install` bir kez yapılmış olmalı (README).
   Yapılmadıysa DLL'ler küçük işaretçi dosyaları olarak iner ve lobi "GodotSteam eklentisi yüklenemedi" der.
   Çözüm: repo klasöründe `git lfs install`, ardından `git lfs pull`, sonra Godot'u yeniden aç.
   Kontrol: `game\addons\godotsteam\win64\steam_api64.dll` yaklaşık 310 KB olmalı, 1 KB değil.
2. Godot projeyi açarken yeni eklentiyi fark edip editörü **yeniden başlatmanı** isteyebilir; kabul et.
   İstemezse ve hata görürsen **Project → Reload Current Project**.

### B1 — tek başına (5 dakika)

1. Steam'i aç ve giriş yap.
2. Godot'da projeyi **tek pencereyle** çalıştır: Debug → Customize Run Instances'ta Multiple Instances'ı kapat, F5.
3. Lobide **"Steam: <Steam adın> olarak bağlısın."** yazmalı ve ad kutusunda Steam adın olmalı.
4. **Steam masası kur**'a bas. Birkaç saniye içinde lobi kodu çıkmalı ve oyuncu listesinde sen olmalısın.
5. **Arkadaş davet et**'e bas. Steam overlay'i açılıyor mu, not et.
   Oyun editörden başlatıldığında overlay çoğu zaman çıkmaz; bu B2'deki dışa aktarılmış oyunda tekrar denenecek.
6. Steam arkadaş listende "Spacewar oynuyor" görünmen normal: geliştirmede Valve'ın test uygulamasını (480) kullanıyoruz.

Bana gönder: 3. ve 4. adımın ekran görüntüsü. Bir şey ters giderse Godot'un alttaki **Output** panelindeki satırlar.

### B2 — bir arkadaşla (iki ayrı bilgisayar, iki Steam hesabı)

Aynı bilgisayarda iki Steam hesabı birlikte çalışmaz. Arkadaşın Steam'de **arkadaş listende** olmalı, çünkü lobi sadece arkadaşlara açık.

1. **Windows çıktısı al** (arkadaşına Godot kurdurmamak için). Menü adları Türkçe arayüze göre, parantez içinde İngilizcesi:
   - **Dışa aktarma şablonlarını bir kez kur:**
     - **Düzenleyici → Dışa Aktarma Şablonlarını Yönet…** (Editor → Manage Export Templates…) → **İndir ve Yükle** (Download and Install).
     - "Beklenen yolda herhangi bir dışa aktarma şablonu bulunamadı" uyarısı bu yüzden çıkıyordu.
   - **Proje → Dışa Aktar…** (Project → Export…) → **Windows Desktop** ön ayarı → **Projeyi Dışa Aktar…** (Export Project…).
   - Açılan **Bir Dosya Kaydet** penceresi exe'nin nereye yazılacağını sorar. Exe ve `builds` klasörü bu adımda oluşur:
     1. **↑** (yukarı) okuyla iki kez çık: yol `/Users/kerem/game-project` olmalı. Böylece repo dışındasın; build dosyaları Git'e girmez.
     2. Sağ üstteki **+ işaretli klasör** simgesiyle `builds` klasörünü oluştur ve içine gir.
     3. **Dosya:** kutusuna `UcMaymun.exe` yaz → **Kaydet**.
        "Hata Ayıklama ile Dışa Aktar" (Export With Debug) kutusu varsa işaretli kalsın, hata olursa log için.
   - Godot bu yolu hatırlar (`../../builds/UcMaymun.exe`, `game/` klasörüne göre). Sonraki seferlerde sadece **Projeyi Dışa Aktar…** yeter.
   - `builds` klasöründe şunlar olmalı:
     - `UcMaymun.exe`, `UcMaymun.console.exe` (logları siyah pencerede gösterir), `UcMaymun.pck`
     - `libgodotsteam.windows.template_debug.x86_64.dll`, `steam_api64.dll`
   - Kontrol: Steam açıkken `UcMaymun.exe`'ye çift tıkla. Lobide "Steam: <adın> olarak bağlısın" yazmalı.
     Sonra klasörü zip'le, arkadaşına gönder.
   - Ön ayar `game/export_presets.cfg` dosyasına kaydedilir. GitHub Desktop'ta yeni dosya olarak görünür.
     Bunu commit et: herkes aynı ayarla dışa aktarsın. Şifre veya anahtar içermez; Godot onları `.godot/` altında tutar.
2. İkiniz de Steam'i açın. Sen dışa aktardığın `.exe`'yi ya da editörü çalıştır, arkadaşın kendi `.exe`'sini.
3. Sen: **Steam masası kur** → **Kodu kopyala** → kodu Discord'dan arkadaşına at.
4. Arkadaşın: kodu yapıştırıp **Kodla katıl**. İki ekranda da iki oyuncu görünmeli.
5. Sen: **Oyunu başlat**. Herkes sadece kendi gelirini görmeli; beyanlar herkes beyan edince açılmalı.
6. Davet yolunu da dene: masadan kalkın, yeniden **Steam masası kur** → **Arkadaş davet et**.
   Arkadaşın Steam'den daveti kabul edince (oyunu açıkken) masaya düşmeli.
   Overlay açılmazsa **Shift+Tab** dene. O da olmazsa Steam'in kendi arkadaş listesinden arkadaşına sağ tıkla → oyuna davet et.

### Steam overlay neden açılmıyor?

Steam overlay'i, Steam'in kendisinin başlattığı oyunlara enjekte edilir. Oyunu Godot editöründen ya da `.exe`'ye çift tıklayarak açınca Steam oyunu başlatmamış olur ve overlay çoğu zaman gelmez. Bu bizim kodumuzdaki bir hata değil.

Kendi App ID'mizi aldığımızda (Steam Direct, 100 $) oyun Steam kütüphanesinden açılacak ve overlay ile davetler normal çalışacak. O zamana kadar güvenilir yol **lobi kodu**.

Bana gönder: hangi adımlar çalıştı, hangileri çalışmadı, her iki taraftan ekran görüntüsü.

Farklı evlerden ENet ile bağlanmaya çalışmaya gerek yok; port yönlendirme gerektirir, Steam bunu bizim yerimize hallediyor.

### B3 — sesli sohbet

Nasıl çalışıyor:
- Masadayken mikrofonun Steam üzerinden kaydedilir ve Steam'in ses kodlayıcısıyla sıkıştırılır.
- Ses host'a gider, host diğerlerine iletir. Ses ayrı bir ağ kanalında gittiği için oyun mesajlarını beklemez.
- Her maymunun sesi kendi kafasından gelir: soldaki soldan, karşıdaki karşıdan duyulur.
- Konuşan maymunun ağzı sesin şiddetine göre açılır ve adı sarıya döner.
- Paneldeki **Mikrofon** düğmesi mikrofonu açıp kapatır, yanındaki çubuk ne kadar yüksek sesle konuştuğunu gösterir.
- **Gelen ses** satırı her oyuncudan gelen sesin şiddetini gösterir (`Gonc 0.12 · Ulas —`).
  "—" son bir saniyede o oyuncudan hiç ses gelmediği anlamına gelir.
  Ağız kıpırdamıyorsa önce buna bak: değer görünüyorsa ses geliyor, sorun ağızda; "—" ise ses hiç gelmiyor.

Önce mikrofonu kontrol et: **Steam → Ayarlar → Sesli** (Voice) bölümünden doğru mikrofonu seç ve oradaki test ile çalıştığını gör.
Oyun mikrofonu Steam üzerinden kullanıyor. Windows mikrofon izni de açık olmalı: Ayarlar → Gizlilik → Mikrofon.

**Tek başına — mikrofon (2 dakika):**
1. Oyunu dışa aktar (yeni sürüm), Steam açıkken çalıştır, **Steam masası kur** → **Oyunu başlat**.
2. Konuş: paneldeki çubuk hareket etmeli.
3. **Kendi sesimi duy (mikrofon testi)**'ni aç: kendi sesini hafif gecikmeli duymalısın.
   Hoparlör yerine kulaklık kullan, yoksa ses döngüye girip ötebilir. Testten sonra kapat.

Kendi maymununu görmediğin için (birinci şahıs) kendi konuşmanda ağız göremezsin.
4 pencereyle denemek de mikrofon için güvenilir değil: hepsi aynı Steam hesabı ve aynı mikrofon,
Steam sesi büyük ihtimalle pencerelerden sadece birine veriyor.

**Tek başına — ağız ve ses yönü (2 dakika):**
1. 4 pencereli çalıştırmadaki (Debug → Customize Run Instances) her satırın sonuna ` --fake-voice` ekle.
2. F5. Her pencere mikrofon yerine kesik kesik bir test tonu "konuşur".
3. Her pencerede diğer üç maymunun ağzı açılıp kapanmalı, adları sararmalı. **Gelen ses** satırında üç değer görünmeli.
4. Kulaklıkla dinle: tonlar soldan, karşıdan ve sağdan gelmeli.
5. Bitince ` --fake-voice`'u satırlardan sil, yoksa gerçek mikrofon kullanılmaz.

**Arkadaşınla:**
1. Yeni sürümü dışa aktarıp arkadaşına tekrar gönder. İkiniz aynı sürümü kullanmalısınız.
2. Lobi koduyla aynı masaya geçin ve oyunu başlatın.
3. Konuşun:
   - Birbirinizi duyuyor musunuz, gecikme ne kadar?
   - Ses doğru yönden geliyor mu? Arkadaşın sağındaysa sesi sağdan gelmeli.
   - Konuşanın ağzı açılıp adı sararıyor mu?
4. **Mikrofon**'u kapatınca karşı taraf seni duymamalı.

Bana gönder: duyup duymadığınız, gecikme ve ses kalitesi hakkında izleniminiz, ses yönü doğru mu, bir ekran görüntüsü.
Çıktıyı `UcMaymun.console.exe` ile açarsan siyah pencerede hata satırları görünür; bir şey ters giderse onları da gönder.

## Bilinen sınırlar (bilerek ertelendi)

- **2 kişide gizli bilgi kalmıyor.** Masaya dağıtılan toplam bilindiği için 2 kişide herkes diğerinin gelirini hesaplayabiliyor.
  Spike'ta test kolaylığı için 2 kişiyle başlanabiliyor; oyunun gerçek alt sınırı 3 olmalı (`docs/gdd/kurallar-v0.1.md`).
- Ses sadece Steam'le çalışıyor; yerel ağ modunda gerçek mikrofon yok (sadece `--fake-voice` test tonu). Bas-konuş (push-to-talk), fısıltı ve oyuncu başına sessize alma M2'de.
- Bir oyuncu oyun sırasında ayrılırsa maç biter ve herkes lobiye döner. Bot devralması ya da duraklatma M2'de.
- Arayüz metinleri kodda Türkçe yazılı. Çeviri sistemi (TR/EN) M2'de.
- Host her şeyi bilir; arkadaşlar arasında kabul edilebilir. Açık lobiler için yeniden değerlendirilecek.
- Kurallardan sadece gelir ve beyan var. Katkı, denetim, rüşvet ve kefil M2'de, kağıt prototipten sonra.
- **Fazla beyan serbest** (aldığından fazlasını beyan etmek). İlk 4 pencereli denemede hemen yaşandı.
  Kurallarda açık bir uç durum; Kerem Gönç karar verene kadar oyun buna izin veriyor ve "BEYAN FAZLASI" diye gösteriyor.
