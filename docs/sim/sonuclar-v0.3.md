# Simülasyon sonuçları — kurallar v0.3

> Bu dosya `game/sim/simulate.gd` tarafından üretilir; elle düzenlemeyin.
> Deney başına 2000 maç, seed 20261020. Yorum: `docs/sim/bulgular-v0.3.md`.
> Deney numaraları önceki raporlardaki aynı soruyu sorar; anlamı kalmayanlar çıkarıldı.

Sütunlar: **Kazanma** = o tipteki bir oyuncunun maçı kazanma payı (4 kişide adil pay %25).
**Puan** = gece skoru ortalaması (5/3/2/1, masa batarsa 0). **Yalan/tur** = yalan söylediği turların oranı.
**Yakalanma** ve **örtbas** = yalanların ne kadarı raporlandı / rüşvetle kapatıldı.

## E1 — 4 dürüst

Herkes dürüstse masa kurtuluyor mu, kazananı ne belirliyor?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.38
- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına 0.23 jeton
- Denetçi olduğu tura göre kazanma / puan: 1. tur 25% / 2.82 · 2. tur 26% / 2.80 · 3. tur 24% / 2.76 · 4. tur 25% / 2.78

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| dürüst | 25% | 2.79 | 7.1 | 0% | — | — | — |

## E2 — 4 açgözlü

Herkes açgözlüyse (gelirinin yarısını saklıyor) masa batıyor mu?

- Masa kurtuldu: **95%**
- Taksitin eksik kaldığı tur: maç başına 0.53 · kıl payı (en fazla 2 artıkla) ödendiği tur: 2.53
- Ödenemeyip ortak borca eklenen: maç başına 1.23 jeton
- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına 5.51 jeton
- Denetçi olduğu tura göre kazanma / puan: 1. tur 25% / 2.96 · 2. tur 25% / 2.70 · 3. tur 22% / 2.44 · 4. tur 23% / 2.41

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| açgözlü | 24% | 2.63 | 7.0 | 75% | 33% | 0% | — |

## E3 — 1 açgözlü + 3 dürüst

Dürüstlerin arasındaki tek açgözlü kazanıyor mu?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 0.85
- Ödenemeyip ortak borca eklenen: maç başına 0.19 jeton
- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına 4.42 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| açgözlü | 6% | 1.33 | -2.7 | 75% | 85% | 0% | — |
| dürüst | 31% | 3.24 | 8.8 | 0% | — | — | — |

## E5 — 2 yolsuz + 2 dürüst

Rüşvete açık denetçiler (örtbas) yalanı ne kadar kârlı yapıyor? Karşılaştırma: E6.

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 0.91
- Ödenemeyip ortak borca eklenen: maç başına 0.32 jeton
- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına 4.61 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| yolsuz | 29% | 2.53 | 4.9 | 75% | 48% | 9% | — |
| dürüst | 21% | 2.98 | 8.1 | 0% | — | — | — |

## E6 — 2 açgözlü + 2 dürüst

İki açgözlü, iki dürüst: karışık masa.

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 0.73
- Ödenemeyip ortak borca eklenen: maç başına 0.33 jeton
- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına 4.89 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| açgözlü | 27% | 2.45 | 4.2 | 75% | 57% | 0% | — |
| dürüst | 23% | 3.06 | 8.1 | 0% | — | — | — |

## E7 — 2 kinci + 2 dürüst

Kaybedeceğini düşünen son turda katkıyı keserse? Karşılaştırma: E6.

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 0.74
- Ödenemeyip ortak borca eklenen: maç başına 0.30 jeton
- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına 4.88 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| kinci | 27% | 2.46 | 4.3 | 75% | 57% | 0% | 74% |
| dürüst | 23% | 3.06 | 8.1 | 0% | — | — | — |

## E8 — 1 bedavacı + 3 dürüst

Payının sadece bir kısmını ödemek isteyen bedavacı kazanıyor mu?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.38
- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına 0.23 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| bedavacı | 25% | 2.78 | 7.1 | 0% | — | — | — |
| dürüst | 25% | 2.79 | 7.1 | 0% | — | — | — |

## E15 — 4 yolsuz

Herkes rüşvete açıksa örtbas ekonomisi ne kadar büyüyor? Karşılaştırma: E2.

- Masa kurtuldu: **72%**
- Taksitin eksik kaldığı tur: maç başına 0.97 · kıl payı (en fazla 2 artıkla) ödendiği tur: 2.52
- Ödenemeyip ortak borca eklenen: maç başına 1.22 jeton
- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına 5.13 jeton
- Denetçi olduğu tura göre kazanma / puan: 1. tur 17% / 2.16 · 2. tur 18% / 2.01 · 3. tur 19% / 1.92 · 4. tur 18% / 1.81

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| yolsuz | 18% | 1.97 | 7.4 | 75% | 26% | 7% | — |

## E20 — 2 açgözlü + 2 dürüst

Senet olmasaydı (ödenemeyen ceza ortak borca eklenseydi)? Karşılaştırma: E6.

Kural değişikliği: `{"unpaid_becomes_iou":false}`

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.09
- Ödenemeyip ortak borca eklenen: maç başına 5.39 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| açgözlü | 30% | 2.60 | 5.6 | 75% | 57% | 0% | — |
| dürüst | 20% | 2.89 | 5.8 | 0% | — | — | — |

## E21 — 4 açgözlü

Senet olmasaydı, herkes açgözlüyken? Karşılaştırma: E2.

