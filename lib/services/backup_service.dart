import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/alert_item.dart';
import '../models/insight_item.dart';

class BackupService {
  static const _backupVersion = 1;

  Future<void> exportBackup({required String filePath, required String pin}) async {
    final payload = await _buildPayload();

    final encrypted = await _encrypt(jsonEncode(payload), pin);
    final file = File(filePath);
    await file.writeAsString(jsonEncode(encrypted));
  }

  Future<String> exportAutoBackupJson() async {
    final payload = await _buildPayload();
    final docsDir = await getApplicationDocumentsDirectory();
    final filePath = p.join(docsDir.path, 'autofi_auto_backup.json');
    final file = File(filePath);
    await file.writeAsString(jsonEncode(payload));
    return filePath;
  }

  Future<ImportResult> importBackup({
    required String filePath,
    required String pin,
    required ImportStrategy strategy,
  }) async {
    final file = File(filePath);
    final raw = await file.readAsString();
    final encrypted = jsonDecode(raw) as Map<String, dynamic>;
    final decrypted = await _decrypt(encrypted, pin);
    final decoded = jsonDecode(decrypted) as Map<String, dynamic>;

    final data = decoded['data'] as Map<String, dynamic>;
    final expensesData = List<Map<String, dynamic>>.from(data['expenses'] ?? []);
    final budgetsData = List<Map<String, dynamic>>.from(data['budgets'] ?? []);
    final alertsData = List<Map<String, dynamic>>.from(data['alerts'] ?? []);
    final insightsData = List<Map<String, dynamic>>.from(data['insights'] ?? []);

    final db = AppDatabase();
    if (strategy == ImportStrategy.replaceAll) {
      await db.clearAll();
    }

    final existingExpenses = await db.getExpenses();
    final expenseKeyMap = {
      for (final e in existingExpenses)
        _expenseKey(e): e,
    };

    int added = 0;
    int updated = 0;

    for (final map in expensesData) {
      final imported = Expense.fromMap(map);
      final key = _expenseKey(imported);
      final existingByKey = expenseKeyMap[key];
      final existingById =
          imported.id != null ? await db.getExpenseById(imported.id!) : null;

      if (existingByKey != null) {
        if (_isNewer(imported.createdAt, existingByKey.createdAt) &&
            existingByKey.id != null) {
          final replacement = _copyExpense(imported, id: existingByKey.id);
          await db.updateExpense(replacement);
          expenseKeyMap[key] = replacement;
          updated++;
        }
        continue;
      }

      if (existingById != null) {
        if (_expenseKey(existingById) == key) {
          if (_isNewer(imported.createdAt, existingById.createdAt)) {
            final replacement = _copyExpense(imported, id: existingById.id);
            await db.updateExpense(replacement);
            expenseKeyMap[key] = replacement;
            updated++;
          }
          continue;
        }

        final inserted = _copyExpense(imported, id: null);
        final newId = await db.addExpense(inserted);
        expenseKeyMap[key] = _copyExpense(inserted, id: newId);
        added++;
        continue;
      }

      final newId = await db.addExpense(imported);
      expenseKeyMap[key] = _copyExpense(imported, id: newId);
      added++;
    }

    final existingBudgets = await db.getBudgets();
    final budgetKeyMap = {
      for (final b in existingBudgets)
        _budgetKey(b): b,
    };

    for (final map in budgetsData) {
      final item = Budget.fromMap(map);
      final key = _budgetKey(item);
      final existing = budgetKeyMap[key];
      if (existing == null) {
        await db.addBudget(item);
        added++;
      } else if (_isNewer(item.createdAt, existing.createdAt)) {
        await db.updateBudget(item);
        updated++;
      }
    }

    for (final map in alertsData) {
      final item = AlertItem.fromMap(map);
      await db.addAlert(item);
      added++;
    }

    for (final map in insightsData) {
      final item = InsightItem.fromMap(map);
      await db.addInsight(item);
      added++;
    }

    final settings = decoded['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      final prefs = await SharedPreferences.getInstance();
      if (settings['currency_symbol'] != null) {
        await prefs.setString('currency_symbol', settings['currency_symbol']);
      }
      if (settings['category_overrides'] != null) {
        await prefs.setString('category_overrides', settings['category_overrides']);
      }
      if (settings['biometric_enabled'] != null) {
        await prefs.setBool('biometric_enabled', settings['biometric_enabled'] == true);
      }
      if (settings['demo_mode'] != null) {
        await prefs.setBool('demo_mode', settings['demo_mode'] == true);
      }
    }

    return ImportResult(added: added, updated: updated);
  }

  String _expenseKey(Expense e) {
    return '${e.title}|${e.amount}|${e.date.toIso8601String()}|${e.category}';
  }

  String _budgetKey(Budget b) {
    return '${b.category}|${b.startMonth}';
  }

  bool _isNewer(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.isAfter(b);
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final db = AppDatabase();
    final expenses = await db.getExpenses();
    final budgets = await db.getBudgets();
    final alerts = await db.getAlerts();
    final insights = await db.getInsights();
    final prefs = await SharedPreferences.getInstance();

    return {
      'version': _backupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'data': {
        'expenses': expenses.map((e) => e.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'alerts': alerts.map((a) => a.toMap()).toList(),
        'insights': insights.map((i) => i.toMap()).toList(),
      },
      'settings': {
        'currency_symbol': prefs.getString('currency_symbol'),
        'category_overrides': prefs.getString('category_overrides'),
        'biometric_enabled': prefs.getBool('biometric_enabled') ?? false,
        'demo_mode': prefs.getBool('demo_mode') ?? false,
      },
    };
  }

  Expense _copyExpense(Expense source, {required int? id}) {
    return Expense(
      id: id,
      title: source.title,
      amount: source.amount,
      category: source.category,
      date: source.date,
      notes: source.notes,
      merchant: source.merchant,
      paymentMethod: source.paymentMethod,
      createdAt: source.createdAt,
    );
  }

  Future<Map<String, dynamic>> _encrypt(String plaintext, String pin) async {
    final cipher = AesGcm.with256bits();
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _deriveKey(pin, salt);
    final secretBox = await cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    return {
      'version': _backupVersion,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  Future<String> _decrypt(Map<String, dynamic> payload, String pin) async {
    final cipher = AesGcm.with256bits();
    final salt = base64Decode(payload['salt']);
    final nonce = base64Decode(payload['nonce']);
    final cipherText = base64Decode(payload['ciphertext']);
    final mac = Mac(base64Decode(payload['mac']));
    final secretKey = await _deriveKey(pin, salt);
    final box = SecretBox(cipherText, nonce: nonce, mac: mac);
    final clear = await cipher.decrypt(box, secretKey: secretKey);
    return utf8.decode(clear);
  }

  Future<SecretKey> _deriveKey(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 120000,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
  }

  List<int> _randomBytes(int length) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }
}

enum ImportStrategy { merge, replaceAll }

class ImportResult {
  final int added;
  final int updated;

  ImportResult({required this.added, required this.updated});
}
