# Kurallar v0.2 — Kağıt prototip

> Durum: **Yerini [v0.3](kurallar-v0.3.md) aldı** (2026-10-21). Neyin neden değiştiğini görmek için duruyor.
>
> Eski durum: Test edilecek taslak · Son güncelleme: 2026-10-21
>
> - v0.1'deki simülasyon önerileri uygulandı ([farklar](#v01den-farklar)). Kerem Ataç kabul etti (2026-10-21).
> - **[ÖNERİ]** işaretli kurallar Claude'un önerisi; fikir sahibinin (Kerem Gönç) onayı gerekiyor.
> - **[KARAR]** işaretli yerlerde ekip seçim yapmalı.
> - Bütün sayılar ilk tahmin; playtest'lerden sonra değişecek. Oyundaki karşılıkları `game/data/rules_v0_2.tres` dosyasında.
> - Simülasyon: [bulgular v0.2](../sim/bulgular-v0.2.md). Önceki sürüm: [kurallar v0.1](kurallar-v0.1.md).

Amaç: Dijital oyuna tek satır kod yazmadan önce, çekirdek eğlenceyi gerçek bir masada, gerçek jetonlarla test etmek.

## v0.1'den farklar

| Kural | v0.1 | v0.2 | Neden (simülasyon) |
|---|---|---|---|
| Denetçinin geliri | Gizli. Denetçi o tur denetlenmediği için yalanı risksiz. | Denetçi beyan yazmaz, gelir kartını açar. | Sadece kendi denetçi turunda çalan oyuncu %48 kazanıyordu, şimdi %25. |
| Katkı | Serbest | Herkes beyanının en az %60'ını öder, beyanlar açılır açılmaz. | Doğru beyan edip az ödeyen %54 kazanıyordu, şimdi %25. |
| Son tur alışverişi | Var | Yok | Son denetimden sonra aksesuar risksiz bir hediyeydi. |
| Yalan | Beyan < gerçek gelir | Beyan ≠ gerçek gelir | Fazla beyanla arkadaşın yalanı bedavaya örtülebiliyordu. |
| Oyuncu sayısı | 4 | En az 3 (sayılar şimdilik 4 kişilik) | 2 kişide toplam bilindiği için gelirler açığa çıkıyor. |

## Malzeme

- ~150 jeton (bozuk para, poker fişi, nohut…)
- **8 zarf**, her birinde bir dağıtım setinin 4 gelir kartı (aşağıda)
- Her oyuncuya: kendi zarfı (gelir kartlarını ve beyan kağıtlarını saklamak için), kalem
- Ortak kasa (bir kase) ve borç takip kağıdı
- Aksesuar kartları (fiyatları yazılı)
- Asgari katkı tablosunun bir kopyası (aşağıda)
- Telefon zamanlayıcı

Moderatör gerekmiyor. Bütün kartlar ve kağıtlar maç sonuna kadar saklanıyor, Hesap Günü'nde her şey doğrulanabiliyor.

## Kurulum

- 4 oyuncu, herkes 0 jetonla başlar. **[KARAR]** Başlangıç parası olsun mu?
- Oyun en az 3 kişiyle oynanır. 3 ve 5 kişilik sayılar henüz tasarlanmadı; 3 kişide açık denetçi kartı bir sorun yaratıyor (bkz. "Uç durumlar").
- **Borç: 48 jeton, 4 taksit → her tur 12.** [ÖNERİ: Tek seferlik toplam borç yerine taksit. Her turun kendi doruk noktası olur ve "son tura bırakırız" ertelemesi önlenir.]
- Denetçi sırası sabit: 1. tur A, 2. tur B, 3. tur C, 4. tur D. 4 tur, 4 oyuncu: herkes bir kez denetçi olur.
  - [ÖNERİ] Gece boyunca her yeni maçta ilk denetçi bir kişi kayar. Simülasyonda yalancı masalarda ilk turun denetçisi son turunkinden daha sık kazanıyor.

## Gelir dağıtım setleri (her birinin toplamı 20)

| Zarf | Kartlar |
|---|---|
| 1 | 2 · 4 · 6 · 8 |
| 2 | 1 · 3 · 7 · 9 |
| 3 | 5 · 5 · 5 · 5 |
| 4 | 2 · 2 · 6 · 10 |
| 5 | 3 · 4 · 6 · 7 |
| 6 | 1 · 1 · 8 · 10 |
| 7 | 4 · 4 · 4 · 8 |
| 8 | 2 · 3 · 5 · 10 |

