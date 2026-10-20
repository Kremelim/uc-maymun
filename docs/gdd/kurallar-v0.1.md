# Kurallar v0.1 — Kağıt prototip

> Durum: **Test edilecek taslak** · Son güncelleme: 2026-10-20
>
> - **[ÖNERİ]** işaretli kurallar Claude'un önerisi; fikir sahibinin (Kerem Gönç) onayı gerekiyor.
> - **[KARAR]** işaretli yerlerde ekip seçim yapmalı.
> - Bütün sayılar ilk tahmin; playtest'lerden sonra değişecek.

Amaç: Dijital oyuna tek satır kod yazmadan önce, çekirdek eğlenceyi gerçek bir masada, gerçek jetonlarla test etmek.

## Malzeme

- ~150 jeton (bozuk para, poker fişi, nohut…)
- **8 zarf**, her birinde bir dağıtım setinin 4 gelir kartı (aşağıda)
- Her oyuncuya: kendi zarfı (gelir kartlarını ve beyan kağıtlarını saklamak için), kalem
- Ortak kasa (bir kase) ve borç takip kağıdı
- Aksesuar kartları (fiyatları yazılı)
- Telefon zamanlayıcı

Moderatör gerekmiyor. Bütün kartlar ve kağıtlar maç sonuna kadar saklanıyor, Hesap Günü'nde her şey doğrulanabiliyor.

## Kurulum

- 4 oyuncu, herkes 0 jetonla başlar. **[KARAR]** Başlangıç parası olsun mu?
- **Borç: 48 jeton, 4 taksit → her tur 12.** [ÖNERİ: Tek seferlik toplam borç yerine taksit. Her turun kendi doruk noktası olur ve "son tura bırakırız" ertelemesi önlenir.]
- Denetçi sırası sabit: 1. tur A, 2. tur B, 3. tur C, 4. tur D. 4 tur, 4 oyuncu: herkes bir kez denetçi olur.

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
2. **Beyan.** Herkes kağıda "bana X geldi" yazar, kağıtlar aynı anda açılır.
   - Beyanlar toplanır ve **kayıp jeton = 20 − beyan toplamı** yüksek sesle söylenir.
   - [ÖNERİ] Oyun içinde "yalan"ın tanımı budur: **beyan < gerçek gelir**. Sesli sohbette söylenenleri oyun denetleyemez, beyanı denetleyebilir.
3. **Pazarlık (2 dk).** Serbest konuşma. Bu sırada:
   - **Kefil:** "X'e kefilim" denebilir. Kendine kefil olunamaz, tur başına en fazla 1 kefalet verilir. Kefalet kağıda yazılır.
   - **Masa altı:** Jeton transferi serbesttir ve gizli yapılabilir (rüşvet, borç, ittifak). Hiçbir söz bağlayıcı değildir.
4. **Katkı.** Herkes kasaya koyacağı jetonu kapalı avucunda tutar, avuçlar aynı anda açılır. Katkılar herkese açıktır.
5. **Denetim.** Denetçi herkesin önünde bir oyuncuyu seçer ve onun bu turki gelir kartına **gizlice** bakar. Sonra iki şeyden birini söyler:
   - **"Raporluyorum"** → kart herkese gösterilir, ceza uygulanır.
   - **"Temiz"** → denetlenene 1 jeton "haksız denetim tazminatı" öder.

   Denetçi yalanı görüp "temiz" diyebilir. Buna **örtbas** denir ve Hesap Günü'nde ortaya çıkar. [ÖNERİ: Kullanıcı hikâyesindeki "parayı kabul edip arkadaşını kollama" fikrini bu şekilde formel hale getiriyoruz. Alternatif olarak sonucu her zaman açık denetimi de test edin.]

   **Yakalanırsa** (fark = g):
   - Yalancı g jetonu kasaya öder.
   - Ayrıca g jeton ceza öder; cezayı denetçi alır.
   - Kefili varsa ceza paylaşılır: kefil ⌊g/2⌋, yalancı kalanını öder.

   **Temiz çıkarsa:** Denetlenene kefil olan kişi bankadan +2 alır.

   Kurallar:
   - Denetçinin kendisi o tur denetlenemez. **[KARAR]** Bu, herkes için "bedava yalan turu" demek. Alternatif: denetçinin beyanını bir sonraki turun denetçisi geriye dönük denetleyebilsin.
   - Ödeyecek nakdi yetmeyen oyuncunun aksesuarlarına alış fiyatından el konur. O da yetmezse kalan tutar ortak borca eklenir.
6. **Taksit kontrolü.** Kasaya bu tur giren (katkılar + yakalanan paralar) ≥ 12 ise taksit ödenmiştir; fazlası sonraki taksitten düşer.
   Eksik kalırsa: eksik × 1,5 (yukarı yuvarlanır) sonraki taksite eklenir. Bu faizdir.
7. **Alışveriş.** Cepteki jetonla aksesuar alınabilir. Aksesuar kartı oyuncunun önüne, herkesin göreceği şekilde konur.

| Aksesuar | Fiyat | Maç sonu değeri |
|---|---|---|
| Gözlük | 4 | 5 |
| Eldiven | 6 | 7 |
| Saat | 8 | 10 |
| Altın zincir | 12 | 15 |
| Taç | 20 | 25 |

