import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _pinSaltKey = 'pin_salt';
  static const _pinHashKey = 'pin_hash';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _demoModeKey = 'demo_mode';
  static const _recoverySaltKey = 'recovery_salt';
  static const _recoveryQuestionsKey = 'recovery_questions';
  static const _recoveryHashesKey = 'recovery_hashes';
  static const _usernameKey = 'profile_name';
  static const _avgIncomeKey = 'avg_monthly_income';
  static const _iterations = 120000;

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinHashKey) != null && prefs.getString(_pinSaltKey) != null;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _randomBytes(16);
    final hash = await _deriveHash(pin, salt);
    await prefs.setString(_pinSaltKey, base64Encode(salt));
    await prefs.setString(_pinHashKey, base64Encode(hash));
    await prefs.setBool(_demoModeKey, false);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saltEncoded = prefs.getString(_pinSaltKey);
    final hashEncoded = prefs.getString(_pinHashKey);
    if (saltEncoded == null || hashEncoded == null) {
      return false;
    }
    final salt = base64Decode(saltEncoded);
    final expected = base64Decode(hashEncoded);
    final actual = await _deriveHash(pin, salt);
    return _constantTimeEquals(expected, actual);
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinSaltKey);
    await prefs.remove(_pinHashKey);
  }

  Future<void> setRecoveryQuestions({
    required List<String> questions,
    required List<String> answers,
  }) async {
    if (questions.length != answers.length || questions.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final salt = _randomBytes(16);
    final hashes = <String>[];
    for (final answer in answers) {
      final hash = await _deriveHash(answer.trim().toLowerCase(), salt);
      hashes.add(base64Encode(hash));
    }
    await prefs.setString(_recoverySaltKey, base64Encode(salt));
    await prefs.setString(_recoveryQuestionsKey, jsonEncode(questions));
    await prefs.setString(_recoveryHashesKey, jsonEncode(hashes));
  }

  Future<List<String>> getRecoveryQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recoveryQuestionsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => e.toString()).toList();
  }

  Future<bool> verifyRecoveryAnswers(List<String> answers) async {
    final prefs = await SharedPreferences.getInstance();
    final saltEncoded = prefs.getString(_recoverySaltKey);
    final hashesEncoded = prefs.getString(_recoveryHashesKey);
    if (saltEncoded == null || hashesEncoded == null) {
      return false;
    }
    final salt = base64Decode(saltEncoded);
    final stored = (jsonDecode(hashesEncoded) as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    if (answers.length != stored.length) {
      return false;
    }
    for (var i = 0; i < answers.length; i++) {
      final hash = await _deriveHash(answers[i].trim().toLowerCase(), salt);
      if (!_constantTimeEquals(base64Decode(stored[i]), hash)) {
        return false;
      }
    }
    return true;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoModeKey, value);
  }

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoModeKey) ?? false;
  }

  Future<void> setUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name.trim());
  }

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? 'Guest';
  }

  Future<void> setAvgMonthlyIncome(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_avgIncomeKey, amount);
  }

  Future<double> getAvgMonthlyIncome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_avgIncomeKey) ?? 0.0;
  }

  Future<void> setBiometricsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, value);
  }

  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<List<int>> _deriveHash(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return bytes;
  }

  List<int> _randomBytes(int length) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
