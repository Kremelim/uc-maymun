# Simülasyon bulguları — kurallar v0.3

> Son güncelleme: 2026-10-21 · Ham sonuçlar: [sonuclar-v0.3.md](sonuclar-v0.3.md) (deney başına 2000 maç ya da gece) · Önceki: [bulgular-v0.2.md](bulgular-v0.2.md)
> Kerem Gönç'ün kararını bekleyen maddeler **[KARAR]** ile işaretli.

v0.2'nin üç önerisi koda ayar olarak eklendi ve ölçüldü: senet, yarım ceza, kayan ilk denetçi.
İkisi [kurallar v0.3'e](../gdd/kurallar-v0.3.md) girdi, biri girmedi.
Botlar önceki raporlardakiyle aynı; aynı numaralı deney aynı soruyu soruyor.
Bu sayılar **kuralların neyi ödüllendirdiğini** gösterir, insanların nasıl oynayacağını değil.

## Kısaca

1. **Senet girdi.** Masa artık yalancının ödeyemediği cezayı ödemiyor. Dürüst biraz kazandı.
   - Yan etki: Herkes açgözlüyken bile masa %95 kurtuluyor (v0.2: %69); ortak borcun tehdidi zayıfladı.
2. **Yarım ceza girmedi.** Tek yalancının sonucunu hiç değiştirmiyor. Sorun cezanın büyüklüğü değil, yakalanma oranı.
3. **Kayan ilk denetçi girdi, gece 4 maç oldu.** 3 maçta bile ilk denetçi kayınca gece dengeleniyor; 4 maçta tam adil.
4. **Borç 12 kaldı.** Masa kağıt prototipte hiç batmıyorsa ya da kimse yalan söylemiyorsa ilk denenecek ayar 14 / %70. **[KARAR]**

## 1. Senet

**Kural:** Bir oyuncuya ödenemeyen ceza ya da tazminat ortak borca eklenmez. Senet olur ve Hesap Günü'nde borçlunun servetinden düşülüp alacaklınınkine eklenir.

| Ölçü | v0.2 (senetsiz: E20, E21) | v0.3 (E6, E2) |
|---|---|---|
| Karışık masa: ortak borca eklenen, maç başına | 5,4 jeton | 0,3 jeton |
| Karışık masa: açgözlü / dürüst kazanma | %30 / %20 | %27 / %23 |
| Karışık masa: açgözlü / dürüst gece skoru | 2,60 / 2,89 | 2,45 / 3,06 |
| 4 açgözlü: masa kurtuldu | %69 | %95 |
| 4 yolsuz: masa kurtuldu (E15) | %45 | %72 |

- **İstediğimiz oldu:** Yalancının cezası artık cebiyle sınırlı değil. Ödenemeyen kısım maç başına ~5 jeton senede dönüşüyor ve sonunda yalancıdan alınıyor.
  - Dürüstler bunu ödemekten kurtuldu; denetçi de cezasını sonunda alıyor.
  - Tek yalancı sonunda ortalama eksi servetle bitiriyor (E3'te −2,7).
- **Yalan hâlâ "riskli ama cazip":** Karışık masada açgözlü daha sık kazanıyor (%27'ye %23). Ama ortalamada belirgin şekilde daha az puan alıyor (2,45'e 3,06).
- **Yan etki:** v0.2'de yalancı masaları batıran şeyin büyük kısmı, yalancıların ödeyemediği cezalarmış. Bunlar kalkınca herkes gelirinin yarısını saklasa da masa çoğunlukla kurtuluyor.
  Ortak borcun "herkes açgözlü olursa herkes kaybeder" tehdidi zayıfladı. Bkz. 4. madde.

## 2. Yarım ceza: işe yaramıyor

| Ceza (E22) | 1 açgözlü (%25 saklıyor) | 1 açgözlü (%50 saklıyor) | Karışık masa: açgözlü / dürüst |
|---|---|---|---|
| Tam (fark × 1) | %14 | %6 | %27 / %23 |
| fark × 0,75 | %14 | %6 | %27 / %23 |
| Yarım (fark × 0,5) | %14 | %7 | %29 / %21 |

- **Tek yalancının sonucu değişmiyor:** Botlar tek yalancıyı %68–85 oranında yakalıyor. Yakalanınca saklanan jetonlar geri gidiyor, ceza ne olursa olsun kazanma şansı bitiyor.
- **Yarım ceza nereye yarıyor:** Sadece zaten yalancı olan karışık masada yalancıya biraz yarıyor. İstediğimiz bu değildi.
- **Sonuç:** Ceza tam kaldı. Tek başına yalanın kârlı olup olmadığını insanların ne kadar iyi yakaladığı belirleyecek; bunu ancak kağıt prototip gösterir.

## 3. Kayan ilk denetçi ve 4 maçlık gece

Tek maçta, herkes açgözlüyken (E2), denetçi olunan tura göre:

| Denetçi olduğu tur | 1. | 2. | 3. | 4. |
|---|---|---|---|---|
| Kazanma | %25 | %25 | %22 | %23 |
| Ortalama puan | 2,96 | 2,70 | 2,44 | 2,41 |

- **Ölçüm:**
  - Kazanma oranları neredeyse eşit; asıl fark sonuncu olmakta.
  - İlk turun denetçisi maçların %5'inde sonuncu oluyor, son turunki %37'sinde.
  - Dürüst masada fark yok.
- **Neden: "bir kez yakalanan hep denetlenir."**
  - 1. turda yakalanan oyuncu maç boyunca hedef oluyor ve tekrar tekrar yakalanıyor.
  - 1. turun denetçisi o tur denetlenemediği için bu kartopundan kurtuluyor.
  - Aksesuarlar etkilemiyor; botlar aksesuar almasa da sonuç aynı.
- **Gece boyunca (E23):** Aynı 4 açgözlü bir gece oynuyor. Koltuk A ilk maçın ilk denetçisi.

  | İlk denetçi | Maç | A | B | C | D | En iyi − en kötü (yüzde puanı) |
  |---|---|---|---|---|---|---|
  | Her maç A | 3 | %35 | %27 | %20 | %18 | 18 |
  | Her maç bir kayıyor | 3 | %26 | %27 | %25 | %21 | 6 |
  | **Her maç bir kayıyor** | **4** | %24 | %26 | %25 | %25 | 2 (gürültü) |

  4 oyuncu ve 3 maçla kaydırma tam olamıyor: D hiç ilk denetçi olmuyor. 4 maçta herkes her denetçi sırasını bir kez oynuyor.
- **v0.3:** Gece 4 maç, her maç ilk denetçi bir kişi kayıyor.
  - Gece 4 maç ~40–60 dakika. Uzun gelirse 3 maç + kura ile seçilen ilk denetçi de ortalamada adil, ama tek bir gecede değil.
  - Dijitalde tek maç oynanırsa ilk denetçi rastgele seçilmeli.

## 4. Borç: 12 kaldı, alternatif hazır

Senetten sonra borcu artırmak masanın tehdidini geri getirir. Ama taksitle birlikte asgari oran da artmalı (taksit / gelir toplamı). Yoksa az ödeyen yine kazanıyor: taksit 14, asgari %60'ta bedavacı %37 kazanıyor (keşif çalıştırması).

| Taksit / asgari (E24) | Toplam borç | 4 açgözlü: masa kurtuldu | Karışık: sıkışık tur | Karışık: açgözlü / dürüst | Bedavacı |
|---|---|---|---|---|---|
| **12 / %60 (v0.3)** | 48 | %95 | %19 | %27 / %23 | %25 |
| 13 / %65 | 52 | %90 | %21 | %31 / %19 | %25 |
| 14 / %70 | 56 | %79 | %25 | %32 / %18 | %26 |
| 15 / %75 | 60 | %60 | %32 | %35 / %15 | %25 |

- **14 / %70'in getirdikleri:**
  - Masanın tehdidi v0.2 seviyesine yakın (%79).
  - Yalan biraz daha cazip: asgari yükseldikçe saklamanın kazancı artıyor, `BD = g·(0,7 − 2p)`.
  - Karışık masadaki denge v0.2'ninkine dönüyor (%32 / %18, puan 2,60 / 2,91).
- **Bedeli:** Yeni sayılar (borç 56, asgari tablosu değişir). Dürüst oyuncunun kazanma payı da biraz düşüyor.
- **[KARAR] Kerem Gönç, kağıt prototipten sonra:** Masa hiç batmıyorsa ya da kimse yalan söylemiyorsa 14 / %70'e geçin. İkisi de yolundaysa 12 / %60 kalsın.

## Diğer bulgular

- **Rüşvet ve örtbas:** Hâlâ küçük bir etki. Yolsuz yalancılar (E5) %29, açgözlüler (E6) %27 kazanıyor.

## Kontrol

Bütün yeni ayarlar kapalıyken v0.2 raporu birebir aynı üretiliyor. E20 ve E21 de v0.2'deki E6 ve E2 ile birebir aynı. Yeni kurallar eskileri bozmadan eklendi.

## Sıradaki adımlar

1. **Kağıt prototip v0.3 ile.** Gözlem listesi kurallar v0.3'te. En önemli üç soru:
   - Yalan söyleyen çıkıyor mu, ve yakalanıyor mu?
   - Masa hiç batıyor mu?
   - Senet takibi kağıtta zor mu?
2. **Kerem Gönç'ün kararları:**
   - Şimdi: senet ve 4 maçlık gece.
   - Kağıt prototipten sonra: borç (12 / %60 ya da 14 / %70).
3. **Simülatör:** Masadakilere göre davranışını değiştiren (uyarlanan) botlar. Örneğin kimse yalan söylemiyorsa yalana başlayan, yakalanınca duran botlar.

Simülatörü çalıştırmak (~2,5 dakika):

```
godot --headless --path game --script res://sim/simulate.gd -- --matches=2000 --out=$(pwd)/docs/sim/sonuclar-v0.3.md
```
