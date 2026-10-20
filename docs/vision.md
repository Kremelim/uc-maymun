# Vizyon — Üç Maymun (çalışma adı)

> Durum: **Taslak v0.1** · Fikir: Kerem Gönç · Son güncelleme: 2026-10-20

## Tek cümle

Dört maymun, tek masa, ortak bir borç: **borcu birlikte ödeyin, cebe en çok parayı siz atın.**

İngilizce (mağaza için ilk deneme): *"Pay the debt together. Pocket the most alone."*

## Oyuncu fantezisi

Arkadaşının gözünün içine baka baka "bana bu el sadece 2 geldi" demek ve yırtmak. Ya da tam tersi: yalanı yakalamak.
Masanın altından anlaşmalar, kefil olup yanmak, rüşveti alıp göz yummak. "Param yok" diyen adamın
ertesi tur altın saatle masaya oturması.

## Tasarım ilkeleri

1. **Asıl oyun sohbet.** Mekanikler konuşma başlatmak için var. Kural yükü konuşmayı bastırmamalı;
   her fazda konuşulacak yeni bir şey (bir sayı, bir şüphe, bir teklif) ortaya çıkmalı.
2. **Her yalan bir iz bırakır.** Yalan söylemek mümkün ve kârlı ama asla izsiz değil:
   beyan toplamındaki açık, aksesuarlar, denetim, maç sonunda Hesap Günü.
3. **Herkes sona kadar oyunda.** Eleme yok. Gizli cepler sayesinde kimse kaybettiğinden emin olmamalı.
4. **Kısa maç, uzun kin.** Maç 10–15 dakika; kim kimi sattıysa maçlar arasında hatırlanır.

## Hedef kitle

- **Birincil:** Discord'da sesli oynayan 3–5 kişilik arkadaş grupları (Liar's Bar, Among Us, Lethal Company, R.E.P.O. oyuncuları).
- **Çarpan etkisi:** Yayıncılar ve izleyicileri. Oyunun her maçı klip üretmeli.
- **İkincil:** Açık lobide yabancılarla oynayanlar.

## Platform ve teknik çerçeve

- PC (Windows), yalnızca Steam.
- 3D, tek oda, tek masa.
- Online 4 oyuncu (öneri: kural matematiği 3–5 oyuncuya ölçeklenecek şekilde tasarlansın).
- Sesli sohbet merkezde ama mikrofonsuz oynanabilmeli (hızlı sohbet çarkı).
- Motor kararı: [ADR-0001](adr/0001-oyun-motoru.md).

## Emsaller

| Oyun | Ondan aldığımız | Nasıl ayrışıyoruz |
|---|---|---|
| **Liar's Bar** (Curve Animation, Ankara, 2024; Unity; tahmini 2,2–3,7 milyon kopya) | 4 kişilik masa, blöf, hayvan karakterler, yayıncı viralliği | Eleme ve Rus ruleti yok; ekonomi ve yolsuzluk teması; herkesin birlikte kaybedebildiği ortak borç |
| **Sheriff of Nottingham** (masa oyunu) | Denetim + rüşvet döngüsü | Gizli gelir + ortak borç; denetçi her tur değişiyor |
| **Among Us** | Sesli tartışma, sosyal çıkarım | Sabit hain rolü yok: herkes her tur hain olmayı seçebilir |
| **Coup / Secret Hitler** | Blöf, gizli bilgi | Sürekli bir ekonomi, görünür servet sinyali (aksesuarlar) |
| **Kamu malı oyunu** (deneysel ekonomi) | Ortak kasa ikilemi | Bunu bir parti oyununa çeviriyoruz |

**En büyük pazarlama riski:** "Liar's Bar klonu" algısı. Kapsül görseli ve fragmanın ilk 3 saniyesi farkı göstermeli.

## Kanca adayları (mağaza sayfası / fragman)

- "Param yok" diyen maymunun altın saatle masaya oturması.
- **Hesap Günü:** Maç sonunda herkesin gerçek geliri, her yalan, her örtbas ekrana dökülür.
- Rüşveti alan denetçi gözlerini kapatır. "Görmedim, duymadım, bilmiyorum" temasına doğrudan gönderme.

## Kapsam

**MVP / ilk demo (içinde):**
- 1 oda
- 4 maymun (kozmetik varyasyonlu)
- Çekirdek kurallar: gelir, beyan, katkı, denetim, rüşvet, kefil
- ~8 aksesuar
- Steam lobisi: arkadaş daveti + açık lobi listesi
- Sesli sohbet + hızlı sohbet çarkı
- Hesap Günü ekranı
- Türkçe + İngilizce

**Sonra (dışında):** yapay zekâ botlarla tek oyunculu mod, dereceli mod, mağaza/monetizasyon, ek odalar ve modlar, konsol.

## Riskler

| Risk | Önlem |
|---|---|
| Liar's Bar klonu algısı | Sanat yönü ve kanca farklı; eleme yok; ekonomi teması |
| Tam 4 arkadaş bulma bariyeri | 3–5 oyuncu desteği, açık lobiler, ileride "Guest Pass" seçeneği |
| Kaybettiğini düşünen oyuncunun masayı batırması | Gizli cepler + gece skoru (bkz. kurallar) |
| Çok oyunculu + ses teknik riski | 2 haftalık teknik spike (ADR-0001) |
| Yayıncı keşfine bağımlılık | Erken Steam sayfası, erken demo, Türk yayıncılarla ilişki |
| Tür hızlı dönüyor (lider oyun 3–9 ayda payının çoğunu kaybediyor) | Lansman sonrası düzenli içerik güncellemesi planı |
