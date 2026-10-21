# M3 — Sanat yönü ve dikey dilim: plan

> Durum: **Taslak plan** · Son güncelleme: 2026-10-21 · Karar gerekenler **[KARAR]** ile işaretli.
> Fiyat ve lisans bilgileri 2026-10-21'de kaynaklarından kontrol edildi; doğrulanamayanlar işaretli.
> Yol haritasındaki tanım: "Maymun modeli (sipariş veya kendimiz), oda, Hesap Günü ekranı hazır. Steam sayfası açıldı, kapsül görseli sipariş edildi."

## Amaç: dikey dilim

Dikey dilim (vertical slice) şu demek: oyunun küçük bir parçası, çıkacağı kalitede. Bizim için:

- bir oda;
- dört maymun;
- bir maç (beyan → denetim → Hesap Günü), ses ve ışıkla birlikte.

Bunu görüp "Steam'de görsem tıklarım" diyebilmeliyiz. Steam sayfasının görselleri ve fragmanı da bu dilimden çıkacak.

## Sıra: önce ekip testi, sonra para

Kuralların insanlarla eğlenceli olduğu henüz kanıtlanmadı: kağıt prototip oynanmadı, M2 ekip testi bekliyor. Bu yüzden M3 ikiye bölünüyor:

- **M3a (şimdi, para yok):**
  - görsel yön kararı ve referans panosu;
  - sanatçıya verilecek teknik şartname;
  - oyunda karakterin "takılacağı" yerin hazırlanması.
- **M3b ve sonrası (para harcanan kısım):** M2 ekip testinden ve "devam" kararından sonra.

Bir hafta gecikmek, beğenmeyeceğimiz bir oyuna para harcamaktan ucuz.

**İstisna: Steam ücreti (100 $) erken ödenebilir.**
- Oyun ilk $1.000 geliri yapınca geri dönüyor.
- Kendi App ID'mizi veriyor; M1'den beri bekleyen Steam daveti ve overlay testi onunla çözülüyor (bkz. 5).
- Sayfayı halka açmak ise görseller hazır olunca.

## 1. Görsel yön [KARAR]

### Stil

