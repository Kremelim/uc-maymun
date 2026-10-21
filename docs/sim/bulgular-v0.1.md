# Simülasyon bulguları — kurallar v0.1

> Son güncelleme: 2026-10-20 · Ham sonuçlar: [sonuclar-v0.1.md](sonuclar-v0.1.md) (deney başına 2000 maç)
> Kerem Gönç'ün kararını bekleyen maddeler **[KARAR]** ile işaretli.
>
> **Sonuç:** Üç öneri ve fazla beyan kuralı kabul edildi, [kurallar v0.2](../gdd/kurallar-v0.2.md) oldu. Yeni bulgular: [bulgular-v0.2.md](bulgular-v0.2.md).
> Bu raporu üreten simülatör sürümü `1b5964f` commit'inde (`git checkout 1b5964f` ile aynı sonuçlar tekrar üretilebilir).

Kurallar v0.1'in tamamı (gelir, beyan, kefil, masa altı, katkı, denetim, örtbas, taksit, haciz, aksesuar,
Hesap Günü, gece skoru) koda geçirildi. Farklı oyuncu tiplerini temsil eden botlarla on binlerce maç oynatıldı.
Bu sayılar **kuralların neyi ödüllendirdiğini** gösterir, insanların nasıl oynayacağını değil (bkz. "Sınırlar").

## Kısaca

1. **En büyük açık: denetçinin "bedava yalan" turu.**
   - Sorun: Denetçi o tur denetlenemediği için, sadece kendi denetçi turunda gelirinin tamamını saklayan oyuncu maçların **%48'ini** kazanıyor (adil pay %25; E4).
   - Öneri: **Denetçinin gelir kartı herkese açık olsun.** Fırsatçının kazanma payı tam **%25'e** iniyor (E12). **[KARAR]**
2. **Kurallar katkıyı hiç denetlemiyor.**
   - Sorun: Gelirini doğru beyan edip kasaya payından az koyan oyuncu hiçbir risk almadan **%54** kazanıyor (E8).
   - Öneri: **Herkes beyanının en az %60'ını kasaya koysun.** %60 = taksit / gelir toplamı (12 / 20), yani tam adil pay. Bedavacı **%25'e** iniyor (E16).
   - %50 yetmiyor, bedavacı yine %40 kazanıyor (E13). **[KARAR]**
3. **Son tur alışverişi bir karar değil, bir hediye.**
   - Sorun: Son denetimden sonra kimseyi bekleyen bir risk kalmadığı için herkes bütün parasını aksesuara yatırıp %25 bonusu topluyor. Bu, servetin ~%16'sı ediyor ve sıralamayı değiştirmiyor (E9 ile E3 aynı).
   - Öneri: **Son denetimden sonra dükkan kapalı.** Aksesuarın anlamı "zenginliğini göstermenin riski"; son turda o risk yok. **[KARAR]**
4. **Borç (48 = 4 × 12) iyi bir yerde.**
   - Karışık masada (2 açgözlü + 2 dürüst) masa %96 kurtuluyor ve turların ~%43'ü kıl payı ya da eksik ödeniyor.
   - Kurallardaki "turların yaklaşık yarısında kıl payı" hedefine yakın. 14'ün üstünde masa sık batıyor (E11). Değiştirmeye gerek yok.
