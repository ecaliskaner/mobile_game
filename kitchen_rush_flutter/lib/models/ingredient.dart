import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The eight ingredient types used on the board. Values double as stable
/// identifiers (persisted in nothing here, but kept short and explicit).
enum IngredientType { tomato, carrot, onion, meat, egg, garlic, pepper, cheese }

/// Visual + semantic metadata for one ingredient.
///
/// When [lucideIcon] is set, the ingredient is rendered with a real Lucide
/// icon (Carrot, Beef, Egg — Lucide ships these food icons natively).
/// Lucide has no dedicated tomato/onion/garlic/pepper/cheese glyphs, so
/// those five fall back to hand-drawn [CustomPainter] glyphs instead of an
/// emoji (see `widgets/ingredient_painters.dart`).
class IngredientSpec {
  final String labelTr;
  final Color primary;
  final Color secondary;
  final IconData? lucideIcon;

  const IngredientSpec({
    required this.labelTr,
    required this.primary,
    required this.secondary,
    this.lucideIcon,
  });
}

const Map<IngredientType, IngredientSpec> kIngredientSpecs = {
  IngredientType.tomato: IngredientSpec(
    labelTr: 'Domates',
    primary: Color(0xFFE6432C),
    secondary: Color(0xFFA8241A),
  ),
  IngredientType.carrot: IngredientSpec(
    labelTr: 'Havuç',
    primary: Color(0xFFFFB84D),
    secondary: Color(0xFFDD7513),
    lucideIcon: LucideIcons.carrot,
  ),
  IngredientType.onion: IngredientSpec(
    labelTr: 'Soğan',
    primary: Color(0xFFC77BB0),
    secondary: Color(0xFF7D3F68),
  ),
  IngredientType.meat: IngredientSpec(
    labelTr: 'Et',
    primary: Color(0xFFC97052),
    secondary: Color(0xFF7A3524),
    lucideIcon: LucideIcons.beef,
  ),
  IngredientType.egg: IngredientSpec(
    labelTr: 'Yumurta',
    primary: Color(0xFFFFF6E2),
    secondary: Color(0xFFF6B93B),
    lucideIcon: LucideIcons.egg,
  ),
  IngredientType.garlic: IngredientSpec(
    labelTr: 'Sarımsak',
    primary: Color(0xFFFFFAF0),
    secondary: Color(0xFFD3C095),
  ),
  IngredientType.pepper: IngredientSpec(
    labelTr: 'Biber',
    primary: Color(0xFF8FD14F),
    secondary: Color(0xFF2E7D32),
  ),
  IngredientType.cheese: IngredientSpec(
    labelTr: 'Peynir',
    primary: Color(0xFFFFE07A),
    secondary: Color(0xFFE8A017),
  ),
};