| Seçenek | Artısı | Eksisi |
|---|---|---|
| **A. Stilize karikatür** (kalın silüet, abartılı yüz ifadeleri, sıcak renkler) | Liar's Bar'dan net ayrışır. Mizaha ve "üç maymun" hicvine uyar. Yayın kliplerinde okunaklı. Küçük ekip için yönetilebilir. | Özgün karakter siparişi gerektirir. Hazır paketle bu stili tutturmak zor. |
| **B. Düşük poligon** (Synty tarzı, düz renkler) | Hazır paketlerle en hızlı ve en ucuz yol. | "Hazır paketle yapılmış" (asset flip) görünme riski. Karakter kişiliği zayıf. |
| **C. Yarı gerçekçi, karanlık** (Liar's Bar tarzı) | Atmosferik. | Pahalı. "Liar's Bar klonu" algısını güçlendirir; vizyon belgesindeki 1 numaralı pazarlama riski bu. |

**Önerimiz: A.** Vizyondaki en büyük risk, oyunun "Liar's Bar klonu" sanılması. Kapsül görseli ve ilk 3 saniye farkı göstermeli; bunu en iyi stil yapar.

### Ortam

| Seçenek | His |
|---|---|
| **1. Gazino arka odası** | 70'ler İstanbul'u: yeşil çuhalı masa, tavanda tek lamba, duman, pavyon ışıkları, eski radyo. |
| **2. Orman barı** | Bambu, sarmaşık, tiki. |
| **3. Şirket toplantı odası** | Takım elbiseli maymunlar, hiciv. |

**Önerimiz: 1.** Özgün ve yerel; yabancı oyuncuya da çekici geliyor. "Görmedim, duymadım, bilmiyorum" ve yolsuzluk temasıyla örtüşüyor.

### Karakterler

- Dört maymun, masada uzaktan bile ayırt edilebilmeli. Her biri farklı tür ya da farklı kürk, kıyafet ve renk.
- Aksesuarlar oyunda zaten var (gözlük, eldiven, saat, altın zincir, taç) ve modelin üstünde görünecekler. Oyunun "zenginliğini göstermenin riski" mekaniği tam olarak bu.
- Üç maymun teması (gözünü, kulağını, ağzını kapatan) Hesap Günü ve denetim anlarında kullanılabilir. Örneğin örtbas eden denetçi gözlerini kapatır.

## 2. İhtiyaç listesi (dikey dilim)

| Kalem | Ayrıntı |
|---|---|
| **Maymun** | 1 temel model + 4 varyant. İnsansı iskelet (animasyon paylaşmak için), konuşunca açılan ağız (çene kemiği ya da blend shape), göz kırpma. Aksesuar takma noktaları: göz, boyun, bilek, eller, kafa. |
| **Animasyon** (oturarak, ~12) | bekleme, konuşma, şüpheli bakış, gülme, şaşırma, işaret etme, jeton itme, kart çevirme, denetçinin karta bakması, yakalanma, sevinç, üzüntü |
| **Oda** | Yeşil çuhalı masa, sandalyeler, lamba, bar tezgâhı, duvar süsleri, duman. |
| **Masa üstü** | Jeton, beyan kartı, kasa (kâse), aksesuar modelleri. |
| **Arayüz** | Tema (font, renk, paneller). Hesap Günü sahnesi: kartlar tek tek açılır, yalanlar vurgulanır. |
| **Ses** | Oda ambiyansı, jeton, kart, duyuru vurguları, müzik (gazino ya da caz). |
| **Steam** | Kapsül görselleri, ekran görüntüleri, sonra kısa bir fragman. |

## 3. Kaynak seçenekleri ve maliyet

Fiyatlar ve lisanslar 2026-10-21'de kontrol edildi. Fiyatlar dolar cinsinden; "tahmin" yazanlar piyasa aralıklarından çıkarıldı.

### Hazır paketler

| Kaynak | Maymun var mı | Fiyat | Lisans (Godot'da kullanılır mı) |
|---|---|---|---|
| **Synty** (POLYGON) | Yok. Tek primat, Kaiju paketindeki canavar goril. | Paketler ~$50–70; animasyon paketleri $49,99 (bekleme), $59,99 (tepkiler) | Evet: "oyun motoruyla sınırlı değil". 5 kişilik ekip lisansı. Varlıkları yapay zekâ üretecine vermek yasak. [lisans](https://syntystore.com/pages/end-user-licence-agreement) |
| **Quaternius** | Yok | Animasyon kütüphanesi: 45 klip ücretsiz, Pro $9,99+ (120+ insansı klip, oturma dahil, Godot için dışa aktarılmış) | Ticari kullanım serbest, kaynak göstermek gerekmiyor. Lisansı 2026'da "Quaternius Asset License"a geçti; indirdiğin günkü sürüm geçerli. [site](https://quaternius.com/license.html) |
| **Kenney** | Doğrulanamadı | Ücretsiz | CC0, her şey serbest. [destek](https://kenney.nl/support) |
| **OpenGameArt** | Var: 2016'dan, iskeletli, sade bir maymun | Ücretsiz | CC0. Teknik deneme için ideal. [model](https://opengameart.org/content/monkey-3d-model-rigged-fbx) |
| **Fab** (Epic; Sketchfab mağazası da buraya taşındı) | Var: birkaç karikatür, iskeletli maymun | Fiyatlar doğrulanamadı | Evet: standart lisans başka motorlarda kullanıma izin veriyor; varlığı tek başına yeniden satmak yasak. [Fab lisansları](https://dev.epicgames.com/documentation/fab/licenses-and-pricing-in-fab) |
| **Unity Asset Store** | Bakılmadı | Değişken | Evet: Unity'nin kendi sayfası "başka motorlarla kullanılabilir" diyor (lisansı farklı işaretli varlıklar hariç). [Unity yardım](https://support.unity.com/hc/en-us/articles/34387186019988-Can-I-use-assets-from-the-Asset-Store-with-other-engines) |

**Sonuç:** İstediğimiz stilde, hazır, kaliteli bir maymun karakteri yok. Hazır paketler oda, masa üstü nesneleri ve animasyon için işe yarıyor.

**Repo notu:** Ücretli paketler repoya girecekse repo özel (private) kalmalı; Synty ve Fab lisansları başkalarına dağıtmayı yasaklıyor. Büyük dosyalar Git LFS kotasını da dolduracak; GitHub kotasını M3b'den önce kontrol edelim.

### Sipariş (serbest sanatçı)

Güvenilir bir piyasa araştırması yok; aşağıdakiler fiyat listelerinden ve ilanlardan çıkan aralıklar.

| Kalem | Aralık | Not |
|---|---|---|
| **Bir karakter** (model + doku + iskelet + çene/ağız) | **$800–3.000** (gerçekçi aralık) | Fiverr'da $30–400 ilanlar var, ama çoğu sadece model. Bir fiyat listesi stilize, dokulu tam vücut için $1.200 + iskelet $480–720 diyor. Stüdyolar ~$2.000'dan başlıyor. [fiyat listesi](https://freelancenation.com/blog/3d-model-commission-prices) |
| **Dört maymun** | Tahmin: dört ayrı siparişten belirgin şekilde ucuz | Tek temel model ve iskelet üzerine 4 varyant (kürk, kıyafet, renk). |
| **Animasyon** (10–12 oturarak klip) | Tahmin: **$500–4.000** | Fiverr'da klip başı $40'tan başlıyor; orta seviye animatör saati $50–100. |
| **Steam kapsül görselleri** (ana, başlık, küçük, dikey) | **$250–1.000** | Uzman bir sanatçı küçük oyunlar için $500–700 alıyor. Sanatçının yapay zekâ çıktısı üstüne boyayıp boyamadığını sorun. [How To Market A Game](https://howtomarketagame.com/2022/03/08/what-should-you-spend-money-on-if-you-have-a-small-marketing-budget/) |

### Yapay zekâ ile 3D üretimi

| Araç | Fiyat | Not |
|---|---|---|
| Meshy | $20–100/ay | Ücretli planda çıktı senin. Otomatik iskelet sadece insansı ve dört ayaklılar için; yüz ve kuyruk elle. [fiyatlar](https://www.meshy.ai/pricing) |
| Tripo | $15,90–111,90/ay | Fiyatlar doğrulanamadı (resmî sayfa açılmadı). |
| Rodin (Hyper3D) | $30/ay ve üstü | "Sınırsız dışa aktarma ve her türlü kullanım". [fiyatlar](https://hyper3d.ai/pricing) |

**Değerlendirme:**
- Karakter için uygun değil. Eklem bölgeleri dağınık çıkıyor, otomatik iskelet bozuluyor ve hiçbiri kullanılabilir bir ağız/çene vermiyor.
- Oyunda kalan yapay zekâ içeriği Steam'de beyan edilmek zorunda (bkz. 5).
- En fazla prototip ya da küçük masa nesneleri için düşünülebilir.

### Animasyon

- **Mixamo:**
  - Hâlâ ücretsiz; ticari kullanım serbest, Godot'da kullanılabilir. [Adobe SSS](https://community.adobe.com/t5/mixamo-discussions/mixamo-faq-licensing-royalties-ownership-eula-and-tos/m-p/13234775)
  - Otomatik iskelet sadece iki ayaklı insansılar için. Adobe hâlâ "teknoloji önizlemesi" diyor, şartlar değişebilir.
- **Godot'da animasyon aktarma:** Godot 4, insansı bir iskeletin animasyonlarını başka bir insansı iskelete aktarabiliyor (BoneMap + SkeletonProfileHumanoid). [Godot belgesi](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html)
  - İnsansı iskeletli bir maymun Mixamo ve Quaternius animasyonlarını kullanabilir.
  - Ama uzun kollar yüzünden eller hedefi (jeton, kart) ıskalar; her karakterde ayar gerekir.
  - Kuyruğun kendi animasyonu ya da fiziği gerekir.

### Önerimiz: karma

- **Karakter: sipariş.** Özgün maymunlar pazarlamanın ta kendisi; hazırda da yok.
  - Tek temel model, 4 varyant.
  - İnsansı iskelet, ağız için blend shape, aksesuar için sabit kemik isimleri.
- **Animasyon:** Önce Mixamo ve Quaternius. Eksik kalan birkaç özel an (karta bakma, yakalanma, sevinç) siparişle.
- **Oda ve masa üstü:** Hazır paket (lisansı uygun), rengi ve ışığıyla bize uyarlanmış.
- **Kapsül:** Uzman bir kapsül sanatçısı. Steam sayfasının ilk izlenimi bu.

## 4. Bütçe senaryoları [KARAR]

Kabaca; kesin fiyat sanatçı tekliflerinden sonra belli olur.

| Senaryo | Ne alınır | Toplam (tahmin) | Risk |
|---|---|---|---|
| **Düşük** | Steam ücreti; ücretsiz ya da ucuz hazır maymun (Fab/CC0); Mixamo ve Quaternius animasyonları; hazır oda; kapsülü kendimiz yaparız | **$100–400** | Sıradan görünür. Liar's Bar'dan ayrışmak zor. |
| **Orta** (önerimiz) | Steam ücreti; sipariş temel maymun + 4 varyant; hazır ve birkaç özel animasyon; hazır oda; uzman kapsül | **$2.000–5.000** | Sanatçı seçimi kritik; teslim süresi uzayabilir. |
| **Yüksek** | 4 ayrı özgün karakter, tam özel animasyon seti, özel oda, profesyonel kapsül ve fragman | **$8.000–15.000** | Kurallar insanlarla kanıtlanmadan bu kadar harcamak riskli. |

- **Steam ücreti geri döner:** Oyun $1.000 brüt gelire ulaşınca 100 dolar geri ödeniyor.
- **Önerimiz: orta senaryo, parça parça.**
  1. Önce tek maymunu sipariş edip oyunda deneyin.
  2. Beğenilirse varyantlara ve animasyonlara geçin.

## 5. Steam sayfası

- **Ücret:** Uygulama başına 100 $, iade edilmez. Oyun $1.000 brüt gelire ulaşınca geri ödenir. [Steam](https://partner.steamgames.com/doc/gettingstarted/appfee)
- **Kendi App ID'miz:** Ücreti ödeyince kendi App ID'miz olur. Şu an test App ID'si 480 ile çalışıyoruz. M1'de ertelediğimiz **Steam daveti ve overlay** ancak kendi App ID'mizle doğru test edilebilir. Yani sayfayı erken açmak teknik bir işi de çözüyor.
- **Süreler (ilk oyun için):** [Coming Soon](https://partner.steamgames.com/doc/store/coming_soon) · [yayın](https://partner.steamgames.com/doc/store/releasing)
  - Ücreti ödedikten sonra çıkışa en az **30 gün** var.
  - "Yakında" sayfası çıkıştan en az **2 hafta** önce açık olmalı.
  - Sayfa yayına girmeden en az 7 iş günü önce gönderilmeli; inceleme genelde 3–5 gün sürüyor.
  - Erken açmanın üst sınırı yok. Valve, "insanlarla konuşmaya hazır olduğunuz anda açın" diyor. İstek listesi (wishlist) toplamak için ne kadar erken o kadar iyi.
- **Gerekli görseller:** [mağaza](https://partner.steamgames.com/doc/store/assets/standard) · [kütüphane](https://partner.steamgames.com/doc/store/assets/libraryassets)

  | Görsel | Boyut |
  |---|---|
  | Başlık kapsülü | 920×430 |
  | Küçük kapsül | 462×174 |
  | Ana kapsül | 1232×706 |
  | Dikey kapsül | 748×896 |
  | Ekran görüntüleri | en az 5 adet, 1920×1080 ya da üstü, 16:9, gerçek oyun |
  | Sayfa arka planı (isteğe bağlı) | 1438×810 |
  | Kütüphane kapsülü | 600×900 |
  | Kütüphane kahraman görseli | 3840×1240, yazısız; önemli kısım ortadaki 860×380 alanda |
  | Kütüphane logosu | 1280 genişlik ve/veya 720 yükseklik, şeffaf PNG |

- **Kapsül kuralları:** Sadece görsel ve oyunun adı. İnceleme puanı, ödül, indirim ya da "şimdi al" gibi yazı yasak. [kurallar](https://partner.steamgames.com/doc/store/assets/rules)
- **Yapay zekâ beyanı:** İçerik anketinde, oyunda oyuncunun gördüğü ya da duyduğu yapay zekâ ile üretilmiş her şey (görsel, ses, metin, çeviri) beyan edilir. Kod asistanları gibi geliştirme araçları 2026 Ocak'tan beri beyan gerektirmiyor. [Steam](https://partner.steamgames.com/doc/gettingstarted/contentsurvey)

## 6. Kim ne yapar [KARAR]

Öneri; ekip konuşup netleştirsin. Abdulalim ve Ulaş'ın somut sorumluluk alanı burada belirlenebilir.

| Kişi | M3'teki işi |
|---|---|
| **Kerem Gönç** | Görsel yön kararı. Karakterlerin kişilikleri. Hesap Günü sahnesinin fikri. Referans panosunu onaylar. |
| **Abdulalim** (öneri) | Referans panosu: stil, ortam, maymun örnekleri (Pinterest, ArtStation). Sanatçı araştırması ve iletişim (portfolyo toplama, fiyat sorma). |
| **Ulaş** (öneri) | Ses ve müzik araştırması (hazır paketler, lisanslar). Steam sayfası metinleri (TR/EN). Discord topluluğunu kurma. |
| **Kerem Ataç + Claude** | Teknik hazırlık ve sanatçı şartnamesi. Modelin oyuna bağlanması. Test. |

## 7. Adımlar

| Adım | İçerik | Para |
|---|---|---|
| **M3a** | Referans panosu → görsel yön kararı (ADR-0004). Sanatçı şartnamesi. Teknik hazırlık (aşağıda). Ücretsiz bir maymun modeliyle deneme. | Yok |
| **M2 ekip testi** | En az bir gece oynanır. Devam / değiştir / bırak kararı. | Yok |
| **M3b** | Karakter (sipariş ya da paket). Tek maymun oyunda: ağız, aksesuarlar, birkaç animasyon. | Var |
| **M3c** | Oda ve ışık, masa üstü nesneleri. | Var |
| **M3d** | Hesap Günü sahnesi, ses ve müzik, arayüz teması. | Var |
| **M3e** | Steam sayfası: ücret, görseller, metin, "Yakında" sayfası. Kapsül siparişi. | Var |

**Bitti kriteri:** Ekip dikey dilimi oynar ve "bunu Steam'de görsem tıklarım" der. Steam sayfası açık.

## 8. Teknik hazırlık (M3a, para gerektirmez): bitti

Kararı ve gerekçesi: [ADR-0003](adr/0003-maymun-modeli-sozlesmesi.md). Sanatçıya giden kurallar: [sanatçı şartnamesi](sanatci-sartnamesi.md) ([İngilizcesi](artist-spec.en.md)).

1. **Maymun arayüzü:** Masa maymunla tek bir sınıf üzerinden konuşuyor (`features/monkey/monkey.gd`):
   - ad ve durum;
   - denetçi şapkası;
   - aksesuarlar;
   - ses ve ağız;
   - tepkiler (yakalandı, sevinç, hayal kırıklığı).

   Hangi koltukta hangi model olduğu `assets/monkeys/cast.tres`'te. Yeni maymun gelince kod değişmez.
2. **Aksesuarlar:** Modelin içinde, `acc_glasses` gibi adlarla.
   - Sert olanlar kemiğe bağlı; Godot'da `BoneAttachment3D` olarak geliyor. Eldivenler iskelete bağlı (skinned).
   - Oyun görünürlüğü açıp kapıyor. Kendi aksesuarların masada, önünde duruyor (kendi maymununu görmüyorsun).
3. **Konuşan ağız ve göz kırpma:** `jaw_open` ve `blink` blend shape'leri.
   - Ağız ses seviyesini izliyor.
   - 0,25 saniyeden uzun konuşmada maymun `talk` animasyonuna geçiyor, susunca beklemeye dönüyor.
4. **Karikatür görünüm:** Toon ışık ve stencil kontur koddan ekleniyor (`cast.tres` → Toon). Aynı model koltuklara göre farklı kürk rengi alabiliyor.
5. **Sanatçı şartnamesi:** Hazır.
   - Biçim, ölçek, poligon ve doku bütçesi.
   - Kemik ve blend shape adları, aksesuar ve şapka nesneleri.
   - Animasyon listesi, oturma ölçüleri, dışa aktarma ayarları, haklar.
6. **Ücretsiz test maymunu:** Hazır ve masada.
   - OpenGameArt'taki model şartnameye uymadığı için Blender betiğiyle üretildi (`tools/blender/make_test_monkey.py`, Suzanne başı, CC0).
   - Bütün zincir onunla sınandı: Blender → glTF → Godot, iskelet, ağız, göz, aksesuar, 5 animasyon.
7. **Teslim kontrolü:**
   - `tools/check_monkey_model.gd` bir modeli şartnameye göre denetliyor. Testler de oyundaki bütün modelleri denetliyor.
   - Editörde `features/monkey/monkey_preview.tscn` (F6) modeli tuşlarla oynatıyor.

**Kalan (ekipte):**
- Referans panosu ve görsel yön kararı (ADR-0004).
- Şartnamenin Kerem Gönç'le gözden geçirilmesi: özellikle denetçi şapkasının tasarımı ve animasyon listesi.
- Mixamo ya da Quaternius animasyonlarının test maymununa aktarılması. İskelet adları uyumlu; denemesi M3b'de, gerçek modelle.
