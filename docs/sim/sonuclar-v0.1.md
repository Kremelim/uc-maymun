# Simülasyon sonuçları — kurallar v0.1

> Bu dosya `game/sim/simulate.gd` tarafından üretilir; elle düzenlemeyin.
> Deney başına 2000 maç, seed 20261020. Yorum: `docs/sim/bulgular-v0.1.md`.

Sütunlar: **Kazanma** = o tipteki bir oyuncunun maçı kazanma payı (4 kişide adil pay %25).
**Puan** = gece skoru ortalaması (5/3/2/1, masa batarsa 0). **Yalan/tur** = yalan söylediği turların oranı.
**Yakalanma** ve **örtbas** = yalanların ne kadarı raporlandı / rüşvetle kapatıldı.

## E1 — 4 dürüst

Herkes dürüstse masa kurtuluyor mu, kazananı ne belirliyor?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 3.61
- Servetin son tur alışverişinden gelen kısmı: 15%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| dürüst | 25% | 2.79 | 9.7 | 0% | — | — | — |

## E2 — 4 açgözlü

Herkes açgözlüyse (gelirinin yarısını saklıyor) masa batıyor mu?

- Masa kurtuldu: **10%**
- Taksitin eksik kaldığı tur: maç başına 3.14 · kıl payı (en fazla 2 artıkla) ödendiği tur: 0.83
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| açgözlü | 2% | 0.26 | 6.8 | 100% | 25% | 0% | — |

## E3 — 1 açgözlü + 3 dürüst

Dürüstlerin arasındaki tek açgözlü kazanıyor mu?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.42
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| açgözlü | 9% | 1.58 | 3.6 | 100% | 64% | 0% | — |
| dürüst | 30% | 3.16 | 9.1 | 0% | — | — | — |

## E4 — 1 fırsatçı + 3 dürüst

Sadece kendi denetçi turunda çalmak ("bedava yalan") ne kazandırıyor?

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.01 · kıl payı (en fazla 2 artıkla) ödendiği tur: 3.52
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| fırsatçı | 48% | 3.53 | 12.2 | 25% | 0% | 0% | — |
| dürüst | 17% | 2.52 | 8.9 | 0% | — | — | — |

## E5 — 2 yolsuz + 2 dürüst

Rüşvete açık denetçiler (örtbas) yalanı ne kadar kârlı yapıyor? Karşılaştırma: E6.

- Masa kurtuldu: **95%**
- Taksitin eksik kaldığı tur: maç başına 0.37 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.85
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| yolsuz | 40% | 3.04 | 10.0 | 100% | 37% | 8% | — |
| dürüst | 7% | 2.17 | 5.0 | 0% | — | — | — |

## E6 — 2 açgözlü + 2 dürüst

Aynı masa, ama yalancılar rüşvet vermiyor ve denetçiler almıyor.

- Masa kurtuldu: **96%**
- Taksitin eksik kaldığı tur: maç başına 0.28 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.43
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| açgözlü | 40% | 3.01 | 9.2 | 100% | 45% | 0% | — |
| dürüst | 8% | 2.31 | 5.2 | 0% | — | — | — |

## E7 — 2 kinci + 2 dürüst

Kaybedeceğini düşünen son turda masayı batırırsa? Karşılaştırma: E6.

- Masa kurtuldu: **90%**
- Taksitin eksik kaldığı tur: maç başına 0.36 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.75
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| kinci | 39% | 2.91 | 9.9 | 100% | 44% | 0% | 50% |
| dürüst | 6% | 2.08 | 5.4 | 0% | — | — | — |

## E8 — 1 bedavacı + 3 dürüst

Payının sadece bir kısmını ödeyen bir bedavacı kazanıyor mu?

- Masa kurtuldu: **87%**
- Taksitin eksik kaldığı tur: maç başına 0.60 · kıl payı (en fazla 2 artıkla) ödendiği tur: 3.40
- Servetin son tur alışverişinden gelen kısmı: 14%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| bedavacı | 54% | 3.46 | 14.0 | 0% | — | — | — |
| dürüst | 11% | 2.06 | 8.5 | 0% | — | — | — |

## E9 — 1 açgözlü + 3 dürüst

Son turdan sonra dükkan kapalı olursa? Karşılaştırma: E3.

Kural değişikliği: `{"last_round_shop":false}`

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.42
- Servetin son tur alışverişinden gelen kısmı: 0%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| açgözlü | 9% | 1.58 | 3.0 | 100% | 64% | 0% | — |
| dürüst | 30% | 3.16 | 7.7 | 0% | — | — | — |

## E10 — 1 açgözlü + 3 dürüst

Fazla beyan yalan sayılmazsa? (Botlar fazla beyan etmiyor; kontrol amaçlı.) Karşılaştırma: E3.

Kural değişikliği: `{"over_declaration_is_lie":false}`

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.42
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| açgözlü | 9% | 1.58 | 3.6 | 100% | 64% | 0% | — |
| dürüst | 30% | 3.16 | 9.1 | 0% | — | — | — |

## E12 — 1 fırsatçı + 3 dürüst

