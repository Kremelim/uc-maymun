# Sanatçı şartnamesi: maymun modeli

> Durum: **Taslak, M3a** · Son güncelleme: 2026-10-21
> Sanatçıya giden İngilizce çevirisi: [artist-spec.en.md](artist-spec.en.md). Asıl belge bu; değişiklik önce burada yapılır.
> Karar: [ADR-0003](adr/0003-maymun-modeli-sozlesmesi.md). Plan: [M3 planı](m3-plan.md).

Bu belge iki şey için:
1. **Sanatçıya:** Modeli nasıl teslim edeceği. Bölüm 1–9.
2. **Ekibe:** Teslim alınan modelin oyuna nasıl girdiği. Bölüm 10.

**Neden bu kadar ayrıntı:** Oyun, modeldeki parçaları **adlarıyla** buluyor:
- konuşunca açılan ağız;
- denetçinin şapkası;
- satın alınan taç;
- "yakalandı" animasyonu.

Ad tutmazsa o parça oyunda çalışmaz. Adlar bu belgedeki gibiyse yeni bir maymun **kod değişmeden** oyuna girer.

**Örnek model:** `game/assets/monkeys/test_monkey.glb`. Bu şartnameye göre üretilmiş, ücretsiz bir test maymunu.
- Blender'da **File → Import → glTF 2.0** ile açılır; bütün adlar ve hiyerarşi görülür.
- Onu üreten betik: `tools/blender/make_test_monkey.py`.
- Sanatçıya modelle birlikte gönderilir.

## 1. Teslim edilecekler

| Dosya | Açıklama |
|---|---|
| `maymun_<ad>.glb` | Her maymun için bir dosya: glTF 2.0 binary. Dokular içine gömülü. Bütün aksesuarlar ve animasyonlar aynı dosyada. |
| `maymun_<ad>.blend` | Kaynak dosya (ya da kullanılan programın kaynağı). |
| Doku kaynakları | Katmanlı dosyalar (`.psd`, `.kra`, Substance projesi vb.). |
| Görseller | Önden, yandan, arkadan ve 3/4 görüntü (A-poz ve oturma pozunda). |

Dosya adında Türkçe karakter ve boşluk olmasın: `maymun_kemal.glb`.

## 2. Ölçek, eksen ve başlangıç noktası

- **1 birim = 1 metre.** Bütün dönüşümler uygulanmış olmalı: ölçek 1, dönme 0 (Blender: Ctrl+A → All Transforms).
- **Yön:** Blender'da Z yukarı. Maymun **-Y'ye bakar** (Front görünüşte yüzü görünür). Sol eli +X tarafındadır.
  - glTF dışa aktarımı bunu glTF'in "Y yukarı, +Z ileri" kuralına çevirir.
  - Oyun maymunu buna göre döndürür.
- **Başlangıç noktası (origin):** Yerde, iki ayağın ortasında. Oturma animasyonlarında bu nokta taburenin ortasının altındadır.
- **Boy (ayakta, A-pozda):** 0,9–1,7 m. Önerilen: 1,2–1,4 m.
  - Kafa büyük, karikatür oranlar.
  - Test maymunu 1,25 m.

## 3. Poz, poligon, malzeme

- **Dinlenme pozu (rest pose):** A-poz. Kollar 35–45° aşağıda, avuçlar aşağı, bacaklar hafif açık.
- **Üçgen sayısı** (bir maymun, bütün aksesuarlarıyla):
  - hedef **en çok 20.000**;
  - sınır **30.000**.

  Masada aynı anda 3 maymun görünüyor ve stil karikatür; ayrıntıyı biçim ve renk taşır.
- **Malzeme:** En çok 8 malzeme önerilir.
  - Metallic-roughness PBR ya da düz renkler.
  - Kürkün ana malzemesinin adı **`fur`** olmalı. Oyun bazen aynı modeli farklı kürk renkleriyle kullanır ve rengi bu malzemeye uygular.
- **Doku:** En çok 2048×2048, tercihen 1024–2048. Işık ve gölge dokuya **boyanmasın**.
  - Oyun karikatür ışıklandırma (toon) ve kontur çizgisi uyguluyor.
  - Dokuya işlenmiş gölge bunlarla çakışır.
