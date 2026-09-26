# Mutfak Telaşı (Flutter)

Yang Le Ge Yang tarzı katmanlı eşleştirme bulmacasının mutfak konseptli
Flutter portu. Web'deki HTML/JS prototipiyle aynı oyun mantığını
(`lib/game/game_controller.dart`) kullanır; arayüz tamamen Material 3
widget'ları ve özel (custom) widget'larla, emojisiz olarak yeniden
kurulmuştur.

## Nasıl çalıştırılır

Bu oturumda Flutter SDK kurulu değildi, bu yüzden kod derlenip
çalıştırılarak doğrulanamadı — dosyalar dikkatle elle yazıldı. Kendi
makinenizde:

```bash
cd kitchen_rush_flutter
flutter pub get
flutter analyze   # önce hızlı bir statik kontrol için önerilir
flutter run
```

Bir syntax/typo hatasıyla karşılaşırsanız (ör. bir Lucide ikon adı sürüm
farkı nedeniyle değişmiş olabilir), `flutter analyze` çıktısını paylaşın,
hemen düzeltirim.

## Kütüphaneler

- **Material 3** — `ThemeData(useMaterial3: true)`, `ColorScheme.fromSeed`.
- **lucide_icons_flutter** — havuç, et, yumurta ve tüm arayüz ikonları
  (duraklat, karıştır, geri al, ayarlar, hedef, onay) için gerçek Lucide
  ikonları.
- **google_fonts** — Nunito tipografisi.
- Emoji **kullanılmadı** (yalnızca birkaç serbest metin dizesi hariç, ör.
  "🔥 Kombo" toast metni — arayüz kontrolü/ikon değil).

## Neden bazı malzemeler Lucide değil, özel çizim?

Lucide setinde `Carrot`, `Beef` ve `Egg` var; ama **domates, soğan,
sarımsak, biber, peynir** için Lucide'de karşılık gelen bir ikon yok. Bu
beşi emoji yerine `lib/widgets/ingredient_painters.dart` içinde
`CustomPainter` ile elle çizilmiş, gradyanlı vektör glyph'ler olarak
render ediliyor (`ingredient_glyph.dart` ikisi arasında otomatik seçim
yapıyor).

## Dosya yapısı

```
lib/
  main.dart                    # MaterialApp + tema
  models/
    ingredient.dart            # 8 malzeme tipi + renk/ikon eşlemesi
    kitchen_tile.dart           # KitchenTile, TrayItem, ChefTitleTier
  game/
    game_controller.dart        # Tüm oyun mantığı (ChangeNotifier)
  widgets/
    ingredient_glyph.dart       # Lucide ikon / özel çizim seçici
    ingredient_painters.dart    # CustomPainter glyph'ler
    kitchen_tile_widget.dart    # Tahtadaki tek karo
    order_rail_widget.dart      # 7 gözlü sipariş rayı
    hud_widgets.dart            # Aşçı rozeti, hamle sayacı, duraklat, logo
    target_sign_widget.dart     # Hedef malzeme panosu
    toolbar_gem_button.dart     # Karıştır/Geri Al/Ayarlar butonları
    overlays.dart               # Oyun sonu / mola / yardım dialogları
  screens/
    game_screen.dart            # Ekranı birleştiren ana Scaffold
```

## HTML prototipine göre bilinçli sadeleştirmeler

- Buhar (steam) ambiyans animasyonu ve karo uçuş animasyonu (tray'e
  uçan ikon) bu ilk portta yok; oyun mantığı ve HUD birebir taşındı.
  İsterseniz bir sonraki adımda `AnimatedPositioned` / `Overlay` ile
  eklenebilir.
- Tahta sabit mantıksal boyutta (356×352) tutulup `FittedBox` ile dar
  ekranlara ölçekleniyor; tam responsive grid yeniden hesaplama yapılmadı.
