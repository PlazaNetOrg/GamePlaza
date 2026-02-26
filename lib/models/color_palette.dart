import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorPalette {
  plazanet,
  nostalgiaWhite,
  catppuccinLatte,
  catppuccinFrappe,
  catppuccinMacchiato,
  catppuccinMocha,
}

extension ColorPaletteExtension on ColorPalette {
  String get storageKey {
    switch (this) {
      case ColorPalette.plazanet:
        return 'plazanet';
      case ColorPalette.nostalgiaWhite:
        return 'nostalgia_white';
      case ColorPalette.catppuccinLatte:
        return 'catppuccin_latte';
      case ColorPalette.catppuccinFrappe:
        return 'catppuccin_frappe';
      case ColorPalette.catppuccinMacchiato:
        return 'catppuccin_macchiato';
      case ColorPalette.catppuccinMocha:
        return 'catppuccin_mocha';
    }
  }

  static ColorPalette fromString(String value) {
    switch (value) {
      case 'nostalgia':
      case 'nostalgia_white':
        return ColorPalette.nostalgiaWhite;
      case 'catppuccin_latte':
        return ColorPalette.catppuccinLatte;
      case 'catppuccin_frappe':
        return ColorPalette.catppuccinFrappe;
      case 'catppuccin_macchiato':
        return ColorPalette.catppuccinMacchiato;
      case 'catppuccin_mocha':
        return ColorPalette.catppuccinMocha;
      case 'plazanet':
      default:
        return ColorPalette.plazanet;
    }
  }

  static Future<ColorPalette> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('color_palette');
    if (value == null) return ColorPalette.plazanet;
    return fromString(value);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color_palette', storageKey);
  }
}

class PaletteColors {
  final Color primaryBlue;
  final Color secondaryBlue;
  final Color darkSurface;
  final Color elevatedSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const PaletteColors({
    required this.primaryBlue,
    required this.secondaryBlue,
    required this.darkSurface,
    required this.elevatedSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  // PlazaNet Default Palette
  static const plazanet = PaletteColors(
    primaryBlue: Color(0xFF3A9FF1),
    secondaryBlue: Color(0xFF64B7FF),
    darkSurface: Color(0xFF0F172A),
    elevatedSurface: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    divider: Color(0xFF334155),
  );

  // Nostalgia White Palette
  static const nostalgiaWhite = PaletteColors(
    primaryBlue: Color(0xFF4DA3FF),
    secondaryBlue: Color(0xFF7DBBFF),
    darkSurface: Color(0xFFF5F6F8),
    elevatedSurface: Color(0xFFE9EDF2),
    textPrimary: Color(0xFF1C2026),
    textSecondary: Color(0xFF5F6B76),
    divider: Color(0xFFD1D7E0),
  );

  // Catppuccin Latte Palette
  static const catppuccinLatte = PaletteColors(
    primaryBlue: Color(0xFF1E66F5),
    secondaryBlue: Color(0xFF7287FD),
    darkSurface: Color(0xFFEFF1F5),
    elevatedSurface: Color(0xFFDCE0E8),
    textPrimary: Color(0xFF4C4F69),
    textSecondary: Color(0xFF6C6F85),
    divider: Color(0xFFBCC0CC),
  );

  // Catppuccin Frappe Palette
  static const catppuccinFrappe = PaletteColors(
    primaryBlue: Color(0xFF8CAAEE),
    secondaryBlue: Color(0xFF85C1DC),
    darkSurface: Color(0xFF303446),
    elevatedSurface: Color(0xFF414559),
    textPrimary: Color(0xFFC6D0F5),
    textSecondary: Color(0xFFA5ADCE),
    divider: Color(0xFF626880),
  );

  // Catppuccin Macchiato Palette
  static const catppuccinMacchiato = PaletteColors(
    primaryBlue: Color(0xFF8AADF4),
    secondaryBlue: Color(0xFF7DC4E4),
    darkSurface: Color(0xFF24273A),
    elevatedSurface: Color(0xFF363A4F),
    textPrimary: Color(0xFFCAD3F5),
    textSecondary: Color(0xFFA5ADCB),
    divider: Color(0xFF5B6078),
  );

  // Catppuccin Mocha Palette
  static const catppuccinMocha = PaletteColors(
    primaryBlue: Color(0xFF89B4FA),
    secondaryBlue: Color(0xFF74C7EC),
    darkSurface: Color(0xFF1E1E2E),
    elevatedSurface: Color(0xFF313244),
    textPrimary: Color(0xFFCDD6F4),
    textSecondary: Color(0xFFA6ADC8),
    divider: Color(0xFF585B70),
  );

  static PaletteColors fromPalette(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.plazanet:
        return plazanet;
      case ColorPalette.nostalgiaWhite:
        return nostalgiaWhite;
      case ColorPalette.catppuccinLatte:
        return catppuccinLatte;
      case ColorPalette.catppuccinFrappe:
        return catppuccinFrappe;
      case ColorPalette.catppuccinMacchiato:
        return catppuccinMacchiato;
      case ColorPalette.catppuccinMocha:
        return catppuccinMocha;
    }
  }
}