- **Kemik etkisi:** Bir köşeye (vertex) en çok 4 kemik.

## 4. İskelet

İnsansı tek bir iskelet (armature). Kemik adları Godot'nun insansı profilindeki gibi (`SkeletonProfileHumanoid`).
Böylece hazır insansı animasyonlar (Mixamo, Quaternius) da aktarılabilir.

**Zorunlu kemikler:**

| Gövde | Sol | Sağ |
|---|---|---|
| `Hips`, `Spine`, `Chest`, `Neck`, `Head` | `LeftUpperArm`, `LeftLowerArm`, `LeftHand` | `RightUpperArm`, `RightLowerArm`, `RightHand` |
| | `LeftUpperLeg`, `LeftLowerLeg`, `LeftFoot` | `RightUpperLeg`, `RightLowerLeg`, `RightFoot` |

**Önerilen kemikler:**
- `UpperChest`;
- `LeftShoulder`, `RightShoulder`;
- `LeftToes`, `RightToes`;
- `Jaw`;
- `LeftEye`, `RightEye`;
- parmaklar (profildeki adlarla, ör. `LeftIndexProximal`).

**Notlar:**
- **Ek kemikler serbest:** kuyruk (`Tail1`, `Tail2`…), kulaklar, kürk. Oyun bilmediği kemiklere dokunmaz.
- **Kökte** `Root` kemiği olabilir (test maymununda var), şart değil.
- **Mixamo adları da kabul.** Örneğin `mixamorig:Hips`. Ekip içe aktarırken eşler (bkz. 10). Ama Godot adları tercih edilir.
- **Kemiklerde ölçek animasyonu olmasın.**

## 5. Yüz: ağız ve göz kırpma

Blender'da **shape key**, glTF'te **morph target**, Godot'da **blend shape**. Üçü aynı şey.

| Ad | 0 | 1 | Zorunlu mu |
|---|---|---|---|
| `jaw_open` | Ağız kapalı | Ağız tam açık (konuşurken en geniş hâli) | **Evet** |
| `blink` | Gözler açık | İki göz kapalı | Önerilir |

- Oyun bu değerleri her karede kendisi ayarlar:
  - **ağız:** oyuncunun mikrofon sesinin şiddetine göre;
  - **göz kırpma:** 2–5,5 saniyede bir, rastgele.
- Bu yüzden animasyonlar `jaw_open` ve `blink`'i **anahtarlamasın** (keyframe koymasın).
- İleride yüz ifadeleri için şu adlar ayrıldı (şimdilik isteğe bağlı): `smile`, `frown`, `surprised`.

## 6. Aksesuarlar ve denetçi şapkası

Oyunda dükkandan alınan beş aksesuar var ve **maymunun üstünde görünüyorlar**.
- **Kural:** Modeller dosyada görünür bırakılır; oyun gizler ve sahibine göre açar.
- **Okunaklılık:** Masada 3 metreden okunacak kadar büyük ve abartılı olsunlar.

| Nesne adı | Ne | Nasıl takılı |
|---|---|---|
| `acc_glasses` | Gözlük | `Head` kemiğine bağlı (Blender: Ctrl+P → Bone) |
| `acc_gloves` | İki eldiven, tek nesne | İskelete bağlı, ellerle bükülür (Armature modifier, `LeftHand`/`RightHand` ağırlıkları) |
| `acc_watch` | Kol saati | `LeftLowerArm`'a bağlı, sol bileğin üstünde |
| `acc_chain` | Altın zincir, sarkıtlı | `UpperChest`'e (yoksa `Chest`'e) bağlı |
| `acc_crown` | Taç | `Head` kemiğine bağlı |
| `auditor_hat` | **Denetçi şapkası:** yeşil muhasebeci siperliği (öneri; tasarım serbest, ama uzaktan "denetçi" diye tanınmalı) | `Head` kemiğine bağlı |

- **Adlar birebir böyle olmalı.** Küçük harf, İngilizce: `acc_` + anahtar.
  - Anahtarlar oyunun kural dosyasındaki `accessory_keys` ile aynı.
  - Yeni aksesuar eklenirse oraya da eklenir.
