# M3 — Sanat yönü ve dikey dilim: plan

> Durum: **Taslak plan** · Son güncelleme: 2026-10-21 · Karar gerekenler **[KARAR]** ile işaretli.
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

*(araştırma sonuçlarıyla doldurulacak)*

## 4. Bütçe senaryoları

*(araştırma sonuçlarıyla doldurulacak)*

## 5. Steam sayfası

*(araştırma sonuçlarıyla doldurulacak)*

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
| **M3a** | Referans panosu → görsel yön kararı (ADR-0003). Sanatçı şartnamesi. Teknik hazırlık (aşağıda). Ücretsiz bir maymun modeliyle deneme. | Yok |
| **M2 ekip testi** | En az bir gece oynanır. Devam / değiştir / bırak kararı. | Yok |
| **M3b** | Karakter (sipariş ya da paket). Tek maymun oyunda: ağız, aksesuarlar, birkaç animasyon. | Var |
| **M3c** | Oda ve ışık, masa üstü nesneleri. | Var |
| **M3d** | Hesap Günü sahnesi, ses ve müzik, arayüz teması. | Var |
| **M3e** | Steam sayfası: ücret, görseller, metin, "Yakında" sayfası. Kapsül siparişi. | Var |

**Bitti kriteri:** Ekip dikey dilimi oynar ve "bunu Steam'de görsem tıklarım" der. Steam sayfası açık.

## 8. Teknik hazırlık (M3a, para gerektirmez)

1. **Maymun arayüzü:** Oyunun bir maymuna söyleyebileceği her şey tek bir arayüzde toplanır:
   - "konuşuyor (şu seviyede)";
   - "şu aksesuarları taksın";
   - "denetçi";
   - "şu tepkiyi göster".

   Bugünkü kapsül de bu arayüzü kullanır. Model gelince sadece sahne değişir; oyun kodu değişmez.
2. **Aksesuar takma:** Aksesuarlar kemiklere takılır (Godot'da `BoneAttachment3D`). Şimdilik masadaki küçük şekiller.
3. **Sanatçı şartnamesi** (ayrı belge): dosya formatı (glTF/GLB), ölçek ve eksenler, poligon bütçesi, iskelet ve kemik isimleri, ağız/göz blend shape isimleri, doku boyutları, teslim edilecek animasyonlar. Sipariş verirken sanatçıya verilecek.
4. **Ücretsiz deneme modeli:** Lisansı uygun ücretsiz bir maymun ya da insansı modelle bütün zinciri deneriz: içe aktarma, ağız, aksesuar, animasyon. Para harcamadan önce teknik sürpriz kalmaz.
