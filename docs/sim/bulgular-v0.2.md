# Simülasyon bulguları — kurallar v0.2

> Son güncelleme: 2026-10-21 · Ham sonuçlar: [sonuclar-v0.2.md](sonuclar-v0.2.md) (deney başına 2000 maç) · Önceki: [bulgular-v0.1.md](bulgular-v0.1.md)
> Kerem Gönç'ün kararını bekleyen maddeler **[KARAR]**, önerilerimiz **[ÖNERİ]** ile işaretli.

[Kurallar v0.2](../gdd/kurallar-v0.2.md), v0.1'in simülasyon önerileriyle güncellenmiş hali:
- denetçinin kartı açık;
- asgari katkı beyanın %60'ı;
- son tur dükkanı kapalı;
- fazla beyan da yalan.

Botlar v0.1'dekilerle aynı ([nasıl oynuyorlar](bulgular-v0.1.md#botlar-nasıl-oynuyor)). Aynı numaralı deney aynı soruyu soruyor, böylece iki sürüm karşılaştırılabiliyor.
Bu sayılar **kuralların neyi ödüllendirdiğini** gösterir, insanların nasıl oynayacağını değil.

## Kısaca

1. **v0.2 hedeflediği açıkları kapattı.** Masa çok daha sağlam, yalan "riskli ama cazip" kaldı.
2. **Yeni: Masadaki tek yalancı çok kötü sonuç alıyor.** Herkes dürüst oynamaya başlarsa oyun sıkıcılaşabilir. Kağıt prototipte izlenecek bir numaralı şey.
3. **Yeni: Yakalanan yalancının ödeyemediği ceza masaya kalıyor.** Öneri: senet. **[KARAR]**
4. **Yalancı masalarda ilk turun denetçisi avantajlı.** Öneri: her maçta ilk denetçi kaysın. **[ÖNERİ]**
5. **Taksit 12 biraz gevşedi ama değiştirmeye gerek yok.**

## 1. v0.2 ne değiştirdi

| Deney | Ölçü | v0.1 | v0.2 |
|---|---|---|---|
| E4 / E12 · 1 fırsatçı + 3 dürüst | Fırsatçı kazanma | %48 | %25 |
| E8 · 1 bedavacı + 3 dürüst | Bedavacı kazanma | %54 | %25 |
| E2 · 4 açgözlü | Masa kurtuldu | %10 | %69 |
| E6 · 2 açgözlü + 2 dürüst | Açgözlü / dürüst kazanma | %40 / %8 | %30 / %20 |
| E6 | Açgözlü / dürüst gece skoru | 3,01 / 2,31 | 2,60 / 2,89 |
| E7 · 2 kinci + 2 dürüst | Masa kurtuldu | %90 | %100 |
| E15 · 4 yolsuz | Masa kurtuldu | %0 | %45 |

- **Yalan riskli ama cazip:** Karışık masada açgözlü hâlâ daha sık kazanıyor. Ama ortalamada puan kaybediyor, çünkü kaybettiğinde büyük kaybediyor.
- **Kinci masayı batıramıyor:** Son turda katkıyı kesmeye çalıştığı maçların oranı %71. Ama asgariyi kesemediği için masa yine de kurtuluyor.
- **Örtbas hâlâ küçük bir etki:** Rüşvet veren ve alan yalancılar, rüşvetsiz açgözlülerden neredeyse hiç fazla kazanmıyor (E5'te %31, E6'da %30).
- **Fırsatçı artık dürüstle aynı oynuyor:** Kartı açık olduğu için kendi denetçi turunda da saklayamıyor. Bu yüzden v0.2 raporunda ayrı deneyi yok.

## 2. Masadaki tek yalancı çok kötü sonuç alıyor

| Gelirinin sakladığı payı (E19) | Kazanma v0.1 | Kazanma v0.2 | Yakalanma v0.2 |
|---|---|---|---|
| %25 | %23 | %14 | %68 |
| %50 (E3) | %9 | %6 | %85 |
| %75 | %4 | %1 | %95 |

