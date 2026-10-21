# Simülasyon sonuçları — kurallar v0.2

> Bu dosya `game/sim/simulate.gd` tarafından üretilir; elle düzenlemeyin.
> Deney başına 2000 maç, seed 20261020. Yorum: `docs/sim/bulgular-v0.2.md`.
> Deney numaraları v0.1 raporundaki aynı soruyu sorar; v0.2'de anlamı kalmayanlar çıkarıldı.

Sütunlar: **Kazanma** = o tipteki bir oyuncunun maçı kazanma payı (4 kişide adil pay %25).
**Puan** = gece skoru ortalaması (5/3/2/1, masa batarsa 0). **Yalan/tur** = yalan söylediği turların oranı.
**Yakalanma** ve **örtbas** = yalanların ne kadarı raporlandı / rüşvetle kapatıldı.

## E1 — 4 dürüst

Herkes dürüstse masa kurtuluyor mu, kazananı ne belirliyor?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.50
- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına 0.23 jeton
- Denetçi olduğu tura göre kazanma: 1. tur 26% · 2. tur 26% · 3. tur 24% · 4. tur 24%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| dürüst | 25% | 2.79 | 7.1 | 0% | — | — | — |

## E2 — 4 açgözlü

Herkes açgözlüyse (gelirinin yarısını saklıyor) masa batıyor mu?

- Masa kurtuldu: **69%**
- Taksitin eksik kaldığı tur: maç başına 0.76 · kıl payı (en fazla 2 artıkla) ödendiği tur: 2.65
- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına 7.68 jeton
- Denetçi olduğu tura göre kazanma: 1. tur 21% · 2. tur 18% · 3. tur 16% · 4. tur 14%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| açgözlü | 17% | 1.91 | 5.8 | 75% | 33% | 0% | — |

## E3 — 1 açgözlü + 3 dürüst

Dürüstlerin arasındaki tek açgözlü kazanıyor mu?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 0.94
- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına 4.64 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| açgözlü | 6% | 1.33 | 1.6 | 75% | 85% | 0% | — |
| dürüst | 31% | 3.24 | 7.2 | 0% | — | — | — |

## E5 — 2 yolsuz + 2 dürüst

Rüşvete açık denetçiler (örtbas) yalanı ne kadar kârlı yapıyor? Karşılaştırma: E6.

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.49
- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına 5.17 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| yolsuz | 31% | 2.69 | 6.2 | 75% | 49% | 9% | — |
| dürüst | 18% | 2.80 | 5.9 | 0% | — | — | — |

## E6 — 2 açgözlü + 2 dürüst

İki açgözlü, iki dürüst: karışık masa.

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.09
- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına 5.39 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| açgözlü | 30% | 2.60 | 5.6 | 75% | 57% | 0% | — |
| dürüst | 20% | 2.89 | 5.8 | 0% | — | — | — |

## E7 — 2 kinci + 2 dürüst

Kaybedeceğini düşünen son turda katkıyı keserse? Karşılaştırma: E6.

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.11
- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına 5.33 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| kinci | 31% | 2.63 | 5.7 | 75% | 57% | 0% | 71% |
| dürüst | 19% | 2.88 | 5.9 | 0% | — | — | — |

## E8 — 1 bedavacı + 3 dürüst

Payının sadece bir kısmını ödemek isteyen bedavacı kazanıyor mu?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.50
- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına 0.23 jeton

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| bedavacı | 25% | 2.78 | 7.1 | 0% | — | — | — |
| dürüst | 25% | 2.79 | 7.1 | 0% | — | — | — |

## E15 — 4 yolsuz

Herkes rüşvete açıksa örtbas ekonomisi ne kadar büyüyor? Karşılaştırma: E2.

- Masa kurtuldu: **45%**
- Taksitin eksik kaldığı tur: maç başına 1.21 · kıl payı (en fazla 2 artıkla) ödendiği tur: 2.44
- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına 7.34 jeton
- Denetçi olduğu tura göre kazanma: 1. tur 13% · 2. tur 11% · 3. tur 11% · 4. tur 11%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |
|---|---|---|---|---|---|---|---|
| yolsuz | 11% | 1.25 | 6.2 | 75% | 28% | 6% | — |

## E11 — Taksit taraması: 2 açgözlü + 2 dürüst

Borç ne kadar sıkı olmalı? Hedef: turların yaklaşık yarısında taksit kıl payı ödensin.
Eksik ve kıl payı sütunları maç başına tur sayısıdır (4 turun kaçı).

| Tur başı taksit | Toplam borç | Masa kurtuldu | Eksik kalan tur | Kıl payı ödenen tur | Açgözlü kazanma | Dürüst kazanma |
|---|---|---|---|---|---|---|
| 8 | 32 | 100% | 0.00 | 0.10 | 27% | 23% |
| 9 | 36 | 100% | 0.01 | 0.24 | 27% | 23% |
| 10 | 40 | 100% | 0.02 | 0.48 | 27% | 23% |
| 11 | 44 | 100% | 0.02 | 0.80 | 29% | 21% |
| 12 | 48 | 100% | 0.04 | 1.09 | 30% | 20% |
| 13 | 52 | 98% | 0.06 | 1.25 | 32% | 17% |
| 14 | 56 | 94% | 0.09 | 1.48 | 35% | 13% |
| 15 | 60 | 84% | 0.17 | 1.74 | 33% | 9% |
| 16 | 64 | 68% | 0.63 | 1.97 | 29% | 6% |

## E19 — Yalan büyüklüğü: 1 açgözlü + 3 dürüst

Ne kadar saklamak kârlı? Açgözlü her tur gelirinin bu kadarını saklıyor (denetçiyken kartı açık, saklayamıyor).

| Sakladığı pay | Masa kurtuldu | Açgözlü kazanma | Açgözlü puan | Yakalanma | Dürüst kazanma | Dürüst puan |
|---|---|---|---|---|---|---|
| 25% | 100% | 14% | 1.82 | 68% | 29% | 3.08 |
| 50% | 100% | 6% | 1.33 | 85% | 31% | 3.24 |
| 75% | 100% | 1% | 1.07 | 95% | 33% | 3.33 |
| 100% | 78% | 0% | 0.82 | 100% | 26% | 2.60 |