Kural değişikliği: `{"unpaid_becomes_iou":false}`

- Masa kurtuldu: **69%**
- Taksitin eksik kaldığı tur: maç başına 0.76 · kıl payı (en fazla 2 artıkla) ödendiği tur: 2.65
- Ödenemeyip ortak borca eklenen: maç başına 7.68 jeton
- Denetçi olduğu tura göre kazanma / puan: 1. tur 21% / 2.19 · 2. tur 18% / 1.93 · 3. tur 16% / 1.70 · 4. tur 14% / 1.80

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| açgözlü | 17% | 1.91 | 5.8 | 75% | 33% | 0% | — |

## E11 — Taksit taraması: 2 açgözlü + 2 dürüst

Borç ne kadar sıkı olmalı? Hedef: turların yaklaşık yarısında taksit kıl payı ödensin.
Eksik ve kıl payı sütunları maç başına tur sayısıdır (4 turun kaçı).

| Tur başı taksit | Toplam borç | Masa kurtuldu | Eksik kalan tur | Kıl payı ödenen tur | Açgözlü kazanma | Dürüst kazanma |
|---|---|---|---|---|---|---|
| 8 | 32 | 100% | 0.00 | 0.10 | 26% | 24% |
| 9 | 36 | 100% | 0.01 | 0.23 | 26% | 24% |
| 10 | 40 | 100% | 0.02 | 0.42 | 26% | 24% |
| 11 | 44 | 100% | 0.02 | 0.60 | 27% | 23% |
| 12 | 48 | 100% | 0.04 | 0.73 | 27% | 23% |
| 13 | 52 | 100% | 0.05 | 0.97 | 29% | 21% |
| 14 | 56 | 100% | 0.07 | 1.24 | 31% | 19% |
| 15 | 60 | 100% | 0.10 | 1.51 | 33% | 17% |
| 16 | 64 | 98% | 0.32 | 1.65 | 34% | 15% |

## E19 — Yalan büyüklüğü: 1 açgözlü + 3 dürüst

Ne kadar saklamak kârlı? Açgözlü her tur gelirinin bu kadarını saklıyor (denetçiyken kartı açık, saklayamıyor).

| Sakladığı pay | Masa kurtuldu | Açgözlü kazanma | Açgözlü puan | Yakalanma | Dürüst kazanma | Dürüst puan |
|---|---|---|---|---|---|---|
| 25% | 100% | 14% | 1.81 | 68% | 29% | 3.09 |
| 50% | 100% | 6% | 1.33 | 85% | 31% | 3.24 |
| 75% | 100% | 1% | 1.06 | 94% | 33% | 3.33 |
| 100% | 100% | 0% | 1.00 | 100% | 33% | 3.35 |

## E22 — Ceza miktarı

Ceza küçülürse tek başına yalan söylemek kârlı hale geliyor mu? Ceza = fark × çarpan, yukarı yuvarlanır.
Hücreler: kazanma / gece skoru. Karışık masa: 2 açgözlü + 2 dürüst.

| Ceza çarpanı | 1 açgözlü (%25 saklıyor) + 3 dürüst | 1 açgözlü (%50) + 3 dürüst | Karışık masa: açgözlü | Karışık masa: dürüst |
|---|---|---|---|---|
| 1.00 | 14% / 1.81 | 6% / 1.33 | 27% / 2.45 | 23% / 3.06 |
| 0.75 | 14% / 1.81 | 6% / 1.33 | 27% / 2.46 | 23% / 3.05 |
| 0.50 | 14% / 1.85 | 7% / 1.39 | 29% / 2.53 | 21% / 2.98 |

## E23 — Gece: 4 açgözlü

Aynı dört oyuncu bir gece boyunca oynuyor; geceyi en çok toplam puanı alan kazanıyor (eşitlikte paylaşılır).
Koltuk A, gecenin ilk maçında ilk denetçi olan; B, C, D onu izliyor. Adil pay %25.

| İlk denetçi | Maç | A | B | C | D | En iyi − en kötü |
|---|---|---|---|---|---|---|
| her maç A | 3 | 35% | 27% | 20% | 18% | 18% |
| her maç bir kayıyor | 3 | 26% | 27% | 25% | 21% | 6% |
| her maç bir kayıyor | 4 | 24% | 26% | 25% | 25% | 2% |

## E24 — Borç seçenekleri

Taksit artarsa asgari oran da artmalı (taksit / gelir toplamı), yoksa az ödeyen kazanır.
Herkes açgözlüyken masa ne sıklıkla batıyor, karışık masada (2 açgözlü + 2 dürüst) denge nasıl?
Sıkışık tur = eksik ya da kıl payı ödenen. Hücreler: kazanma / gece skoru.

| Taksit / asgari | Toplam borç | 4 açgözlü: masa kurtuldu | Karışık: sıkışık tur | Karışık: açgözlü | Karışık: dürüst | 1 bedavacı + 3 dürüst: bedavacı |
|---|---|---|---|---|---|---|
| 12 / 60% | 48 | 95% | 19% | 27% / 2.45 | 23% / 3.06 | 25% / 2.78 |
| 13 / 65% | 52 | 90% | 21% | 31% / 2.56 | 19% / 2.95 | 25% / 2.77 |
| 14 / 70% | 56 | 79% | 25% | 32% / 2.60 | 18% / 2.91 | 26% / 2.79 |
| 15 / 75% | 60 | 60% | 32% | 35% / 2.64 | 15% / 2.85 | 25% / 2.79 |

