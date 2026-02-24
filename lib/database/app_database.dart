import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/alert_item.dart';
import '../models/insight_item.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_manager.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          '''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT,
            merchant TEXT,
            payment_method TEXT,
            created_at TEXT
          )
          ''',
        );
        await _createBudgetsTable(db);
        await _createAlertsTable(db);
        await _createInsightsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumnIfMissing(db, 'expenses', 'notes TEXT');
          await _addColumnIfMissing(db, 'expenses', 'merchant TEXT');
          await _addColumnIfMissing(db, 'expenses', 'payment_method TEXT');
          await _addColumnIfMissing(db, 'expenses', 'created_at TEXT');
          await _createBudgetsTable(db);
          await _createAlertsTable(db);
          await _createInsightsTable(db);
        }
      },
    );
  }

  Future<void> _addColumnIfMissing(Database db, String table, String columnDef) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDef');
    } catch (_) {
      // Column probably exists; ignore.
    }
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        monthly_limit REAL NOT NULL,
        start_month TEXT NOT NULL,
        auto_generated INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
      ''',
    );
  }

  Future<void> _createAlertsTable(Database db) async {
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS alerts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        category TEXT,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL
      )
      ''',
    );
  }

  Future<void> _createInsightsTable(Database db) async {
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS insights(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
      ''',
    );
  }

  Future<int> addExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final maps = await db.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return Expense.fromMap(maps.first);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    if (expense.id == null) {
      return 0;
    }
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> clearExpenses() async {
    final db = await database;
    await db.delete('expenses');
  }

  Future<int> addBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    if (budget.id == null) {
      return 0;
    }
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('budgets');
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<int> clearBudgets() async {
    final db = await database;
    return await db.delete('budgets');
  }

  Future<int> addAlert(AlertItem alert) async {
    final db = await database;
    return await db.insert('alerts', alert.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AlertItem>> getAlerts({bool unreadOnly = false}) async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: unreadOnly ? 'is_read = 0' : null,
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AlertItem.fromMap(maps[i]));
  }

  Future<int> updateAlert(AlertItem alert) async {
    final db = await database;
    if (alert.id == null) {
      return 0;
    }
    return await db.update(
      'alerts',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<int> clearAlerts() async {
    final db = await database;
    return await db.delete('alerts');
  }

  Future<int> addInsight(InsightItem insight) async {
    final db = await database;
    return await db.insert('insights', insight.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<InsightItem>> getInsights() async {
    final db = await database;
    final maps = await db.query('insights', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => InsightItem.fromMap(maps[i]));
  }

  Future<int> clearInsights() async {
    final db = await database;
    return await db.delete('insights');
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('budgets');
    await db.delete('alerts');
    await db.delete('insights');
  }
}
