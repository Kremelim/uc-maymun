# ADR-0001: Oyun motoru

- **Durum:** Önerildi. Teknik spike sonrası kabul edilecek ya da reddedilecek.
- **Tarih:** 2026-10-20

## Bağlam

- PC (Windows) / Steam, 3D tek oda, online 4 oyuncu.
- Sesli sohbet oyunun merkezinde.
- Kurallar sıra tabanlı, yani ağ yükü hafif. Ama oyunda **gizli bilgi** var: host otoritesi ve oyuncu başına filtrelenmiş durum şart.
- Ekip 4 kişi, bütçe kısıtlı. Ana geliştirici Kerem Ataç, Claude ile birlikte çalışıyor.

## Seçenekler

| | Godot 4.7 + GodotSteam | Unity 6.3 LTS + FishNet/FishySteamworks | Unreal 5.8 |
|---|---|---|---|
| Lisans | MIT, gelir payı yok | 200 bin $ gelir+fon altında ücretsiz, üstünde koltuk başı ~2.310 $/yıl | 1 milyon $ sonrası %5 |
| Steam lobi/ağ | GodotSteam MultiplayerPeer. Kendi dokümanına göre "başlangıç noktası, production kodu değil" | Olgun: FishySteamworks, Mirror | Yerleşik replikasyon + Steam OSS |
| Ses | GodotSteamKit SteamVoice node'u (Haziran 2026); taşıma katmanı bize kalıyor | Dissonance, UniVoice, Vivox | Yerleşik / EOS |
| Claude ile verim | Yüksek: sahneler metin, kod kısa | Orta: prefab/sahne YAML'ı GUID'li, elle düzenlemesi kırılgan | Düşük: Blueprint ikili dosya |
| Emsal | Bu tür için büyük örnek yok | Liar's Bar | — |

## Karar (öneri)

**Godot 4.7, şartlı.** İki haftalık spike'ta aşağıdakilerin hepsi çalışmalı:

1. Steam lobisi kurma, arkadaş daveti, 4 istemcinin bağlanması (geliştirmede test AppID 480).
2. Steam Voice ile 4 kişi masada konumsal ses, kabul edilebilir gecikme.
3. Host otoriter durum senkronu; her istemciye **sadece kendi gizli geliri** gönderiliyor.
4. Basit 3D sahne: masa + 4 yer tutucu maymun; ses şiddetine göre ağız açılıp kapanıyor.
5. Windows export'u çalışıyor, Steam overlay açılıyor.

Spike başarısız olursa **Unity**'ye geçilir: bu türde kanıtlanmış ve Steam çok oyunculu ekosistemi daha olgun.

**Kararı değiştirebilecek bilgi:** Ekipte güçlü C#/Unity deneyimi varsa Unity baştan tercih edilebilir.

## Sonuçlar

- **Kural motoru:** Ağdan ve görüntüden bağımsız saf kod. Deterministik, seed'li, ekransız test edilebilir, botlarla simüle edilebilir. Motor değişirse taşıma bir yeniden yazım değil, bir çeviri olur.
- **Ağ katmanı soyutlanır:** yerel geliştirmede ENet (tek makinede birden çok pencere), yayında Steam.
- **Hile önlemi:** Gizli bilgi (gelirler, ceplerdeki para) hiçbir zaman sahibi dışındaki istemciye gönderilmez.
