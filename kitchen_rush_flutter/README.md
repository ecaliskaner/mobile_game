# Mutfak Telaşı (Flutter)

Yang Le Ge Yang tarzı katmanlı eşleştirme bulmacası, mutfak konseptiyle.
Üstü açık malzemelere dokun, 7 gözlü tepsiye gönder, aynı malzemeden 3
tane yan yana gelince patlar. Tepsi eşleşmesiz dolarsa kaybedersin.

## Çalıştırma

İlk kez klonladıysanız platform klasörlerini (android/, windows/, web/…)
oluşturmak için bir kez `flutter create .` çalıştırın; `lib/` ve
`pubspec.yaml` dosyalarına dokunmaz.

```
flutter create .
flutter pub get
flutter run
```

Testler: `flutter test`

## Kurallar ve algoritma

- **Sıralı tepsi:** yeni gelen karo, tepside aynı türden karo varsa onun
  hemen yanına yerleşir; yoksa sona eklenir. Bu yüzden eşleşme her zaman
  yan yana duran 3 karodur (ör. domates, domates, havuç + domates →
  domates, domates, domates, havuç → üç domates patlar).
- **Animasyonla senkron:** eşleşme, karo tepsiye *indikten sonra*
  kontrol edilir; havadaki bir karo erkenden patlamaz.
- **Geri al:** yalnızca tepside duran son karoyu tahtaya geri koyar, daha
  önce patlamış bir karoyu asla geri getirmez. Kaybettikten sonra da
  kullanılabilir (oyuna devam).
- **Karıştır:** tahtadaki karoları yeniden dizer, katman yapısını korur.
- **Seviyeler:** 1. seviye 30 karo / 2 katman, 2. seviye 54 karo / 3
  katman, 3. seviye ve sonrası 72 karo / 4 katman.

## Kütüphaneler

- Material 3 (`useMaterial3: true`, `ColorScheme.fromSeed`)
- `lucide_icons_flutter` — arayüz ikonları ve havuç/et/yumurta
- Domates, soğan, sarımsak, biber, peynir için Lucide'de ikon olmadığından
  `CustomPainter` ile çizilmiş vektör ikonlar (`ingredient_painters.dart`)
- İnternet gerektiren font indirmesi yok; oyun tamamen çevrimdışı çalışır.

## Dosya yapısı

```
lib/
  main.dart                  MaterialApp + tema
  models/ingredient.dart      8 malzeme tipi, renk/ikon eşlemesi
  models/kitchen_tile.dart    Karo durumu (tahta/tepsi/patlıyor/bitti), seviye ayarı
  game/game_controller.dart   Oyun kuralları (ChangeNotifier)
  widgets/tile_face.dart      Tek karo görünümü
  widgets/ingredient_glyph.dart   Lucide ikon / özel çizim seçici
  widgets/ingredient_painters.dart CustomPainter ikonlar
  widgets/power_button.dart   Geri al / Karıştır butonları
  screens/game_screen.dart    Ekran: tahta + tepsi tek Stack'te, karolar
                              AnimatedPositioned ile uçarak tepsiye gider
test/game_controller_test.dart  Kural testleri
```