Adil pay %25. v0.1'de küçük bir yalan neredeyse adil sonuç veriyordu; v0.2'de küçük yalan da kaybettiriyor.

- **Neden:** Asgari katkı beyana bağlı. Bu yüzden g jeton saklamak sadece 0,6g kazandırıyor (o kadar az ödüyorsun). Yakalanmak ise 1,4g kaybettiriyor (iade + ceza − kazanç).
  - Beklenen değer `g·(0,6 − 2p)`. Denetçi 3 kişiden rastgele seçse bile (p = 1/3) hafif zararlı.
  - Masada başka yalancılar da varsa denetçi hepsine bakamıyor, p düşüyor. E6'da açgözlünün daha sık kazanmasının nedeni bu.
- **Risk:** Oyuncular bunu öğrenirse herkes dürüst oynar ve kazananı gelir şansı belirler. Blöf oyununda bu kötü.
- **Ama botlar iyi dedektif:**
  - Tek yalancıyı %85 yakalıyorlar. Bir kez yakalanan sonra hep denetleniyor.
  - Öte yandan kayıp jeton sayısını kullanmıyorlar ve düşük beyan veren dürüstlerden de şüpheleniyorlar.
  - İnsanlar konuşarak denetçiyi başka yöne çevirebilir. Gerçek p'yi ancak kağıt prototip gösterir.
- **[KARAR] Kağıt prototipten sonra:**
  - Ne zaman: Masada kimse yalan söylemiyorsa ya da yalancılar hep yakalanıyorsa.
  - İlk denenecek ayar: Cezayı yarıya indirmek (fark / 2, yukarı yuvarlanır). O zaman `BD = g·(0,6 − 1,5p)` olur ve rastgele denetimde yalan hafif kârlı (+0,1g).
  - Şimdi değiştirmeyin; önce insanların ne kadar iyi yakaladığını görün.

## 3. Yakalanan yalancının ödeyemediği ceza masaya kalıyor

- **Neden ödeyemiyor:** Yakalanan yalancı çoğu zaman hem saklarını iade edip hem cezayı ödeyecek kadar paraya sahip değil; gelirinin bir kısmı zaten asgariye gitti.
  - Örnek: 8 gelen, 4 beyan eden yalancı. Asgari 3, cebinde 5 kalıyor. Yakalanınca 4 iade + 4 ceza = 8 borçlanıyor. Ödeyemediği 3 jeton ortak borca ekleniyor.
- **Ne kadar:** Karışık masada (E6) maç başına **5,4 jeton**, yani borcun ~%11'i. Tek yalancılı masada (E3) 4,6 jeton.
  - v0.1'de de aynıydı (E6'da 5,2); bu raporda ilk kez ölçüldü.
- **Sonuçları:**
  - Bu borcu dürüstler ödüyor; denetçi de cezasını alamıyor.
  - Yalancının cezası cebiyle sınırlı kalıyor. Kaybedecek bir şeyi olmayan büyük yalan söyleyebilir.
- **[KARAR] Öneri: senet.**
  - Ödenemeyen ceza silinmez, ortak borca da eklenmez. Yalancı onu sonraki turlarda, asgari katkısını ödedikten sonra kalan gelirinden öder.
  - Maç sonunda hâlâ ödenmemiş senet yalancının servetinden düşülür ve alacaklının servetine eklenir.
  - Kağıtta borç kağıdına "X → Y: 3" diye yazılır.
- **Not:** Senet yalanı daha da pahalı yapar. 2. maddeyle birlikte düşünülmeli; gerekirse senet ve yarım ceza birlikte denenebilir.

## 4. Yalancı masalarda ilk turun denetçisi avantajlı