Herkes toplamın 20 olduğunu bilir, hangi setin çekildiğini bilmez. **[KARAR]** Sabit set listesini oyunculara göstermek çıkarımı artırır ("iki kişi 2 dedi, ama hangi sette iki tane 2 var?"). Göstermemek blöfü kolaylaştırır. İkisini de deneyin.

## Bir tur (~3–4 dk)

1. **Gelir.** Rastgele bir zarf seçilir, kartlar kapalı karıştırılıp dağıtılır. Herkes kendi kartına bakar, o kadar jetonu bankadan gizli cebine alır ve kartı kendi zarfına koyar.
2. **Beyan.**
   - Herkes kağıda "bana X geldi" yazar. **Denetçi yazmaz; gelir kartını kapalı olarak ortaya koyar.**
   - Kağıtlar ve denetçinin kartı aynı anda açılır. Beyanlar toplanır ve **kayıp jeton = 20 − beyan toplamı** yüksek sesle söylenir.
   - Oyun içinde "yalan"ın tanımı: **beyan ≠ gerçek gelir**. Sesli sohbette söylenenleri oyun denetleyemez, beyanı denetleyebilir.
   - Fazla beyan da yalandır. Yakalanınca iade yoktur (saklanan jeton yok), sadece fark kadar ceza ödenir.
3. **Asgari katkı.** Beyanlar açılır açılmaz herkes beyanının **%60'ını (yukarı yuvarlanır)** herkesin önünde kasaya koyar:

   | Beyan | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
   |---|---|---|---|---|---|---|---|---|---|---|---|
   | **Asgari** | 0 | 1 | 2 | 2 | 3 | 3 | 4 | 5 | 5 | 6 | 6 |

   - 10'dan büyük beyan için: beyan × 0,6, yukarı yuvarlanır.
   - Parası yetmeyen cebindeki her şeyi koyar. Bu sadece gelirinden fazlasını beyan edince olabilir.
   - [ÖNERİ] Asgari pazarlıktan **önce** ödenir. Pazarlıkta jetonlar masa altından el değiştirebiliyor. Asgari sonra ödenseydi, cebini arkadaşına boşaltan "param yok" deyip ödemekten kurtulurdu.
   - %60 = taksit / gelir toplamı (12 / 20). Dürüst bir masada asgariler tek başına taksiti karşılar.
     Taksiti tehlikeye atan şey saklanan jetonlar: saklanan her jeton kasadan ~0,6 jeton eksiltir.
4. **Pazarlık (2 dk).** Serbest konuşma. Bu sırada:
   - **Kefil:** "X'e kefilim" denebilir. Kefalet kağıda yazılır. Kurallar:
     - Kendine kefil olunamaz; tur başına en fazla 1 kefalet verilir.
     - Birden fazla kişi aynı oyuncuya kefil olabilir.
     - [ÖNERİ] **Denetçi kefil olamaz, denetçiye de kefil olunamaz.** Yoksa denetçi kendi hedefine kefil olup "temiz" diyerek bankadan bedava +2 alır. Denetçinin kartı zaten açık olduğu için ona kefil olmak anlamsız.
   - **Masa altı:** Jeton transferi serbesttir ve gizli yapılabilir (rüşvet, borç, ittifak). Hiçbir söz bağlayıcı değildir.
5. **Ek katkı.** Herkes asgarinin üstüne koymak istediği jetonu kapalı avucunda tutar (0 da olabilir). Avuçlar aynı anda açılır, ek katkılar herkese açıktır.
   Kasada taksite eksik varsa onu kimin kapatacağı pazarlığın asıl konusudur.
6. **Denetim.** Denetçi herkesin önünde bir oyuncuyu seçer ve onun bu turki gelir kartına **gizlice** bakar. Sonra iki şeyden birini söyler:
   - **"Raporluyorum"** → kart herkese gösterilir, ceza uygulanır.
   - **"Temiz"** → denetlenene 1 jeton "haksız denetim tazminatı" öder.

   Denetçi yalanı görüp "temiz" diyebilir. Buna **örtbas** denir ve Hesap Günü'nde ortaya çıkar. [ÖNERİ: Kullanıcı hikâyesindeki "parayı kabul edip arkadaşını kollama" fikrini bu şekilde formel hale getiriyoruz. Alternatif olarak sonucu her zaman açık denetimi de test edin.]

   **Yakalanırsa** (fark = g):
   - Yalancı g jetonu kasaya öder.
   - Ayrıca g jeton ceza öder; cezayı denetçi alır.
   - Kefili varsa ceza paylaşılır: kefil ⌊g/2⌋, yalancı kalanını öder.
     [ÖNERİ] Birden fazla kefil varsa ⌊g/2⌋'yi eşit bölerler (aşağı yuvarlanır), kalanı yalancı öder.

   **Temiz çıkarsa:** Denetlenene kefil olan herkes bankadan +2 alır.

   Kurallar:
   - Denetçinin kendisi o tur denetlenmez; kartı açık olduğu için yalan da söyleyemez.
   - Ödeyecek nakdi yetmeyen oyuncunun aksesuarlarına alış fiyatından el konur (en ucuzdan başlayarak, para üstü geri verilir). O da yetmezse kalan tutar ortak borca eklenir.
     - **[KARAR]** Bu kural, yakalanan yalancının ödeyemediği cezayı masaya ödetiyor. Simülasyonda bu, karışık bir masada maç başına ~5 jeton ediyor. Öneri: senet ([bulgular v0.2](../sim/bulgular-v0.2.md)).
   - Parası yetmeyen denetçinin ödeyemediği tazminat da aynı şekilde ortak borca eklenir.
