# M2 — Online gri kutu

> Durum: **İlk sürüm hazır, ekip testi bekliyor** · Son güncelleme: 2026-10-21
> Mimari: [ADR-0002](adr/0002-online-mac-mimarisi.md) · Kurallar: [kurallar v0.3](gdd/kurallar-v0.3.md)

Kurallar v0.3'ün tamamı online oynanıyor:

- gelir, beyan, asgari katkı;
- pazarlık (kefil, masa altı), ek katkı;
- denetim (örtbas dahil);
- dükkan, senet;
- Hesap Günü ve 4 maçlık gece.

Maymunlar hâlâ gri kutu; sanat yok. Boş koltuklara bot oturuyor. Oyun sırasında biri çıkarsa yerine bot geçiyor.

## Nasıl oynanır

### Tek başına, botlarla (en hızlı deneme)

1. Godot'da **Debug → Customize Run Instances…** aç. **Enable Multiple Instances** işaretli kalsın, sayıyı **1** yap.
2. 1. satırın Launch Arguments alanına: `-- --auto-host --auto-start=1 --name=Kerem`
3. **F5**. Masa kurulur, 3 bot oturur, oyun başlar.

### Kendi bilgisayarında 4 pencereyle

[M1 dokümanındaki](spike-m1.md#kendi-bilgisayarında-4-pencereyle-denemek) gibi:

- 4 pencere aç.
- İlk satır: `-- --auto-host --auto-start=4 --win=0 --name=Kerem`
- Diğer satırlar: `-- --auto-join --win=N --name=...`

Daha az pencere açarsan (ör. `--auto-start=2` ile 2 pencere) kalan koltuklara bot oturur.

### Arkadaşlarla, Steam üzerinden

M1 B2'deki gibi:

1. Biri **Steam masası kur**'a basar ve lobi kodunu diğerlerine gönderir.
2. Diğerleri kodla katılır.
3. Host **Oyunu başlat**'a basar.

**Boş koltuklara bot oturt** işaretliyse (varsayılan) eksik kişiler botla tamamlanır. Böylece 2 kişiyle de tam oyun oynanabilir. İşareti kaldırırsan en az 3 kişi gerekir.

## Ekran

- **Üst çubuk:** maç ve tur, aşama, denetçi, bu tur ödenecek taksit, kasadaki jeton, pazarlık süresi.
- **Sol alt (sen):** gelirin (sadece sen görürsün), cebin, beyanın ve ödenen asgarin, senetlerin, aksesuarların, gece puanın, ses ayarları.
- **Orta alt (ne yapacaksın):** o aşamanın düğmeleri. "Bekleniyor:" satırı kimin karar vermediğini gösterir.

  | Aşama | Ne yapılır |
  |---|---|
  | Beyan | Sayıyı seç, **Beyan et**. Herkes beyan edince açılır. Denetçinin kartı açık, beyanı gelirine kilitli. |
  | Pazarlık | Kefil seçimi, masa altından jeton verme, **Pazarlığı bitir**. Herkes hazır olunca ya da 2 dakika dolunca biter. |
  | Katkı | Asgari zaten ödendi. Üstüne koyacağın jetonu seç, **Avucunu kapat**. |
  | Denetim (denetçi) | Kimi denetleyeceğini seç. Sonra kartını gör: **Raporluyorum** ya da **Temiz** (temiz dersen tazminat ödersin; yalanı görüp temiz demek örtbas). |
  | Denetim (diğerleri) | Bekle ya da masa altından rüşvet ver. |
  | Dükkan | Aksesuar al (herkes görür), **Turu bitir**. Son turda dükkan kapalı. |
  | Hesap Günü | Bütün gelirler ve beyanlar (kırmızı = yalan), örtbaslar, masa altı transferler, servet, puan, gece toplamı. **Sonraki maça hazırım**. |

- **Sağ alt (olaylar):** masada olan her şey. Sarı satırlar sadece seni ilgilendiren gizli şeyler (masa altı).
- **Maymunların üstü:** ad, denetçi şapkası (sarı), beyan, katkı, kimin kefili olduğu, aksesuarlar, senet.

## Deneme listesi (ekibe)

Bir gece oynayın (4 maç, ~40–60 dakika) ve şunları not edin. Notları `docs/playtests/` altına `_sablon.md` ile yazabiliriz.

1. Kurallar ekrandan anlaşılıyor mu? Hangi aşamada "şimdi ne yapacağım?" dediniz?
2. Pazarlık süresi (2 dk) kısa mı, uzun mu? Herkes erkenden "hazırım" mı diyor?
3. Yalan söyleyen çıktı mı? Yakalandı mı? Örtbas oldu mu?
4. Masa battı mı?
5. Botlar sırıtıyor mu (çok aptal ya da çok iyi)?
6. Hata, donma, yanlış görünen bir sayı. Ekran görüntüsü ve `UcMaymun.console.exe` çıktısı çok yardımcı olur.

## Geliştirici notları

| Argüman | Ne yapar |
|---|---|
| `--seed=N` | Geceyi aynı kartlarla tekrar oynatır (host). Seed her gece başında konsola yazılır. |
| `--no-bots` | Lobide bot seçeneği kapalı başlar. |
| `--bot-kinds=açgözlü,kinci` | Botların tipi (sırayla). Yoksa rastgele: dürüst, açgözlü, kinci, bedavacı. |
| `--bot-delay=0` | Botlar beklemeden oynar (testler). Varsayılan 0,8 sn. |
| `--fake-voice` | Mikrofon yerine test tonu (M1'deki gibi). |

Testler:
- E2E iki senaryo çalıştırıyor:
  - Host + 2 istemci + 1 bot bir geceyi oynuyor; sonuç simülatörle birebir aynı olmalı.
  - Bir istemci gece ortasında çıkıyor; yerine bot geçmeli ve gece bitmeli.
- Birim testleri `Night` sınıfının akışını ağsız sınıyor (`tests/unit/test_night.gd`).

## Bilinen sınırlar (sonraki adımlar)

- Bas-konuş (push-to-talk), fısıltı ve oyuncu başına sessize alma yok.
- Yeniden bağlanma yok: çıkan oyuncu geri gelemez, koltuğunu bot oynar. Host çıkarsa gece biter.
- Botlar konuşmuyor, pazarlık etmiyor, rüşvet vermiyor ya da almıyor; masa altından gelen jetonu da karşılıksız bırakıyor.
- 3 kişilik sayılar tasarlanmadı. Botlar kapalıyken 3 kişiyle oynanabiliyor ama denge 4 kişiye göre.
- Arayüz metinleri kodda Türkçe; çeviri sistemi yok.
- Maymun animasyonu, oda, ses efektleri ve Hesap Günü sahnesi M3'te.
