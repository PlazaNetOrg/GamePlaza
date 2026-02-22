import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorPalette {
  plazanet,
  nostalgiaWhite,
}

extension ColorPaletteExtension on ColorPalette {
  String get storageKey {
    switch (this) {
      case ColorPalette.plazanet:
        return 'plazanet';
      case ColorPalette.nostalgiaWhite:
        return 'nostalgia_white';
    }
  }

  static ColorPalette fromString(String value) {
    switch (value) {
      case 'nostalgia':
      case 'nostalgia_white':
        return ColorPalette.nostalgiaWhite;
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

  static PaletteColors fromPalette(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.plazanet:
        return plazanet;
      case ColorPalette.nostalgiaWhite:
        return nostalgiaWhite;
    }
  }
}
