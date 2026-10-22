# M3b — Karakter: sipariş paketi

> Durum: **Hazır, ekip kararı bekliyor** · Son güncelleme: 2026-10-22
> Plan: [M3 planı](m3-plan.md) · Modelin kuralları: [sanatçı şartnamesi](sanatci-sartnamesi.md) · İlan metni (İngilizce): [artist-job-post.en.md](artist-job-post.en.md)

M3b'nin hedefi (plandan): **tek maymun oyunda**, ağzı, aksesuarları ve birkaç animasyonuyla. Teknik tarafı M3a'da hazırlandı:
- Yeni bir model `.glb` olarak gelir.
- Kontrol aracından geçer.
- `cast.tres`'e eklenince masaya oturur; kod değişmez.

Bu belge kalan işi, yani **karakteri bulmayı ve sipariş etmeyi**, adım adım anlatıyor.

## 1. Başlamadan önce: kararlar

Para harcanmadan önce şunların netleşmesi gerekiyor. Hepsi ekibin kararı.

| Karar | Nerede | Önerimiz |
|---|---|---|
| **M2 ekip testi yapıldı mı, "devam" dendi mi?** | [M3 planı](m3-plan.md#sıra-önce-ekip-testi-sonra-para): "önce ekip testi, sonra para" | Test yoksa önce bir gece oynayın. İlanı hazırlamak ve fiyat sormak para gerektirmez; o kısım beklemeden başlayabilir. |
| **Bütçe senaryosu** | [M3 planı §4](m3-plan.md#4-bütçe-senaryoları-karar) | **Orta senaryo, parça parça:** önce konsept ve tek maymun, beğenilirse devamı (bkz. 3). |
| **Görsel yön** (ADR-0004) | [M3 planı §1](m3-plan.md#1-görsel-yön-karar) | İlan metni önerimize, yani stilize karikatür ve 70'ler gazino arka odasına göre yazıldı. Karar değişirse ilan da değişir. |
| **Şartnamenin onayı** | [sanatçı şartnamesi](sanatci-sartnamesi.md) | Kerem Gönç özellikle denetçi şapkasına ve animasyon listesine bakar. |
| **Haklar kime geçecek, kim ödeyecek** | [ekip sözleşmesi](ekip-sozlesmesi.md): "Fikri mülkiyet", "Harcamalar", "Şirketleşme" maddeleri hâlâ açık | Sözleşmeyi kim imzalayacak, sanatçı hakları kime devredecek? Önce bunu ekip yazılı olarak kararlaştırsın; gerekirse bir avukata ya da mali müşavire danışın. Ödemeyi yapan kişi ile hakları alan taraf belli olmalı. |

## 2. Ne sipariş ediyoruz

Tamamı (plandaki "1 temel model + 4 varyant"):
- **Dört maymun.** Aynı temel model ve iskelet üzerinde dört varyant (kürk, kıyafet, renk, kişilik). Masada uzaktan ayırt edilmeliler.
- **Aksesuarlar:** Her maymunda beş aksesuar ve denetçi şapkası, şartnamedeki adlarla.
- **Animasyonlar:** Beş animasyon: `idle`, `talk`, `caught`, `cheer`, `slump`. Aynı iskelet, bu yüzden bir kez yapılır, dört varyantta oynar.
- **Konsept:** Dört maymunun 2D tasarımı, modele başlamadan önce.

Dört aşamaya bölünür. **2. aşamadan sonra bir dur noktası var:** ilk maymun oyunda beğenilmezse devam etmeyiz.

## 3. Aşamalar ve ödeme

| Aşama | Teslim | Kabul | Ödeme payı (öneri) |
|---|---|---|---|
| **1. Konsept** | Dört maymunun ön ve yan çizimi, renkler, aksesuarlar, denetçi şapkası. 2 düzeltme turu. | Kerem Gönç onaylar | %15 |
| **2. Temel maymun** | Bir maymun: model, doku, iskelet, `jaw_open`/`blink`, aksesuarlar, şapka, A-poz `.glb` ve `.blend`. 2 düzeltme turu. | Kontrol aracı 0 hata, oyunda bot gecesi, ekip onayı | %35 |
| — **Dur noktası** | Ekip ilk maymunu oyunda görür: devam mı? | | |
| **3. Animasyonlar** | Beş animasyon, oturarak, şartnamedeki ölçülerle. | Oyunda tepkiler doğru anlarda oynuyor | %20 |
| **4. Varyantlar** | Kalan üç maymun, aksesuarları, son dosyalar ve kaynaklar. | Kontrol aracı 0 hata, dördü masada | %30 |

**Ödeme kuralları:**
- **Önden ödeme:** Her aşama teslim edilip kabul edilince ödenir. Sanatçı önden pay isterse en çok ilk aşamanın payı verilir.
- **Emanet hesabı:** Fiverr ve Upwork gibi platformlar parayı aşama bitene kadar emanette tutuyor (escrow). İlk kez çalışılan biriyle bu güvenli yol.
- **Kabul süresi:** Her teslimde Kerem Ataç kontrol aracını, önizleme sahnesini ve bir bot gecesini çalıştırır, 3 gün içinde yazılı geri bildirim verir. Adımlar: [şartname §10](sanatci-sartnamesi.md#10-ekip-için-teslim-alma-ve-oyuna-koyma).

## 4. Bütçe (tahmin)

Kesin fiyat tekliflerle belli olur. Aralıklar M3 planındaki araştırmadan ve aşağıdaki kaynaklardan; "tahmin" yazanlar bizim çıkarımımız.

| Kalem | Aralık | Kaynak |
|---|---|---|
| Konsept (4 maymun) | $300–1.200 (tahmin) | Bir stüdyonun 2025 fiyat listesi: karakter eskizi $200–300, renkli taslak $300–500 ([RocketBrush](https://rocketbrush.com/blog/character-concept-art-cost-a-full-guide)). Serbest sanatçılar genelde daha ucuz. |
| Temel maymun (model + doku + iskelet + yüz) | $800–3.000 | [M3 planı §3](m3-plan.md#sipariş-serbest-sanatçı) |
| Üç varyant ve aksesuarlar | $400–1.500 (tahmin) | Aynı temel üzerinde; dört ayrı siparişten ucuz. |
| Beş animasyon | $250–1.000 (tahmin) | Fiverr'da klip başı $40'tan; orta seviye animatör saati $50–100 ([M3 planı](m3-plan.md#sipariş-serbest-sanatçı)) |
| **Toplam** | **~$1.750–6.700** | Orta senaryonun karakter payına yakın; üst ucu senaryoyu aşıyor, yani pazarlık ve aşamalı karar önemli. |

**İlan bütçesi:** İlanda bir rakam yazmak iyi teklif almayı kolaylaştırıyor. Öneri: önce **1. ve 2. aşama için $1.000–2.000** yazılsın; devamı fiyatı aşamalara göre konuşulur. Bu bir karar; ilan metninde yer tutucu olarak duruyor.

## 5. Sanatçı nerede bulunur

| Yer | Ücret | Not |
|---|---|---|
| **Polycount** forumu, "Freelance Job Postings" | Ücretsiz | Sadece ücretli serbest iş. Başvurular e-posta ya da mesajla gelir, başlığa değil. Kurallar forumun en üstündeki "Freelance Jobs - Guidelines" başlığında. ([forum](https://polycount.com/categories/freelance-job-postings)) |
| **r/gameDevClassifieds** (Reddit), `[PAID]` etiketiyle | Ücretsiz | Ayrıntılı ve adil ücretli ilan isteniyor. Kuralları göndermeden önce sayfasında kontrol edin; okuyabildiğimiz kopya 2022 tarihli. ([subreddit](https://www.reddit.com/r/gameDevClassifieds/)) |
| **ArtStation Jobs** | Serbest iş ilanı ~$150, 15 gün (üçüncü taraf bir incelemeden; güncel fiyatı sitede kontrol edin) | Stilize karakter sanatçılarının çoğu burada. ([inceleme](https://www.betterteam.com/artstation-jobs)) |
| **Doğrudan ulaşmak** | Ücretsiz | ArtStation ve Sketchfab'da "stylized character", "game ready", "Blender" araması. Sketchfab'da modelin tel kafesine ve animasyonuna bakılabiliyor. Beğendiğiniz 5–10 kişiye kısa bir mesaj ve ilan bağlantısı. |
| **Fiverr / Upwork** | Platform hizmet bedeli (siparişte görünür) | Emanet hesabı ve anlaşmazlık süreci var. Kalite çok değişken; portfolyoya göre seçin. |
| **Türkiye:** Armut, Bionluk | Değişken | Armut "3D karakter modelleme" için 500–5.000 TL ortalama gösteriyor ([Armut](https://armut.com/fiyatlari/3d-karakter-modelleme_1627)). Oyun karakteri deneyimine dikkat; çoğu ilan baskı ve figür için. |

**Kim yapar:** Plandaki öneriye göre portfolyo toplama ve ilk iletişim Abdulalim'de; seçim ekibin.

**Mesaj sayısı:** 3–5 sanatçıdan teklif alın, ikisiyle kısa görüşün.

## 6. Portfolyo nasıl değerlendirilir

Her aday için 1–5 puan:

1. **Stil:** Stilize, kişilikli karakterler; abartılı yüz ve silüet. Gerçekçi işler tek başına yetmez.
2. **Oyuna hazır iş:**
   - tel kafes (wireframe), üçgen sayısı;
   - doku sayfaları;
   - iskeletli ve animasyonlu örnekler (turntable, Sketchfab).
3. **Yüz:** Ağız ve göz şekilleri (shape key) ya da ifadeler gösterilmiş mi?
4. **Tutarlılık:** Aynı dünyadan birden çok karakter. Bizim dört maymunumuz bir aile gibi görünmeli.
5. **Araçlar:** Blender ve glTF tecrübesi. Godot bilen artı puan, şart değil.
6. **İletişim:**
   - Cevap süresi.
   - İngilizce ya da Türkçe.
   - Aşamalı, net bir teklif.
   - Haftalık ara görüntü sözü.

**Kırmızı bayraklar:**
- Ödemenin tamamını önden istemek; aşamalı çalışmayı reddetmek.
- Ara aşama (eskiz, kil hâli, tel kafes) gösteremeyen portfolyo.
  - Başkasının işi olabilir: görselleri tersine görsel aramasıyla kontrol edin.
  - Yapay zekâ çıktısı olabilir.
- Piyasanın çok altında fiyat ve çok kısa süre.
- Şartnameyi okumadan "her şeyi yaparım" demek.

## 7. Adaylara sorulacaklar

İngilizce, kopyalanabilir:

```
1. Could you share 2–3 game-ready rigged characters you made (wireframe, polycount, a turntable or a Sketchfab link)?
2. Have you made shape keys for a talking mouth and blinking? Can you export glTF (.glb) from Blender following our spec?
3. Would you do the 2D concept of the four monkeys yourself, or work from our sketches?
4. Your price per milestone (concept, base monkey, animations, variants), revisions included, and timeline?
5. Do you use AI tools anywhere in your process? (Steam asks us to disclose AI content.)
6. Are you fine with a full transfer of rights on payment (work for hire)? We are happy for you to show the work in your portfolio once the game is announced.
7. Can you send a short progress image every week?
```

## 8. Sözleşmede olması gerekenler

Bu bir hukuki metin değil; imzalamadan önce [ekip sözleşmesi](ekip-sozlesmesi.md) kararları ve gerekiyorsa bir avukat. Platform üzerinden çalışılıyorsa bunların bir kısmı platform şartlarında var; geri kalanı sipariş açıklamasına yazılır.

- **Kapsam:** Şartnamenin sürümü (tarih ve bağlantı), aşamalar ve teslimler.
- **Kabul:** Kontrol aracı 0 hata ve ekibin yazılı onayı. Her aşamada düzeltme turu sayısı.
- **Takvim:** Aşama başına tarih. Gecikmede ne olur.
- **Ödeme:** Aşama başına tutar, para birimi, yöntem (platform, banka, Wise, PayPal).
- **Haklar:**
  - Ödeme yapılınca bütün ticari haklar ekibin belirlediği tarafa geçer.
  - Kaynak dosyalar da teslim edilir.
  - Sanatçı oyun duyurulduktan sonra işi portfolyosunda gösterebilir.
- **Gizlilik:** Oyun duyurulana kadar paylaşmama.
- **İçerik:** Üçüncü taraf içerik yok (lisansı belirtilmedikçe). Yapay zekâ kullanıldıysa beyan.
- **Jenerik:** Sanatçının adı oyunda (isterse).
- **Ayrılma:** Taraflardan biri bırakırsa tamamlanmış aşamalar ödenir ve teslim edilir.

## 9. Takvim (tahmin)

| Aşama | Süre |
|---|---|
| İlan ve teklifler | 1–2 hafta |
| Konsept | 1–2 hafta |
| Temel maymun | 2–4 hafta |
| Dur noktası (oyunda deneme) | birkaç gün |
| Animasyonlar | 1–2 hafta |
| Varyantlar | 2–3 hafta |
| **Toplam** | **~7–13 hafta** |

## Hazır animasyon denemesi

**Soru:** Animasyonları hazır kütüphanelerden alıp siparişi küçültebilir miyiz? M3 planı "önce Mixamo ve Quaternius" diyordu. M3b'de Quaternius'un ücretsiz kütüphanesiyle denendi ([Universal Animation Library](https://opengameart.org/content/universal-animation-library), Standard sürüm, CC0, 45 animasyon, oturma animasyonları dahil).

**Ne yapıldı:**
- Kütüphane Godot'ya kemik eşlemeyle (BoneMap, insansı profil) ve Fix Silhouette açık aktarıldı. Kemik adları Rigify düzeninde (`DEF-upper_arm.L`), iskeleti T-pozda.
- Test maymunu da aynı ayarlarla içe aktarıldı (A-pozda).
- Kütüphanenin animasyonları test maymununa eklenip oynatıldı.

**Sonuç:**
- **Aktarma çalışıyor.** Kemikler, eksenler ve A-poz/T-poz farkı Godot'nun içe aktarma ayarlarıyla çözülüyor. Maymun, insan için yapılmış animasyonları oynuyor; kendi animasyonları da bozulmadı.
- **Hazır oturma animasyonları masamıza uymuyor:**
  - **Yükseklik:** İnsan oranlarıyla yapıldıkları için kalça yüksekliği maymuna göre ölçekleniyor. Maymun taburenin içine gömülüyor.
  - **Eller:** Kucakta duruyor, masada değil. Planın "uzun kollar yüzünden eller hedefi ıskalar" riski gerçek.
- **Ne kazandık:** Bütün maymunlar bu ayarlarla içe aktarılınca animasyonları modeller arasında paylaşılabiliyor. Dört varyant ortak animasyonları kullanır.
  - Test maymunu artık böyle ayarlı.
  - Kontrol aracı ayar yapılmamışsa uyarıyor.
  - Editör adımları: [şartname §10](sanatci-sartnamesi.md#10-ekip-için-teslim-alma-ve-oyuna-koyma).

**Karar önerisi:**
- **Sipariş:** Oturma pozu ve beş temel animasyon siparişte kalsın (bkz. 3. aşama).
- **Hazır klipler sonra:** Hazır kütüphaneler ileride ek el hareketleri için düşünülebilir. Bunun için katmanlı animasyon (sadece üst gövde) ya da elleri masaya oturtan IK gerekir. Bu dikey dilimin cilasında, gerçek modelle denenir.

Denemeyi tekrarlamak için:
1. Kütüphaneyi indir.
2. `Godot/AnimationLibrary_Godot_Standard.glb`'yi projeye kopyala.
3. Şartname §10'daki gibi kemik eşlemesini aç. Rigify adları için kırmızı kalanları elle seç: `DEF-spine.001` → Spine, `.002` → Chest, `.003` → UpperChest.
4. AnimationPlayer'ındaki kütüphaneyi bir maymunun AnimationPlayer'ına ekle.
