# M2 — Online gri kutu

> Durum: **İkinci sürüm (anlaşılırlık turu) hazır, ekip testi bekliyor** · Son güncelleme: 2026-10-21
> Mimari: [ADR-0002](adr/0002-online-mac-mimarisi.md) · Kurallar: [kurallar v0.3](gdd/kurallar-v0.3.md)

Kurallar v0.3'ün tamamı online oynanıyor:

- gelir, beyan, asgari katkı;
- pazarlık (kefil, masa altı), ek katkı;
- denetim (örtbas dahil);
- dükkan, senet;
- Hesap Günü ve 4 maçlık gece.

Maymunlar hâlâ gri kutu; sanat yok. Boş koltuklara bot oturuyor. Oyun sırasında biri çıkarsa yerine bot geçiyor.

**Anlaşılırlık turu (ilk denemeden sonra):**

İlk denemede oyunun akışı anlaşılmadı. Bu yüzden şunlar eklendi:
- **Nasıl oynanır:** Lobide ve masada ("Kurallar" düğmesi) 7 sayfalık kısa anlatım. Oyun ilk kez açılınca kendiliğinden açılır.
- **Temel kurallarla ilk maç:** Kefil, masa altı ve dükkan ikinci maçta açılır ([kurallar](gdd/kurallar-v0.3.md#ilk-maç-temel-kurallar)).
- **Eylem kartı:** Her aşamada ne olduğunu ve ne yapacağını anlatan kart. Sıra sendeyse kenarı parlar ve başlıkta "Sıra sende" yazar.
- **Büyük duyurular:** Beyanlar açıldı, kasada kaç jeton var, kim denetleniyor, YAKALANDI!, taksit ödendi/eksik, masa kurtuldu/battı.
- **Masada:**
  - Ortada kasadaki jetonlar ve "Kasa 8 / 12" yazısı.
  - Her oyuncunun önünde beyan kartı: herkes beyan edene kadar kapalı (kırmızı), sonra açık.
- **Botlar:** Teker teker ve yavaş oynuyor (1,4 sn), ne olduğunu takip edebilesin diye.
- **Hesap Günü'nde ek satır:** Kim kaç kez yalan söyledi, kaçında yakalandı.

## Nasıl oynanır

### Tek başına, botlarla (en hızlı deneme)

1. Godot'da **Debug → Customize Run Instances…** aç. **Enable Multiple Instances**'ı kapat (4 pencere ayarı kalsa da olur, kapatınca tek pencere açılır).
2. **F5**. Lobide adını yaz, **Botlarla oyna**'ya bas. Masa kurulur, 3 bot oturur, oyun başlar.

İlk kez açılıyorsa önce "Nasıl oynanır" gelir; 7 sayfa, iki dakika.

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
**İlk maç temel kurallarla** işaretliyse (varsayılan) ilk maçta kefil, masa altı ve dükkan yoktur. Oyunu bilen bir masa bunu kapatabilir.

## Ekran

İkinci denemeden sonra ekran sadeleştirildi ("çok fazla yazı var"). Kural: her an tek bir yere bakmak yeter, o da ortadaki eylem kartı.

- **Sol üst:** sadece maç ve tur ("Maç 1/4 · Tur 2/4 · temel kurallar").
- **Sağ üst:** pazarlık süresi (sadece pazarlıkta) ve **Menü**:
  - Kurallar;
  - Olay kaydı (aç/kapa);
  - Mikrofon, ses ayrıntıları, kendi sesini duyma;
  - Masadan kalk.
- **Ortada, kısa süre:** önemli anların duyuruları (beyanlar açıldı, YAKALANDI!, taksit eksik…).
- **Masa:**
  - kasadaki jetonlar ve "Kasa 8 / 12";
  - her oyuncunun önünde beyan kartı (herkes beyan edene kadar kapalı);
  - alınan aksesuarlar küçük şekiller olarak (M3'te maymunların üstüne geçecek).
- **Maymunların üstü:** sadece ad ve tek işaret. "…" bekleniyor, "✓" hazır, sarı şapka denetçi. Pazarlıkta kimin kime kefil olduğu da burada.
- **Orta alt (eylem kartı):** aşamanın adı, tek kısa cümle ve düğmeler. Sıra sendeyse kenarı parlar. Kartın köşesindeki **?** o aşamanın kuralını açar.
- **Sol alt:** gelirin, cebin, puanın (ve varsa senedin).

| Aşama | Ne yapılır |
|---|---|
| Beyan | Sayıyı seç, **Beyan et**. Denetçinin kartı açık, beyanı gelirine kilitli. |
| Konuşma / Pazarlık | Konuşun. İkinci maçtan itibaren kefil ve masa altı da var. **Hazırım**. Herkes hazır olunca ya da 2 dakika dolunca biter. |
| Katkı | Asgari zaten ödendi. Üstüne koyacağın jetonu seç, **Avucunu kapat**. |
| Denetim (denetçi) | Kimin kartına bakacağını seç. Sonra **Raporla** ya da **Göz yum** (örtbas). Doğru söyleyene **Temiz** dersin. |
| Denetim (diğerleri) | Bekle. İkinci maçtan itibaren masa altından rüşvet verebilirsin. |
| Dükkan | Aksesuar al (herkes görür), **Turu bitir**. İlk maçta ve son turda yok. |
| Hesap Günü | Bütün gelirler ve beyanlar (kırmızı = yalan), kim kaç kez yalan söyledi ve yakalandı, örtbaslar, masa altı, servet, puan. **Sonraki maça hazırım**. |

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
| `--bot-delay=0` | Botlar beklemeden oynar (testler). Varsayılan 1,4 sn, botlar teker teker. |
| `--no-tutorial` | Lobide "İlk maç temel kurallarla" kapalı başlar. |
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
