import 'dart:math';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../widgets/category_definitions.dart';

class OverspendRisk {
  final String category;
  final double forecast;
  final double budget;

  OverspendRisk({
    required this.category,
    required this.forecast,
    required this.budget,
  });
}

class SuggestionItem {
  final String title;
  final String detail;

  SuggestionItem({
    required this.title,
    required this.detail,
  });
}

class HealthScore {
  final int score;
  final String label;

  HealthScore({
    required this.score,
    required this.label,
  });
}

class AnalyticsService {
  double totalForMonth(List<Expense> expenses, DateTime month, {required bool income}) {
    double total = 0;
    for (final expense in expenses) {
      if (expense.date.year == month.year && expense.date.month == month.month) {
        if (isTransferCategory(expense.category)) {
          continue;
        }
        if (isIncomeCategory(expense.category) == income) {
          total += expense.amount;
        }
      }
    }
    return total;
  }

  Map<String, double> categoryTotals(List<Expense> expenses, DateTime month) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      if (expense.date.year == month.year && expense.date.month == month.month) {
        if (!isIncomeCategory(expense.category) && !isTransferCategory(expense.category)) {
          totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
        }
      }
    }
    return totals;
  }

  List<OverspendRisk> overspendRisks({
    required List<Expense> expenses,
    required List<Budget> budgets,
    required DateTime month,
  }) {
    final risks = <OverspendRisk>[];
    final day = max(1, DateTime.now().day);
    final daysInMonth = _daysInMonth(month.year, month.month);
    final totals = categoryTotals(expenses, month);
    for (final budget in budgets) {
      if (budget.startMonth != DateFormat('yyyy-MM').format(month)) {
        continue;
      }
      final spent = totals[budget.category] ?? 0;
      final forecast = spent / day * daysInMonth;
      if (forecast > budget.monthlyLimit * 1.1) {
        risks.add(OverspendRisk(
          category: budget.category,
          forecast: forecast,
          budget: budget.monthlyLimit,
        ));
      }
    }
    return risks;
  }

  List<SuggestionItem> suggestions(List<Expense> expenses, DateTime month) {
    final suggestions = <SuggestionItem>[];
    final thisMonthTotals = categoryTotals(expenses, month);
    final lastMonth = DateTime(month.year, month.month - 1, 1);
    final lastTotals = categoryTotals(expenses, lastMonth);

    final increases = <String, double>{};
    for (final entry in thisMonthTotals.entries) {
      final last = lastTotals[entry.key] ?? 0;
      final diff = entry.value - last;
      if (diff > 0) {
        increases[entry.key] = diff;
      }
    }
    final sorted = increases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted.take(3)) {
      suggestions.add(SuggestionItem(
        title: 'Spending up in ${entry.key}',
        detail: 'You spent ${entry.value.toStringAsFixed(0)} more than last month. Consider a tighter cap.',
      ));
    }

    final recurring = _detectRecurring(expenses, month);
    for (final item in recurring) {
      suggestions.add(SuggestionItem(
        title: 'Subscription detected',
        detail: 'Recurring ${item} charges found. Review if it is still needed.',
      ));
    }

    if (suggestions.isEmpty) {
      suggestions.add(SuggestionItem(
        title: 'Keep it steady',
        detail: 'No big spikes detected. Maintain your current plan.',
      ));
    }

    return suggestions;
  }

  List<String> _detectRecurring(List<Expense> expenses, DateTime month) {
    final recent = expenses.where((e) {
      return e.date.isAfter(DateTime(month.year, month.month - 2, 1));
    }).toList();
    final Map<String, int> merchantCounts = {};
    for (final expense in recent) {
      final key = expense.merchant?.toLowerCase().trim();
      if (key == null || key.isEmpty) {
        continue;
      }
      merchantCounts[key] = (merchantCounts[key] ?? 0) + 1;
    }
    return merchantCounts.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .take(2)
        .toList();
  }

  HealthScore healthScore({
    required List<Expense> expenses,
    required List<Budget> budgets,
    required DateTime month,
  }) {
    final income = totalForMonth(expenses, month, income: true);
    final expensesTotal = totalForMonth(expenses, month, income: false);
    final savingsRate = income == 0 ? 0.0 : (income - expensesTotal) / max(1.0, income);

    double budgetScore = 1.0;
    if (budgets.isNotEmpty) {
      final totals = categoryTotals(expenses, month);
      int ok = 0;
      for (final budget in budgets) {
        if (budget.startMonth != DateFormat('yyyy-MM').format(month)) {
          continue;
        }
        final spent = totals[budget.category] ?? 0;
        if (spent <= budget.monthlyLimit) {
          ok += 1;
        }
      }
      budgetScore = ok == 0 ? 0.0 : ok / max(1, budgets.length);
    }

    final trendScore = _trendStability(expenses, month);

    final raw = (savingsRate * 40) + (budgetScore * 30) + (trendScore * 30);
    final score = raw.clamp(0, 100).round();
    final label = score >= 75
        ? 'Strong'
        : score >= 55
            ? 'Stable'
            : 'Needs Focus';

    return HealthScore(score: score, label: label);
  }

  double _trendStability(List<Expense> expenses, DateTime month) {
    final weeks = <int, double>{};
    for (final expense in expenses) {
      if (expense.date.year == month.year && expense.date.month == month.month) {
        final week = ((expense.date.day - 1) / 7).floor();
        weeks[week] = (weeks[week] ?? 0) + expense.amount;
      }
    }
    if (weeks.isEmpty) {
      return 0.0;
    }
    final values = weeks.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    double variance = 0;
    for (final v in values) {
      variance += pow(v - mean, 2).toDouble();
    }
    variance = variance / values.length;
    final normalized = mean == 0 ? 0.0 : (1 - min(variance / (mean * mean + 1), 1));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  int _daysInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final next = DateTime(year, month + 1, 1);
    return next.difference(first).inDays;
  }
}