- **Birden çok parça:** Bir aksesuar birkaç parçaysa tek nesnede birleştirilsin. Gözlüğün çerçevesi ve sapları gibi.
- **Taç ve şapka çakışması:** Taç ve denetçi şapkası aynı anda takılabilir. Birbirinin içinden geçmesinler. Örneğin taç biraz yukarıda, siperlik alında olabilir.

## 7. Animasyonlar

**Genel kurallar:**
- 30 kare/saniye.
- Her animasyon Blender'da ayrı bir **Action**.
  - Dışa aktarımda ayrı animasyon olarak çıkar: Action'lar NLA'da ya da "Actions" modunda.
  - Adlar aşağıdaki gibi, küçük harf.
- **Hepsi oturarak.** Maymun bir taburede oturuyor, önkolları masanın kenarında. Ölçüler:
  - **Tabure:** oturma yüzeyi yerden **0,44 m**. Ortası başlangıç noktasının üstünde.
  - **Masa:** üst yüzeyi yerden **0,79 m**. Kenarı maymunun **0,38 m önünde** (Blender'da -Y). Masa yuvarlak, yarıçapı 1 m.
- **Başlangıç ve bitiş:** Tek seferlik animasyonlar temel oturma pozunda başlar ve biter. Oyun bunları beklemeye yumuşakça bağlar (0,25 sn karışım).
- **Kök hareketi yok:** Maymun yerinden kaymaz. Kalça zıplayıp geri dönebilir.
- **Tüm kemikleri anahtarlayın:** Her animasyonda bütün kemiklere anahtar koymak en güvenlisi. Anahtarlanmayan kemik, önceki animasyonda nerede kaldıysa orada kalabilir.

**Şimdi gerekenler:**

| Ad | Döngü | Süre | Ne zaman | Ne |
|---|---|---|---|---|
| `idle` | Evet | 3–5 sn | Her zaman | Nefes, hafif bakınma, kuyruk sallanır. |
| `talk` | Evet | 1–2 sn | Oyuncu konuşurken | Baş sallama, el hareketi. Ağız oynamaz (o `jaw_open`). Önerilir. |
| `caught` | Hayır | 1,5–2 sn | Denetimde yalanı yakalanınca | Panik: eller yanaklara, geri kaçma, baş sallama. |
| `cheer` | Hayır | 1–2 sn | Temiz çıkınca, masa kurtulunca | Sevinç: kollar havaya, zıplama. |
| `slump` | Hayır | 1,5–2 sn | Taksit eksik kalınca, masa batınca | Hayal kırıklığı: omuzlar düşer, baş eğilir. |

**Dikey dilim için sonra istenecekler** (adlar ayrıldı):
- `suspicious` — şüpheli bakış;
- `laugh` — gülme;
- `surprised` — şaşırma;
- `point` — birini gösterme;
- `push_coins` — jeton itme;
- `flip_card` — kart çevirme;
- `peek_card` — denetçinin karta bakması;
- üç maymun pozları: `see_no_evil`, `hear_no_evil`, `speak_no_evil`.

## 8. Dışa aktarma (Blender 4.x)

**File → Export → glTF 2.0 (.glb/.gltf)**:

| Bölüm | Ayar |
|---|---|
| Format | glTF Binary (.glb) |
| Include | Bütün nesneler (Selected Objects kapalı) |
| Transform | +Y Up açık |
| Data → Mesh | Apply Modifiers **kapalı**: açıkken shape key'ler kaybolur. UVs ve Normals açık. |
| Data → Shape Keys | Açık |
| Data → Armature | Deform bones only kapalı; ek kemikler (kuyruk) silinmesin. |
| Data → Skinning | Açık |
| Animation | Açık. Mode: **Actions**. Always Sample Animations açık. |

## 9. Haklar

- **Haklar:** Sipariş edilen işin bütün ticari hakları ekibe geçer (work for hire). Oyunda, mağaza sayfasında, fragmanda ve tanıtımda kullanılır.
- **Üçüncü taraf içerik:** Lisansı belirtilmedikçe kullanılmaz (doku, fırça, model parçası).
- **Yapay zekâ:** Kullanıldıysa söylenir. Steam, oyunda kalan yapay zekâ içeriğinin beyan edilmesini istiyor.
- **Jenerik:** Sanatçının adı oyunun jeneriğine yazılır (istemezse yazılmaz).

## 10. Ekip için: teslim alma ve oyuna koyma

Kerem Ataç'ın Windows'ta yapacağı adımlar.

**1. Dosyayı koy.** `maymun_kemal.glb`'yi `game/assets/monkeys/` altına kopyala.
- `.glb` dosyaları Git LFS'e kendiliğinden gider (`.gitattributes`).
- Ücretli bir paketten geliyorsa repo özel kalmalı (bkz. [M3 planı](m3-plan.md)).

**2. İçe aktar.** Godot editörünü aç. Dosya kendiliğinden içe aktarılır; sağ altta ilerleme çubuğu görünür.

**3. Kemik adları Mixamo ya da başka bir düzendeyse eşle:**
1. FileSystem'de `.glb`'ye çift tıkla. **Advanced Import Settings** açılır.
2. Soldaki ağaçta **Skeleton3D**'yi seç.
3. Sağda **Retarget → Bone Map** satırında **New BoneMap**'e, sonra oluşan BoneMap'e tıkla.
4. **Profile → New SkeletonProfileHumanoid**. Godot Mixamo adlarını kendisi eşler. Yeşil noktalar eşlenen kemikler.
5. **Rename Bones** açık kalsın.
6. **Reimport**.

**4. Kontrol aracını çalıştır.** Repo kökünde, bir terminalde:

```
<Godot klasörü>\Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tools/check_monkey_model.gd -- --model=res://assets/monkeys/maymun_kemal.glb
```

Çıktı ✓ (bulunanlar), ! (uyarı) ve ✗ (hata) satırları ve **SONUÇ** satırı.
- **Kabul şartı:** 0 hata.
- **Uyarılar** (ör. `blink` yok, üçgen sayısı hedefin üstünde) sanatçıyla konuşulur.
- **`--model` olmadan** oyundaki bütün maymunları denetler.

**5. Gözle bak:**
1. Editörde `features/monkey/monkey_preview.tscn`'i aç.
2. Kök düğüm **MonkeyPreview**'u seç; Inspector'da **Body**'ye `.glb`'yi sürükle.
3. **F6**.
4. Tuşlar ekranda yazıyor:
   - 1/2/3 tepkiler;
   - K konuşma;
   - A aksesuarlar;
   - D denetçi şapkası;
   - oklarla döndürme.

Ekransız bir yakın plan görüntüsü için: `tests/visual/render_monkey.gd` (kullanımı dosyanın başında).

**6. Oyuna koy.** `assets/monkeys/cast.tres`'e çift tıkla. Inspector'da:
- **Bodies:** Koltuk 0 listedeki ilk modeli, koltuk 1 ikinciyi alır; liste kısaysa başa döner.
  - Tek model varsa herkes o olur.
  - Dört farklı maymun gelince dört eleman ekle, her birine bir `.glb` sürükle.
- **Fur Tints:** Aynı modeli kullanan koltukları renkle ayırır; `fur` malzemesinin rengiyle çarpılır. Dört ayrı maymun varsa hepsini beyaz yap (1, 1, 1).
- **Toon:** Karikatür ışık ve kontur. Kapalıyken modelin kendi malzemeleri görünür.

**7. Oyna.** F5 → **Botlarla oyna**. Maymunlar masada.

## Neden böyle (kısaca)

- **glTF/GLB:** Godot'nun en iyi desteklediği biçim. Blender doğrudan yazıyor. FBX'e göre daha az sürpriz çıkarıyor.
- **Godot insansı kemik adları:** Hazır animasyonları aktarmak için. Mixamo düzeni de içe aktarırken eşlenebiliyor.
- **Ağız için blend shape:** Çene kemiği sadece çeneyi döndürür. Blend shape'le dudaklar ve yanaklar da şekil alır; karikatür stile uyar.
- **Aksesuarlar modelin içinde:** Her maymunun kafası ve vücudu farklı.
  - Ortak bir taç her kafaya oturmaz. Sanatçı her maymuna kendi aksesuarını oturtur (çoğu kopyala-ölçekle).
  - Oyun sadece görünürlüğünü açıp kapar.
- **Ayrıntılı gerekçe:** [ADR-0003](adr/0003-maymun-modeli-sozlesmesi.md).