7. **Taksit kontrolü.** Kasaya bu tur giren (asgariler + ek katkılar + yakalanan paralar) ≥ 12 ise taksit ödenmiştir; fazlası sonraki taksitten düşer.
   Eksik kalırsa: eksik × 1,5 (yukarı yuvarlanır) sonraki taksite eklenir. Bu faizdir.
8. **Alışveriş (sadece 1–3. turlarda).** Cepteki jetonla aksesuar alınabilir. Aksesuar kartı oyuncunun önüne, herkesin göreceği şekilde konur.
   4. turda dükkan açılmaz: son denetimden sonra aksesuar almanın riski kalmıyor.

| Aksesuar | Fiyat | Maç sonu değeri |
|---|---|---|
| Gözlük | 4 | 5 |
| Eldiven | 6 | 7 |
| Saat | 8 | 10 |
| Altın zincir | 12 | 15 |
| Taç | 20 | 25 |

[ÖNERİ] Aksesuarlar ~%25 "statü bonusu" ile değerlenir ama görünürdür ve cezada haczedilebilir. Nakit gizlidir ama bonus vermez. Bu gerilimin amacı aksesuarı anlamlı kılmak; yoksa skoru düşüren bir şeyi kimse almaz.

## Maç sonu — Hesap Günü

- **Borç bitti:** Masa kurtulur. En zengin (nakit + aksesuar değeri) kazanır. Eşitlikte, 4 turda kasaya toplam en çok koyan (asgariler dahil) kazanır.
  [ÖNERİ] O da eşitse oyuncular daha iyi sırayı paylaşır (ikisi de o sıranın puanını alır).
- **Borç kaldı:** Herkes kaybeder.
- **Her durumda Hesap Günü yapılır.** Herkes zarfını açar; bütün gerçek gelirler, beyanlar, kefaletler ve örtbaslar okunur. Dijital oyunun en önemli klip anı burası olacak.

## Gece skoru [ÖNERİ]

Bir oturum 3 maçtır.
- Masa kurtulursa sıralama puanı **5 / 3 / 2 / 1**.
- Masa batarsa herkes **0**.

Böylece sonuncu bile masanın kurtulmasını ister (1 > 0). Bu kural, kaybettiğini düşünen oyuncunun "batırırım" demesini baskın strateji olmaktan çıkarır ama bir pazarlık kozu olarak bırakır.
v0.2'de asgari katkı yüzünden kimse katkıyı tamamen kesemiyor; masayı batırmak artık ancak beyanı düşürmekle mümkün.

## Matematik notları

- **Ekonomi:** 4 tur × 20 = 80 jeton gelir; borç 48 (%60).
  - Herkes doğru beyan ederse asgariler her tur 12–14 eder (yukarı yuvarlama yüzünden). Taksit ödenir, fazlası sonraki taksitten düşer.
  - Masa en fazla 32 jetonu "güvenle" çalabilir, kişi başı ortalama 8.
- **Yalanın beklenen değeri:** g jeton saklayınca asgarin 0,6g azalır. Dürüst oyuncuya göre kazancın budur.
  Yakalanırsan g'yi iade eder, g de ceza ödersin. Dürüst oyuncuya göre zararın 1,4g olur. Yakalanma olasılığı p ise:
  `BD = (1−p)·0,6g − p·1,4g = g·(0,6 − 2p)`
  - Denetçi 3 kişiden rastgele seçerse p = 1/3 ve BD ≈ −0,07g: yalan ortalamada hafif zararlı.
  - Yalan ancak p < 0,3 ise kârlı. Yani denetçiyi başkasına yönlendirebiliyorsan, ya da masada başka yalancılar da varsa (denetçi tek kişiye bakabiliyor).
  - v0.1'de katkı beyandan bağımsızdı, saklanan jetonun tamamı kazançtı: `g·(1 − 2p)`. v0.2 yalanı belirgin şekilde pahalılaştırdı.