- **Ölçüm:** Herkes açgözlüyken (E2) denetçi olduğu tura göre kazanma oranları:

  | Denetçi olduğu tur | 1. tur | 2. tur | 3. tur | 4. tur |
  |---|---|---|---|---|
  | Kazanma | %21 | %18 | %16 | %14 |

  - Masa %69 kurtulduğu için adil pay %17.
  - Dürüst masada fark yok denecek kadar az (%26 – %24, E1).
- **Muhtemel neden:** Denetçi kendi turunda yalan söyleyemiyor. Son turdaki yalanın sonrası yok: yakalansan bile sonraki turlarda şüpheli olmanın bedelini ödemiyorsun. Bu yüzden son turda dürüst kalmak zorunda olmak daha pahalı.
- **[ÖNERİ]** Gece boyunca her yeni maçta ilk denetçi bir kişi kaysın. Dijitalde ilk denetçi rastgele ya da sırayla seçilir.

## 5. Taksit 12 biraz gevşedi ama değiştirmeye gerek yok

- **Ölçüm:** Karışık masada turların ~%28'i kıl payı ya da eksik ödeniyor (v0.1: ~%43; hedef yaklaşık yarısı). Asgari katkı kasayı düzenli dolduruyor.
- **Taksiti artırmanın bedeli (E11):**

  | Taksit | Sıkışık turlar | Masa kurtuldu | Dürüst kazanma |
  |---|---|---|---|
  | 12 (şimdiki) | %28 | %100 | %20 |
  | 13 | %33 | %98 | %17 |
  | 14 | %39 | %94 | %13 |

  Borcu artırmak yalancıyı ödüllendiriyor, çünkü açığı dürüstler kapatıyor.
- **Öneri:** 12 kalsın; gerilimi kağıt prototipte hissedin.

## Diğer bulgular

- **Dürüst masa biraz fazla ödüyor.** Yukarı yuvarlama yüzünden asgariler her tur 12–14 ediyor, fazlası sonraki taksitten düşüyor.
  Sorun değil. Sadece dürüst masada gerilim az: E1'de 4 turun 1,5'i kıl payı, v0.1'de 3,6.
- **3 kişilik oyunda açık kart gelirleri ele veriyor.**
  - Denetçi olmayan iki kişi birbirinin gelirini kesin biliyor: toplam − kendi gelirin − denetçinin kartı.
  - **[KARAR]** 3 kişilik kurallar tasarlanırken başka bir çözüm gerekiyor (bkz. kurallar v0.2, "Uç durumlar").
- **Asgari katkı pazarlıktan önce ödenmeli.** **[ÖNERİ]** Kurallara böyle yazıldı.
  - Asgari, ek katkıyla birlikte pazarlıktan sonra ödenseydi şu boşluk olurdu: Oyuncu pazarlıkta cebini masa altından bir arkadaşına boşaltır, "param yok" der ve asgariyi ödemez.
  - Simülasyondaki botlar bu hileyi yapmadığı için sayılar değişmiyor.

## Kontrol

v0.1'deki önerili paket deneyleri (E17, E18), v0.2'deki aynı masalarla (E6, E2) birebir aynı sonucu veriyor. Kurallar koda doğru geçmiş.

## Sıradaki adımlar

1. **Kağıt prototip v0.2 ile.** Gözlem listesi kurallar v0.2'de. En önemlisi: yalan söyleyen çıkıyor mu, ve yakalanıyor mu?
2. **Kerem Gönç'ün kararları:**
   - Şimdi: 3 (senet), 4 (ilk denetçi kaysın) ve asgarinin zamanlaması.
   - Kağıt prototipten sonra: 2 (ceza miktarı).
3. **Simülatör:**
   - Senet ve yarım ceza varyantları.
   - Ardından masadakilere göre davranışını değiştiren (uyarlanan) botlar.

Simülatörü çalıştırmak:

```
godot --headless --path game --script res://sim/simulate.gd -- --matches=2000 --out=$(pwd)/docs/sim/sonuclar-v0.2.md
```
