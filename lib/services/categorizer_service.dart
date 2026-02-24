import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategorizerService {
  static const _overridesKey = 'category_overrides';

  final Map<String, String> _keywordMap = const {
    'uber': 'Transport',
    'lyft': 'Transport',
    'gas': 'Transport',
    'fuel': 'Transport',
    'rent': 'Home',
    'mortgage': 'Home',
    'electric': 'Bills',
    'water': 'Bills',
    'internet': 'Bills',
    'phone': 'Bills',
    'grocery': 'Food',
    'supermarket': 'Food',
    'restaurant': 'Food',
    'cafe': 'Food',
    'coffee': 'Food',
    'pharmacy': 'Health',
    'doctor': 'Health',
    'hospital': 'Health',
    'school': 'Education',
    'course': 'Education',
    'udemy': 'Education',
    'flight': 'Travel',
    'hotel': 'Travel',
    'booking': 'Travel',
    'amazon': 'Shopping',
    'mall': 'Shopping',
    'clothes': 'Shopping',
    'netflix': 'Bills',
    'spotify': 'Bills',
  };

  Future<String?> suggestCategory({required String title, String? merchant}) async {
    final overrides = await _loadOverrides();
    final combined = '${title.trim()} ${merchant ?? ''}'.toLowerCase();
    for (final entry in overrides.entries) {
      if (combined.contains(entry.key)) {
        return entry.value;
      }
    }
    for (final entry in _keywordMap.entries) {
      if (combined.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  Future<void> addOverride({required String keyword, required String category}) async {
    final overrides = await _loadOverrides();
    overrides[keyword.toLowerCase()] = category;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_overridesKey, jsonEncode(overrides));
  }

  Future<Map<String, String>> _loadOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_overridesKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }
}