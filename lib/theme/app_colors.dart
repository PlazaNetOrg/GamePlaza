import 'package:flutter/material.dart';
import '../models/color_palette.dart';

/// PlazaNet Color Palette
class AppColors {
  static PaletteColors _current = PaletteColors.plazanet;

  static void setPalette(ColorPalette palette) {
    _current = PaletteColors.fromPalette(palette);
  }

  static Color get primaryBlue => _current.primaryBlue;
  static Color get secondaryBlue => _current.secondaryBlue;
  static Color get darkSurface => _current.darkSurface;
  static Color get elevatedSurface => _current.elevatedSurface;
  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get divider => _current.divider;
}