[ÖNERİ] Aksesuarlar ~%25 "statü bonusu" ile değerlenir ama görünürdür ve cezada haczedilebilir. Nakit gizlidir ama bonus vermez. Bu gerilimin amacı aksesuarı anlamlı kılmak; yoksa skoru düşüren bir şeyi kimse almaz.

## Maç sonu — Hesap Günü

- **Borç bitti:** Masa kurtulur. En zengin (nakit + aksesuar değeri) kazanır. Eşitlikte, 4 turda kasaya toplam en çok koyan kazanır.
- **Borç kaldı:** Herkes kaybeder.
- **Her durumda Hesap Günü yapılır.** Herkes zarfını açar; bütün gerçek gelirler, beyanlar, kefaletler ve örtbaslar okunur. Dijital oyunun en önemli klip anı burası olacak.

## Gece skoru [ÖNERİ]

Bir oturum 3 maçtır.
- Masa kurtulursa sıralama puanı **5 / 3 / 2 / 1**.
- Masa batarsa herkes **0**.

Böylece sonuncu bile masanın kurtulmasını ister (1 > 0). Bu kural, kaybettiğini düşünen oyuncunun "batırırım" demesini baskın strateji olmaktan çıkarır ama bir pazarlık kozu olarak bırakır.

## Matematik notları

- **Ekonomi:** 4 tur × 20 = 80 jeton gelir; borç 48 (%60). Masa en fazla 32 jetonu "güvenle" çalabilir, kişi başı ortalama 8.
- **Yalanın beklenen değeri:** g jeton saklarsan ve yakalanma olasılığın p ise (yakalanınca g iade + g ceza):
  `BD = (1−p)·g − p·g = g·(1 − 2p)`
  - Denetçi rastgele seçerse p = 1/3 ve BD = +g/3: yalan kârlı ama riskli.
  - p > 1/2 olursa (denetçi senden şüpheleniyorsa) yalan zararlı.
  - Yani **denetçinin kimden şüphelendiği her şeyi belirliyor.** Konuşmanın konusu tam olarak bu olmalı.
- **Denetçinin hesabı:** X'in yalan söyleme olasılığını q, saklanan miktarı g diye tahmin eden denetçinin beklentisi:
  `q·g − (1−q)·1`
  - Örnek: q = 0,5, g = 4 → 1,5 jeton. Dolayısıyla "beni denetleme, sana 2 jeton vereyim" teklifi denetçi için gerçekten cazip.
- **Örtbas pazarlığı:** Raporlanırsa yalancı 2g kaybeder; örtbas edilirse üstüne 1 jeton tazminat da alır.
  Bu yüzden yalancı en fazla 2g+1 rüşvet verir. Denetçi ise raporlarsa g kazanır, örtbas ederse b−1 kazanır.
  - Yani yakalandıktan sonra (g+1, 2g+1) aralığındaki rüşvet iki taraf için de kârlı.
  - Ama örtbas edilen g jeton kasaya girmez ve taksiti riske atar.

Kurallar netleşince bu hesapları simülasyonla doğrulayacağız: bot stratejileriyle binlerce maç oynatıp hangi stratejinin baskın çıktığına bakacağız.

## Bu sürümde özellikle gözlemleyin

- Herkes kendi denetçi turunda mı çalıyor?
- 4. turda kaybettiğini düşünen biri masayı batırıyor mu?
- Kimse aksesuar almıyorsa bonus yetersiz demektir; herkes alıyorsa fazla.
- "Kayıp jeton" sayısı konuşmayı başlatıyor mu?
- Pazarlık süresi kısa mı, uzun mu?
- Maç süresi (hedef 10–15 dk) ve maç sonunda "bir maç daha" deniyor mu?
- Taksit 12 kolay mı, zor mu? Hedef: turların yaklaşık yarısında taksit kıl payı ödenmeli.

## Uç durumlar (dijital sürüm için listeye girecek)

- **Fazla beyan** (beyan > gerçek): yasal mı? Arkadaşın yalanını örtmek ("kayıp jetonu" küçültmek) için kullanılabilir.
- **Yolsuzluk çetesi:** X yalan söyler, Y ona kefil olur, Z denetçi örtbas eder → Y bankadan +2, X tazminat alır. Tema olarak harika ama baskın strateji olmamalı.
- Aynı kişiye birden fazla kefil; kefilin kendisinin de yalancı olması.
- Denetçinin birden fazla kişiden rüşvet alıp yine de denetlemesi.
- Tazminatı ödeyecek parası olmayan denetçi.
- {5,5,5,5} setinde herkesin 5 demesi → kayıp 0, kesin dürüstlük. Bu set fazla mı "ölü"?
- Kalan borç son tura kapatılamayacak kadar büyürse geri kalan oyun anlamsızlaşır → erken iflas kuralı?
- Eşitlik (tie) kuralının yeterliliği.
- 3 veya 5 oyuncu: gelir toplamı, taksit ve denetçi sırası nasıl ölçeklenecek?
- **2 oyuncu olmaz:** toplam bilindiği için gelirin biri belli olunca diğeri de belli olur (toplam − kendi gelirin).
  İlk Steam testinde (2 kişi) görüldü. Oyunun alt sınırı en az 3 oyuncu.
- **Dijitale özgü:** oyuncu kopması, AFK, host'un çıkması, mikrofonu olmayan oyuncu.