Öneri: denetçinin kartı açık. "Bedava yalan" turu kapanıyor mu? Karşılaştırma: E4.

Kural değişikliği: `{"auditor_card_open":true}`

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 3.61
- Servetin son tur alışverişinden gelen kısmı: 15%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| fırsatçı | 25% | 2.79 | 9.7 | 0% | — | — | — |
| dürüst | 25% | 2.79 | 9.7 | 0% | — | — | — |

## E13 — 1 bedavacı + 3 dürüst

Öneri: herkes beyanının en az yarısını kasaya koymak zorunda. Bedavacılık bitiyor mu? Karşılaştırma: E8.

Kural değişikliği: `{"min_contribution_ratio":0.5}`

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 4.00
- Servetin son tur alışverişinden gelen kısmı: 15%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| bedavacı | 40% | 3.33 | 11.6 | 0% | — | — | — |
| dürüst | 20% | 2.59 | 9.3 | 0% | — | — | — |

## E14 — 2 açgözlü + 2 dürüst

İki öneri birlikte, karışık masa. Karşılaştırma: E6.

Kural değişikliği: `{"auditor_card_open":true,"min_contribution_ratio":0.5}`

- Masa kurtuldu: **99%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.21
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| açgözlü | 29% | 2.58 | 7.0 | 75% | 57% | 0% | — |
| dürüst | 20% | 2.88 | 7.3 | 0% | — | — | — |

## E15 — 4 yolsuz

Herkes rüşvete açıksa örtbas ekonomisi ne kadar büyüyor? Karşılaştırma: E2.

- Masa kurtuldu: **0%**
- Taksitin eksik kaldığı tur: maç başına 3.44 · kıl payı (en fazla 2 artıkla) ödendiği tur: 0.55
- Servetin son tur alışverişinden gelen kısmı: 16%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| yolsuz | 0% | 0.01 | 7.2 | 100% | 20% | 5% | — |

## E16 — 1 bedavacı + 3 dürüst

Asgari katkı adil paya eşit: taksit / gelir toplamı = 12 / 20 = beyanın %60'ı. Karşılaştırma: E8, E13.

Kural değişikliği: `{"min_contribution_ratio":0.6}`

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.00 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.50
- Servetin son tur alışverişinden gelen kısmı: 15%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| bedavacı | 25% | 2.78 | 8.4 | 0% | — | — | — |
| dürüst | 25% | 2.79 | 8.4 | 0% | — | — | — |

## E17 — 2 açgözlü + 2 dürüst

Önerilen paket: kart açık + asgari katkı %60 + son tur dükkanı kapalı, karışık masa. Karşılaştırma: E6, E14.

Kural değişikliği: `{"auditor_card_open":true,"last_round_shop":false,"min_contribution_ratio":0.6}`

- Masa kurtuldu: **100%**
- Taksitin eksik kaldığı tur: maç başına 0.04 · kıl payı (en fazla 2 artıkla) ödendiği tur: 1.09
- Servetin son tur alışverişinden gelen kısmı: 0%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| açgözlü | 30% | 2.60 | 5.6 | 75% | 57% | 0% | — |
| dürüst | 20% | 2.89 | 5.8 | 0% | — | — | — |

## E18 — 4 açgözlü

Önerilen paket, herkes açgözlü. Karşılaştırma: E2.

Kural değişikliği: `{"auditor_card_open":true,"last_round_shop":false,"min_contribution_ratio":0.6}`

- Masa kurtuldu: **69%**
- Taksitin eksik kaldığı tur: maç başına 0.76 · kıl payı (en fazla 2 artıkla) ödendiği tur: 2.65
- Servetin son tur alışverişinden gelen kısmı: 0%

| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |
|---|---|---|---|---|---|---|---|
| açgözlü | 17% | 1.91 | 5.8 | 75% | 33% | 0% | — |

## E11 — Taksit taraması: 2 açgözlü + 2 dürüst

Borç ne kadar sıkı olmalı? Hedef (kurallar v0.1): turların yaklaşık yarısında taksit kıl payı ödensin.
Eksik ve kıl payı sütunları maç başına tur sayısıdır (4 turun kaçı).

| Tur başı taksit | Toplam borç | Masa kurtuldu | Eksik kalan tur | Kıl payı ödenen tur | Açgözlü kazanma | Dürüst kazanma |
|---|---|---|---|---|---|---|
| 8 | 32 | 100% | 0.03 | 1.11 | 28% | 22% |
| 9 | 36 | 100% | 0.07 | 1.21 | 31% | 19% |
| 10 | 40 | 99% | 0.10 | 1.29 | 34% | 15% |
| 11 | 44 | 98% | 0.17 | 1.39 | 38% | 11% |
| 12 | 48 | 96% | 0.28 | 1.43 | 40% | 8% |
| 13 | 52 | 90% | 0.40 | 1.61 | 40% | 5% |
| 14 | 56 | 75% | 0.82 | 1.83 | 33% | 4% |
| 15 | 60 | 48% | 1.47 | 1.75 | 21% | 3% |
| 16 | 64 | 18% | 2.49 | 1.30 | 8% | 2% |

