# Yol haritası

> Son güncelleme: 2026-10-21
>
> Sabit tarih yok; **kilometre taşlarıyla** ilerliyoruz. Her taşın bir "bitti" kriteri var. Her taş bitince
> ekip olarak üç seçenekten birine karar verilir: **devam / değiştir / bırak.**
> M2'den sonra ne kadar hızlı ilerlediğimizi göreceğiz; hedef Next Fest'i o zaman seçeceğiz.

## Kilometre taşları

| # | Taş | "Bitti" kriteri | Kim |
|---|---|---|---|
| **M0** | Kağıt prototip | En az 3 test oturumu yapıldı, notlar `docs/playtests/` altında. Oyuncular kendiliğinden "bir maç daha" diyor. Kurallar playtest'lere göre güncellendi. | Tüm ekip |
| **M1** | Teknik spike | ADR-0001'deki 5 kriter 4 ayrı Windows makinede çalıştı, ADR kabul edildi. | Kerem Ataç + Claude |
| **M2** | Online gri kutu | Tam kural döngüsü online oynanıyor. Maymunlar kutu, sanat yok. Kural motorunun testleri ve simülasyonu var. Ekip haftada en az bir kez kendi oyununu oynuyor. | Kerem Ataç + Claude, testlerde herkes |
| **M3** | Sanat yönü + vertical slice | Maymun modeli (sipariş veya kendimiz), oda, Hesap Günü ekranı hazır. **Steam sayfası açıldı** (Steam Direct ücreti 100 $), kapsül görseli sipariş edildi. | Ekip + dışarıdan sanatçı |
| **M4** | Demo | Steam Playtest veya demo yayında. Yayıncılara ve içerik üreticilerine ilk erişim verildi. | Tüm ekip |
| **M5** | Steam Next Fest | Bir Next Fest'e katılındı. Tarih M2 sonrası seçilecek; kayıt son günleri festivalden yaklaşık 6 hafta önce. | Tüm ekip |
| **M6** | Çıkış | Erken Erişim veya tam sürüm. Lansman sonrası içerik güncellemesi planı hazır. | Tüm ekip |

M0 ve M1 birbirinden bağımsız, aynı anda yürür.

**Şu an (2026-10-21):**
- M1'de kalan tek iş gerçek mikrofonla ses testi.
- M2'nin ilk sürümü hazır: kuralların tamamı online ve botlarla oynanıyor ([m2-gri-kutu.md](m2-gri-kutu.md)).
- M2'nin "bitti" kriteri için ekibin düzenli olarak oynaması gerekiyor.
- Online gri kutu, kağıt prototipin yerine de kullanılabilir: ayrı evlerden oynanabiliyor.
- M3 planı taslak hâlinde: [m3-plan.md](m3-plan.md). Para gerektirmeyen kısmı (görsel yön, sanatçı şartnamesi, teknik hazırlık) hemen başlayabilir. Para harcanan kısım M2 ekip testinden sonra.

## Çalışma ritmi

- **Haftalık:** 30–60 dakikalık ekip görüşmesi. Ne yapıldı, ne takıldı, sıradaki hafta.
- **İki haftada bir:** oynanabilir bir sürüm (M2'den itibaren). "Oynanamayan iki hafta" kırmızı alarm.
- **Her playtest sonrası:** `_sablon.md` ile not.
- **Her kilometre taşı sonrası:** devam / değiştir / bırak kararı ve bu dosyanın güncellenmesi.

## Kapsamı korumak

Takvim olmadığında en büyük risk, kapsamın sessizce büyümesi. Yeni fikirler bir listeye yazılır,
**M2'ye kadar çekirdek kurallar dışında hiçbir şey eklenmez.** Fikir listesi M3 planlanırken gözden geçirilir.
