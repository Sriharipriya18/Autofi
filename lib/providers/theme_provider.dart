import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePalette { navyTeal, charcoalBlue, slateEmerald }

enum ThemeModeSetting { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _paletteKey = 'theme_palette';

  ThemeModeSetting _modeSetting = ThemeModeSetting.system;
  ThemePalette _palette = ThemePalette.navyTeal;

  ThemeProvider() {
    _load();
  }

  ThemeModeSetting get modeSetting => _modeSetting;
  ThemePalette get palette => _palette;

  ThemeMode get flutterMode {
    switch (_modeSetting) {
      case ThemeModeSetting.light:
        return ThemeMode.light;
      case ThemeModeSetting.dark:
        return ThemeMode.dark;
      case ThemeModeSetting.system:
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeRaw = prefs.getString(_modeKey);
    final paletteRaw = prefs.getString(_paletteKey);
    if (modeRaw != null) {
      _modeSetting = ThemeModeSetting.values
          .firstWhere((m) => m.name == modeRaw, orElse: () => ThemeModeSetting.system);
    }
    if (paletteRaw != null) {
      _palette = ThemePalette.values
          .firstWhere((p) => p.name == paletteRaw, orElse: () => ThemePalette.navyTeal);
    }
    notifyListeners();
  }

  Future<void> setModeSetting(ThemeModeSetting setting) async {
    _modeSetting = setting;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, setting.name);
    notifyListeners();
  }

  Future<void> setPalette(ThemePalette palette) async {
    _palette = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, palette.name);
    notifyListeners();
  }
}

class ThemePaletteConfig {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color onBackground;

  const ThemePaletteConfig({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.onBackground,
  });

  static ThemePaletteConfig of(ThemePalette palette, Brightness brightness) {
    switch (palette) {
      case ThemePalette.charcoalBlue:
        return brightness == Brightness.dark
            ? const ThemePaletteConfig(
                primary: Color(0xFF1F7AE0),
                secondary: Color(0xFF66D9FF),
                tertiary: Color(0xFF4ADE80),
                background: Color(0xFF0E1116),
                surface: Color(0xFF1A1F2B),
                onSurface: Colors.white,
                onBackground: Colors.white,
              )
            : const ThemePaletteConfig(
                primary: Color(0xFF1F7AE0),
                secondary: Color(0xFF1463C9),
                tertiary: Color(0xFF16A34A),
                background: Color(0xFFF5F7FB),
                surface: Color(0xFFFFFFFF),
                onSurface: Color(0xFF0F172A),
                onBackground: Color(0xFF0F172A),
              );
      case ThemePalette.slateEmerald:
        return brightness == Brightness.dark
            ? const ThemePaletteConfig(
                primary: Color(0xFF34D399),
                secondary: Color(0xFF10B981),
                tertiary: Color(0xFF60A5FA),
                background: Color(0xFF0D1115),
                surface: Color(0xFF1A2026),
                onSurface: Colors.white,
                onBackground: Colors.white,
              )
            : const ThemePaletteConfig(
                primary: Color(0xFF10B981),
                secondary: Color(0xFF059669),
                tertiary: Color(0xFF3B82F6),
                background: Color(0xFFF6FAF8),
                surface: Color(0xFFFFFFFF),
                onSurface: Color(0xFF0F172A),
                onBackground: Color(0xFF0F172A),
              );
      case ThemePalette.navyTeal:
      default:
        return brightness == Brightness.dark
            ? const ThemePaletteConfig(
                primary: Color(0xFF22D3EE),
                secondary: Color(0xFF2DD4BF),
                tertiary: Color(0xFF60A5FA),
                background: Color(0xFF0B1320),
                surface: Color(0xFF141C2B),
                onSurface: Colors.white,
                onBackground: Colors.white,
              )
            : const ThemePaletteConfig(
                primary: Color(0xFF0EA5E9),
                secondary: Color(0xFF14B8A6),
                tertiary: Color(0xFF3B82F6),
                background: Color(0xFFF4F8FD),
                surface: Color(0xFFFFFFFF),
                onSurface: Color(0xFF0F172A),
                onBackground: Color(0xFF0F172A),
              );
    }
  }
}