5. **Önerilen paketle (1 + 2 + 3) denge istediğimiz gibi (E17).**
   - Yalan hâlâ cazip: açgözlü maçların %30'unu, dürüst %20'sini kazanıyor.
   - Ama ortalamada yalan puan kaybettiriyor (gece skoru 2,60'a 2,89). Yalancılar kaybettiklerinde büyük kaybediyor.
   - Yani "riskli ama cazip". Önceden (E6) yalan hem daha sık kazanıyor hem daha çok puan getiriyordu.

## Diğer bulgular

- **Tek yalancı yakalanıyor, iki yalancı şüpheyi bölüyor.**
  - Dürüstlerin arasındaki tek açgözlü yalanlarının %64'ünde yakalanıp %9 kazanıyor (E3).
  - İki açgözlü olunca yakalanma %45'e düşüyor, kazanma %40'a çıkıyor (E6).
  - Masada kaç yalancı olduğu oyunun karakterini değiştiriyor; tam olarak sohbetin konusu olması gereken şey.
- **Herkes açgözlüyse masa %90 batıyor** (E2). Önerilen paketle bu %31'e iniyor (E18): asgari katkı, beyan edilen kadarını kasaya getiriyor.
- **Kinci (son turda kaybedeceğini düşününce masayı batıran):**
  - Masanın kurtulma oranını %96'dan %90'a düşürüyor (E7).
  - Gece skoru batırmayı cezalandırıyor: kinci ortalama 2,91 puan alıyor, batırmayan açgözlü 3,01. Etki küçük ama doğru yönde.
  - Asıl koruma gizli cepler: botlar kimin önde olduğunu tahmin edemiyor ve kincilerin yarısı hiç batırmıyor.
- **Örtbas ve rüşvet bu botlarla nadir** (yalanların %5–8'i; E5, E15).
  - Ama herkes rüşvete açıkken masa **hiç** kurtulmuyor (E15): örtbas edilen jetonlar kasaya hiç girmiyor.
  - Botların pazarlığı çok basit; insanlar çok daha fazla örtbas yapacaktır. **Kağıt prototipte gözlenmesi gereken bir numaralı şey.**
- **Fazla beyan ölçülemedi:** botlar fazla beyan etmiyor. E10'un E3 ile birebir aynı çıkması bunu doğruluyor.
  Arkadaşın yalanını örtmek için fazla beyan etmek insan işi; kağıt prototipte gözlenecek.

## Kural motorunun açık noktaları nasıl çözdüğü

Kurallar v0.1 bazı durumları tanımlamıyordu. Motor şöyle yapıyor; hepsi **[KARAR]** (Kerem Gönç onaylayana kadar böyle kalır):

| Durum | Motorun yaptığı |
|---|---|
| Yalanın tanımı | Beyan ≠ gerçek gelir. Fazla beyan da yalan sayılıyor (Kerem Ataç kabul etti). Fazla beyan yakalanınca iade yok, sadece fark kadar ceza. Ayarla kapatılabilir. |
| Birden fazla kefil | Cezanın yarısını (aşağı yuvarlanır) kefiller eşit böler, kalanını yalancı öder. Temiz çıkarsa her kefil +2 alır. |
| **Denetçi kefil olursa** | **Olamaz.** Yoksa kendi hedefine kefil olup "temiz" diyerek bankadan bedava jeton alır. Denetçiye kefil olmak da yasak (denetçi denetlenemez, anlamsız). |
| Haciz | Aksesuarlar en ucuzdan başlayarak alış fiyatından satılır; artanı nakit olarak geri verilir. |
| Ödenemeyen borçlar | Yakalanan yalancının ödeyemediği ceza ve parasız denetçinin ödeyemediği tazminat ortak borca eklenir. O tur için faiz işlemez. |
| Taksit fazlası | Sonraki taksitten düşer. |
| Eşitlik | Önce servet, sonra toplam katkı. Hâlâ eşitse oyuncular daha iyi sırayı paylaşır (puanı ikisi de alır). |
| Oyuncu sayısı | En az 3 (kabul edildi). 2 kişide toplam bilindiği için gelirler açığa çıkıyor. Simülasyon şimdilik 4 kişilik. |

## Botlar nasıl oynuyor

Botlar bilerek basit tutuldu. Her biri bir oyuncu tipi:

| Bot | Davranış |
|---|---|
| dürüst | Doğru beyan; beyanına düşen payı ve masadaki açığın kendine düşen kısmını öder |
| açgözlü | Gelirinin yarısını saklar, kendi denetçi turunda tamamını; açığın sadece yarısına katılır |
| fırsatçı | Sadece kendi denetçi turunda (denetlenemezken) tamamını saklar |
| yolsuz | Açgözlü + denetçiyken rüşvet alır, yakalanınca rüşvet verir |
| kinci | Açgözlü + son turda kazanamayacağını düşünürse hiç katkı yapmaz |
| bedavacı | Doğru beyan, payının sadece %60'ını öder |

- **Kimi denetler:** Herkes en şüpheli bulduğu oyuncuyu denetliyor. Şüphenin kaynakları:
  - beyanların açıklayamayacağı aksesuar harcaması (en güçlü işaret);
  - eşit payın altında kalan bir beyan;
  - daha önce yakalanmış olmak.
- **Aksesuar alırken:** Botlar, beyanlarının açıklayabileceğinden fazlasını harcamıyor; zenginliklerini ele vermiyorlar.
- **Rüşvet:** Yakalanan yalancı ile denetçi, ikisi için de raporlanmaktan iyiyse anlaşıyor.

## Sınırlar

- Botlar konuşmuyor, ikna etmiyor, kin tutmuyor, ittifak kurmuyor. Oyunun asıl olayı olan sohbet burada hiç yok.
- Kefil ve rüşvet pazarlığı çok kaba. İnsanlar hem daha cesur hem daha tutarsız oynayacak.
- Sonuçlar 4 kişilik masa için; 3 ve 5 kişilik kurallar henüz tasarlanmadı.
- Botların parametreleri (ör. "açgözlü gelirinin yarısını saklar") varsayım. Başka varsayımlar başka oranlar verir. Yönler (hangi kural neyi ödüllendiriyor) sayılardan daha güvenilir.

## Sıradaki adımlar

1. **Kerem Gönç:** yukarıdaki 3 öneri (kart açık, asgari katkı %60, son tur dükkanı kapalı) ve "açık noktalar" tablosu için karar.
2. **Kağıt prototip:** Önerili ve önerisiz birer maç oynayın, farkı masada hissedin. Özellikle örtbası ve fazla beyanı gözleyin.
3. **Simülatör:** Kararlardan sonra tekrar çalıştırılır. Bir sonraki adım, masadakilere göre davranışını değiştiren (uyarlanan) botlar.

Simülatörü çalıştırmak (bu raporu tekrar üretmek için önce `git checkout 1b5964f`; şimdiki simülatör v0.2'yi çalıştırıyor):

```
godot --headless --path game --script res://sim/simulate.gd -- --matches=2000 --out=$(pwd)/docs/sim/sonuclar-v0.1.md
```
