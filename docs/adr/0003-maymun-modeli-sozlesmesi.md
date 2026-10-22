# ADR-0003: Maymun modeli sözleşmesi

- **Durum:** Önerildi (M3a). Model siparişinden önce Kerem Ataç ve Kerem Gönç'ün onayı.
- **Tarih:** 2026-10-21

## Bağlam

- **M3'te ne değişiyor:** M3'te gri kutu maymunların yerine gerçek modeller gelecek. Sipariş, hazır paket ya da ikisinin karışımı olabilir ([M3 planı](../m3-plan.md)).
- **Oyunun bir maymuna söyledikleri:**
  - adı ve kısa durumu;
  - denetçi olup olmadığı;
  - hangi aksesuarları taktığı;
  - konuşurken sesin ne kadar yüksek olduğu (ağız);
  - yakalanma, sevinç, hayal kırıklığı tepkileri.
- **Sorun:** Bunlar modele bağlı. Her yeni model için kod değişirse:
  - 4 maymunu denemek pahalı olur;
  - sanatçıya ne istediğimizi tam söyleyemeyiz.
- **Model teslim edilmeden yakalanacak hatalar:**
  - yanlış ölçek;
  - ters yön;
  - eksik ağız;
  - yanlış ad.
- **Sınamalar:** Claude testleri ekransız çalıştırıyor; modelin kuralı ekransız sınanabilmeli.

## Karar

1. **Tek bir `Monkey` sınıfı** (`features/monkey/monkey.gd`). Masa maymunla sadece bu sınıfın yöntemleriyle konuşur:
   - `set_player_name`, `set_status`;
   - `set_auditor`;
   - `set_accessories`;
   - `react`;
   - `setup_voice` / `push_voice`.

   Modeli `dress(model, tüy_rengi, toon)` giydirir. Gri kutu kapsül (`MonkeyPlaceholder`) kaldırıldı.
2. **Hangi koltukta hangi model:** bir kaynak dosyasında: `assets/monkeys/cast.tres` (`MonkeyCast`). Yeni maymunlar burada değişir; kod değişmez.
3. **Biçim:** glTF 2.0 binary (`.glb`), bir maymun bir dosya. Blender'da -Y'ye bakar, 1 birim = 1 m, başlangıç noktası ayakların arasında.
4. **İskelet:** Godot'nun insansı profilindeki kemik adları (`SkeletonProfileHumanoid`). Mixamo düzeni içe aktarırken BoneMap ile eşlenebilir.
   - Her model, adları doğru olsa da, BoneMap ve Fix Silhouette açık içe aktarılır (M3b'de eklendi).
   - İskelet `%GeneralSkeleton` olur ve animasyon izleri bütün modellerde aynı yolu kullanır. Böylece animasyonlar modeller arasında paylaşılabilir.
   - Quaternius'un hazır animasyonlarıyla sınandı: [M3b belgesi](../m3b-karakter.md#hazır-animasyon-denemesi).
5. **Ağız ve göz:** `jaw_open` ve `blink` blend shape'leri.
   - Oyun her karede ayarlar: ses seviyesinden ağız, rastgele göz kırpma.
   - Animasyonlar bunlara dokunmaz.
6. **Aksesuarlar modelin içinde:** `acc_<anahtar>` adlı nesneler (anahtarlar `RulesConfig.accessory_keys`'de) ve `auditor_hat`.
   - Sert olanlar kemiğe bağlı (Godot'da `BoneAttachment3D` olur); eldivenler iskelete bağlı (skinned).
   - Oyun sadece görünürlüğü açıp kapar.
7. **Animasyonlar adla:** `idle`, `talk` döngüde; `caught`, `cheer`, `slump` tek sefer. Hepsi oturarak, masa ve tabure ölçüleri şartnamede.
8. **Karikatür görünüm kodda:** Malzemelere toon ışık ve stencil kontur (Godot 4.5+) oyun tarafında eklenir. `fur` adlı malzeme koltuğa göre renklendirilebilir.
9. **Kontrol ekransız:**
   - `MonkeyModelCheck` modeli şartnameye göre denetler: kemikler, yön, boy, blend shape'ler, animasyonlar, aksesuar adları, üçgen sayısı.
   - Teslimde `tools/check_monkey_model.gd`, testlerde de oyundaki bütün modeller için çalışır.
10. **Ücretsiz test maymunu:** Blender betiğiyle üretilir (`tools/blender/make_test_monkey.py`).
    - Suzanne başı ve basit şekillerden oluşur; CC0.
    - Hem şartnamenin örneği, hem gerçek modeller gelene kadar oyundaki maymun.

Ayrıntılar: [sanatçı şartnamesi](../sanatci-sartnamesi.md).

## Değerlendirilen seçenekler

- **Ortak aksesuar sahneleri, kemiğe koddan takılır:**
  - **Artısı:** Bir taç modeli dört maymuna yeter.
  - **Neden seçilmedi:** Maymunların kafa ve vücutları farklı olacağı için her biri için konum ve ölçek ayarı gerekir. Sanatçının her maymuna oturttuğu aksesuar daha iyi görünür ve kodu basit tutar.
  - **Hazır paket gelirse:** Kerem editörde modelin miras sahnesine (inherited scene) `BoneAttachment3D` + `acc_...` düğümü ekleyebilir; kod aynı kalır.
- **Ağız için çene kemiği:**
  - **Neden seçilmedi:** Sadece çeneyi döndürür; dudak ve yanak şekli vermez.
  - **Ayrıca:** Kemik pozu animasyonla çakışır, ayrıca bir "skeleton modifier" gerekir.
  - **Hazır pakette blend shape yoksa:** Blender'da `jaw_open` eklemek kısa bir iş.
- **FBX:**
  - Godot'da destekleniyor, ama ölçek ve eksen sürprizleri daha çok.
  - glTF açık bir standart ve Blender doğrudan yazıyor.
- **OpenGameArt'taki CC0 maymun test modeli olarak:**
  - Adlar ve ağız şartnameye uymuyor; dönüştürmek gerekirdi.
  - Betikle üretilen model şartnameye birebir uyuyor ve istenince yeniden üretilebiliyor.

## Sonuçlar

- **Yeni maymun:** `.glb` + `cast.tres`'te bir satır. Kontrol aracı ilk bakışta eksikleri söyler.
- **Sanatçıya net bir liste veriliyor.** Liste eksikse teslimde ortaya çıkar, oyunda değil.
- **Aksesuar başına iş:** Her maymunun kendi 6 aksesuar nesnesi var (5 aksesuar + şapka). Sanatçıya biraz daha iş, ama çoğu kopyala-ölçekle.
- **Blender çıktısı tekrarlanabilir değil:** Blender'ın dışa aktarımı her çalıştırmada bayt bayt aynı dosyayı vermiyor (n-gon üçgenleme sırası, normaller). Test maymunu yeniden üretilince geometri aynı kalır ama dosya farklı çıkabilir. Bu yüzden sadece betik değişince yeniden üretilir.
- **Sızıntı tuzağı:** Malzemeler `Monkey` başına kopyalanıyor (tüy rengi, toon). Kopyalar `Monkey`'de tutuluyor. Yoksa aynı karede silinen bir maymunun meshi, silinmiş malzemesine uzanıyor ve motor hatası veriyordu (unit testte yakalandı).
