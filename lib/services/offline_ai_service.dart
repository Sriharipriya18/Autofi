import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../widgets/category_definitions.dart';

class OfflineAiInsight {
  final String type;
  final String title;
  final String detail;
  final int priority;

  const OfflineAiInsight({
    required this.type,
    required this.title,
    required this.detail,
    required this.priority,
  });
}

class OfflineAiService {
  static const _monthlyRisePctKey = 'ai_monthly_rise_pct';
  static const _anomalyZKey = 'ai_anomaly_z';
  static const _recurringMinCountKey = 'ai_recurring_min_count';
  static const _recurringCvKey = 'ai_recurring_cv';

  static const defaultTuning = OfflineAiTuning(
    monthlyRisePercent: 25,
    anomalyZThreshold: 3.5,
    recurringMinCount: 3,
    recurringCvLimit: 0.15,
  );

  static Future<OfflineAiTuning> loadTuning() async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineAiTuning(
      monthlyRisePercent: prefs.getInt(_monthlyRisePctKey) ?? defaultTuning.monthlyRisePercent,
      anomalyZThreshold: prefs.getDouble(_anomalyZKey) ?? defaultTuning.anomalyZThreshold,
      recurringMinCount: prefs.getInt(_recurringMinCountKey) ?? defaultTuning.recurringMinCount,
      recurringCvLimit: prefs.getDouble(_recurringCvKey) ?? defaultTuning.recurringCvLimit,
    );
  }

  static Future<void> saveTuning(OfflineAiTuning tuning) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_monthlyRisePctKey, tuning.monthlyRisePercent);
    await prefs.setDouble(_anomalyZKey, tuning.anomalyZThreshold);
    await prefs.setInt(_recurringMinCountKey, tuning.recurringMinCount);
    await prefs.setDouble(_recurringCvKey, tuning.recurringCvLimit);
  }

  List<OfflineAiInsight> buildInsights({
    required List<Expense> expenses,
    required DateTime now,
    OfflineAiTuning tuning = defaultTuning,
  }) {
    final spendOnly = expenses
        .where((e) => !isIncomeCategory(e.category) && !isTransferCategory(e.category))
        .toList();

    final insights = <OfflineAiInsight>[
      ..._monthOverMonthInsights(spendOnly, now, tuning),
      ..._anomalyInsights(spendOnly, now, tuning),
      ..._subscriptionInsights(spendOnly, now, tuning),
    ];
    insights.sort((a, b) => b.priority.compareTo(a.priority));
    return insights;
  }

  List<OfflineAiInsight> _monthOverMonthInsights(
    List<Expense> expenses,
    DateTime now,
    OfflineAiTuning tuning,
  ) {
    final thisMonth = _categoryTotalsForMonth(expenses, DateTime(now.year, now.month, 1));
    final prevMonth = _categoryTotalsForMonth(expenses, DateTime(now.year, now.month - 1, 1));
    final out = <OfflineAiInsight>[];

    for (final entry in thisMonth.entries) {
      final prev = prevMonth[entry.key] ?? 0;
      if (prev <= 0 || entry.value <= prev) {
        continue;
      }
      final rise = entry.value - prev;
      final pct = (rise / prev) * 100;
      if (pct >= tuning.monthlyRisePercent) {
        out.add(
          OfflineAiInsight(
            type: 'monthly_change',
            title: '${entry.key} increased',
            detail:
                'Spending up ${pct.toStringAsFixed(0)}% vs last month (${rise.toStringAsFixed(0)} more).',
            priority: pct >= 50 ? 5 : 4,
          ),
        );
      }
    }
    return out.take(3).toList();
  }

  List<OfflineAiInsight> _anomalyInsights(
    List<Expense> expenses,
    DateTime now,
    OfflineAiTuning tuning,
  ) {
    final monthExpenses = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    if (monthExpenses.length < 6) {
      return const [];
    }

    final amounts = monthExpenses.map((e) => e.amount).toList()..sort();
    final median = _median(amounts);
    final deviations = amounts.map((a) => (a - median).abs()).toList()..sort();
    final mad = _median(deviations);
    if (mad == 0) {
      return const [];
    }

    final out = <OfflineAiInsight>[];
    for (final e in monthExpenses) {
      final robustZ = 0.6745 * (e.amount - median) / mad;
      if (robustZ >= tuning.anomalyZThreshold) {
        out.add(
          OfflineAiInsight(
            type: 'anomaly',
            title: 'Unusual transaction',
            detail:
                '${e.title} (${e.amount.toStringAsFixed(0)}) is above your normal spending range.',
            priority: robustZ >= 5 ? 5 : 4,
          ),
        );
      }
    }
    return out.take(2).toList();
  }

  List<OfflineAiInsight> _subscriptionInsights(
    List<Expense> expenses,
    DateTime now,
    OfflineAiTuning tuning,
  ) {
    final start = DateTime(now.year, now.month - 3, 1);
    final recent = expenses.where((e) => e.date.isAfter(start)).toList();
    final merchantTotals = <String, List<double>>{};

    for (final e in recent) {
      final key = (e.merchant ?? '').trim().toLowerCase();
      if (key.isEmpty) {
        continue;
      }
      merchantTotals.putIfAbsent(key, () => []);
      merchantTotals[key]!.add(e.amount);
    }

    final out = <OfflineAiInsight>[];
    for (final entry in merchantTotals.entries) {
      if (entry.value.length < tuning.recurringMinCount) {
        continue;
      }
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      final variance = _variance(entry.value, avg);
      final cv = avg == 0 ? 0 : sqrt(variance) / avg;
      if (cv < tuning.recurringCvLimit) {
        out.add(
          OfflineAiInsight(
            type: 'recurring',
            title: 'Recurring payment detected',
            detail:
                '${entry.key} appears recurring (~${avg.toStringAsFixed(0)} each cycle). Review if needed.',
            priority: 3,
          ),
        );
      }
    }
    return out.take(2).toList();
  }

  Map<String, double> _categoryTotalsForMonth(List<Expense> expenses, DateTime month) {
    final totals = <String, double>{};
    for (final e in expenses) {
      if (e.date.year == month.year && e.date.month == month.month) {
        totals[e.category] = (totals[e.category] ?? 0) + e.amount;
      }
    }
    return totals;
  }

  double _median(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final mid = values.length ~/ 2;
    if (values.length.isOdd) {
      return values[mid];
    }
    return (values[mid - 1] + values[mid]) / 2;
  }

  double _variance(List<double> values, double mean) {
    if (values.isEmpty) {
      return 0;
    }
    var sum = 0.0;
    for (final v in values) {
      final d = v - mean;
      sum += d * d;
    }
    return sum / values.length;
  }
}

class OfflineAiTuning {
  final int monthlyRisePercent;
  final double anomalyZThreshold;
  final int recurringMinCount;
  final double recurringCvLimit;

  const OfflineAiTuning({
    required this.monthlyRisePercent,
    required this.anomalyZThreshold,
    required this.recurringMinCount,
    required this.recurringCvLimit,
  });
}
