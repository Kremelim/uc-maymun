# ADR-0002: Online maç mimarisi

- **Durum:** Kabul edildi (M2 gri kutu ile).
- **Tarih:** 2026-10-21

## Bağlam

- Kurallar v0.3 tam olarak online oynanacak: 4 maçlık gece, her maçta 4 tur, her turda 7 aşama.
- Oyunda gizli bilgi var: gelirler, cepler, masa altı transferler, denetçinin baktığı kart. Kimse görmeye hakkı olmayanı görmemeli.
- Kural motoru (`MatchState`) ve simülatör hazır. Online oyunun simülatörle aynı kuralları oynadığından emin olmak istiyoruz.
- Ekip her zaman 4 kişi bulamıyor. Oyun sırasında biri düşerse maç bitmemeli.
- Claude testleri ekransız çalıştırıyor. Ağ kodu, arayüz açılmadan sınanabilmeli.

## Karar

1. **Gece kural motorunda:** `core/night.gd` (`Night`).
   - Görevi: maçları ve turları ilerletmek, "hazırım" kontrolleri, pazarlık sayacı ve olay kaydı.
   - `MatchState` gibi saf ve seed'li; zamanı `tick()` ile dışarıdan alıyor. Bu yüzden ağsız, ekransız test edilebiliyor.
2. **Host otoriter.**
   - `Night` sadece host'ta yaşar.
   - İstemciler niyet gönderir (ör. `{"type": "declare", "amount": 4}`). Host bunu `Night.apply()` ile kurallara göre dener; geçersizse yok sayar.
3. **Her oyuncuya sadece kendi görünümü gider.**
   - Host her değişiklikte her koltuğa `Night.view_for(koltuk)` gönderir; ayrı bir "herkese açık durum" yayını yok.
   - Görünüm şunları içerir:
     - masanın açık bilgileri;
     - o oyuncunun kendi sırları;
     - o oyuncunun görmeye hakkı olan olaylar. Masa altı transferi sadece veren ve alan görür.
   - Denetçinin baktığı kart sadece denetçiye gider. Hesap Günü verisi sadece maç bitince gider.
4. **Seed host'tan çıkmaz.** Seed'i bilen herkes kartları yeniden dağıtıp bütün gelirleri görebilir.
5. **Botlar host'ta.**
   - Boş koltukları `SeatBot` doldurur. `SeatBot`, simülatörün botlarını (`SimBot`) kullanır.
   - Bot da sadece kendi görünümünü okur, insanlarla aynı niyetleri aynı yoldan gönderir.
   - Oyun sırasında ayrılan oyuncunun koltuğuna bot geçer, gece devam eder.
   - Botlar rüşvet vermez, almaz; bunun için konuşmak gerekiyor.
6. **Online = simülatör.** Botlar simülatördeki sırayla karar verir. E2E testi şunu doğrular: online oynanan bir gecenin her maçı, aynı seed ve botlarla `MatchRunner`'ın oynadığı maçla birebir aynı biter. Testte host + 2 istemci + 1 host botu gerçek ENet üzerinden oynuyor.

## Sonuçlar

- **Artı:**
  - Kurallar tek yerde. Arayüz ve ağ kural bilmiyor, sadece gösteriyor ve iletiyor.
  - Gizli bilgi sızıntısı testle yakalanıyor (her istemci aldığı her görünümü kontrol ediyor).
  - Kağıt prototip olmadan da ayrı evlerden, eksik kişiyle (botlarla) oynanabiliyor.
- **Eksi:**
  - Her değişiklikte görünümün tamamı gönderiliyor. 4 oyuncu ve küçük durum için sorun değil; büyürse farklar (delta) gönderilir.
  - Host her şeyi biliyor. Arkadaşlar arasında kabul edilebilir; açık lobiler için ayrı sunucu ya da başka çözüm gerekir.
  - Host çıkarsa gece biter (host göçü yok).