- **Denetçinin hesabı:** X'in yalan söyleme olasılığını q, saklanan miktarı g diye tahmin eden denetçinin beklentisi:
  `q·g − (1−q)·1`
  - Örnek: q = 0,5, g = 4 → 1,5 jeton. Dolayısıyla "beni denetleme, sana 2 jeton vereyim" teklifi denetçi için gerçekten cazip.
- **Örtbas pazarlığı:** Raporlanırsa yalancı 2g kaybeder; örtbas edilirse üstüne 1 jeton tazminat da alır.
  Bu yüzden yalancı en fazla 2g+1 rüşvet verir. Denetçi ise raporlarsa g kazanır, örtbas ederse b−1 kazanır.
  - Yani yakalandıktan sonra (g+1, 2g+1) aralığındaki rüşvet iki taraf için de kârlı.
  - Ama örtbas edilen g jeton kasaya girmez ve taksiti riske atar.

Bu hesaplar simülatörde botlarla binlerce maç oynatılarak kontrol edildi: [bulgular-v0.2.md](../sim/bulgular-v0.2.md).

## Bu sürümde özellikle gözlemleyin

- **Yalan söyleyen çıkıyor mu?** Simülasyonda masadaki tek yalancı çok kötü sonuç alıyor. Herkes dürüst oynarsa kazananı gelir şansı belirler; bu sıkıcı mı?
- **Yalancılar ne sıklıkla yakalanıyor?** Botlar tek yalancıyı %85 yakalıyor. İnsanlar konuşarak denetçiyi başka yöne çevirebiliyor mu?
- Asgarinin üstünde ek katkı yapan var mı? Eksiği kimin kapatacağı konuşuluyor mu?
- Denetçinin açık kartı konuşmayı nasıl değiştiriyor? "Kayıp jeton" artık 3 kişi arasında.
- Örtbas ve rüşvet: botlarda nadir, insanlarda ne kadar?
- Fazla beyan: biri arkadaşını örtmek için kullanıyor mu?
- Yakalanan yalancı cezayı ödeyebiliyor mu, yoksa kalan ortak borca mı ekleniyor? Masa buna nasıl tepki veriyor?
- 4. turda kaybettiğini düşünen biri ne yapıyor?
- Kimse aksesuar almıyorsa bonus yetersiz demektir; herkes alıyorsa fazla.
- "Kayıp jeton" sayısı konuşmayı başlatıyor mu?
- Pazarlık süresi kısa mı, uzun mu?
- Maç süresi (hedef 10–15 dk) ve maç sonunda "bir maç daha" deniyor mu?
- Taksit 12 kolay mı, zor mu? Hedef: turların yaklaşık yarısında taksit kıl payı ödenmeli. Simülasyonda v0.2 ile karışık masada turların ~%28'i sıkışık.

## Uç durumlar (dijital sürüm için listeye girecek)

- **3 oyuncu ve açık denetçi kartı:** Denetçi olmayan iki kişi birbirinin gelirini kesin bilir (toplam − kendi gelirin − denetçinin kartı). 2 kişilik sorunun aynısı.
  **[KARAR]** 3 kişilik kurallarda başka bir çözüm gerekiyor; ör. denetçinin beyanını bir sonraki turun denetçisi geriye dönük denetleyebilsin.
- **Yolsuzluk çetesi:** X yalan söyler, Y ona kefil olur, Z denetçi örtbas eder → Y bankadan +2, X tazminat alır. Tema olarak harika ama baskın strateji olmamalı.
- Kefilin kendisinin de yalancı olması.
- Denetçinin birden fazla kişiden rüşvet alıp yine de denetlemesi.
- {5,5,5,5} setinde herkesin 5 demesi → kayıp 0, kesin dürüstlük. Bu set fazla mı "ölü"?
- Kalan borç son tura kapatılamayacak kadar büyürse geri kalan oyun anlamsızlaşır → erken iflas kuralı?
- 3 veya 5 oyuncu: gelir toplamı, taksit ve denetçi sırası nasıl ölçeklenecek?
- **2 oyuncu olmaz:** toplam bilindiği için gelirin biri belli olunca diğeri de belli olur (toplam − kendi gelirin).
  İlk Steam testinde (2 kişi) görüldü.
- **Dijitale özgü:** oyuncu kopması, AFK, host'un çıkması, mikrofonu olmayan oyuncu.
