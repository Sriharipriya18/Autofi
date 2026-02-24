import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../widgets/currency.dart';
import '../widgets/category_definitions.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onSettingsTap;
  final String currencySymbol;

  const ProfileScreen({
    super.key,
    required this.onSettingsTap,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: AuthService().getUsername(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Guest';
        return FutureBuilder<List<Expense>>(
          future: AppDatabase().getExpenses(),
          builder: (context, expenseSnap) {
            final expenses = expenseSnap.data ?? [];
            final analytics = AnalyticsService();
            final month = DateTime.now();
            final totals = analytics.categoryTotals(expenses, month);
            final trend = _buildWeeklyTrend(expenses, month);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                const Text(
                  'Me',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: scheme.surface.withOpacity(0.7),
                          borderRadius: const BorderRadius.all(Radius.circular(18)),
                        ),
                        child: Icon(Icons.person, color: scheme.secondary, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _OptionCard(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: onSettingsTap,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Spend Snapshot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _ChartCard(
                  title: 'Monthly Spending',
                  child: _MonthlyBarChart(
                    data: _buildMonthlyTrend(expenses),
                    currencySymbol: currencySymbol,
                  ),
                ),
                const SizedBox(height: 12),
                _ChartCard(
                  title: 'Category Donut',
                  child: _DonutChart(totals: totals),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<_BarPoint> _buildMonthlyTrend(List<Expense> expenses) {
    final now = DateTime.now();
    final totals = List<double>.filled(6, 0);
    for (final expense in expenses) {
      if (isIncomeCategory(expense.category) || isTransferCategory(expense.category)) {
        continue;
      }
      final diffMonths = (now.year - expense.date.year) * 12 + (now.month - expense.date.month);
      if (diffMonths >= 0 && diffMonths < 6) {
        totals[5 - diffMonths] += expense.amount;
      }
    }
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i), 1);
      final label = '${month.month}/${month.year % 100}';
      return _BarPoint(label: label, value: totals[i]);
    });
  }

  List<_BarPoint> _buildWeeklyTrend(List<Expense> expenses, DateTime month) {
    final totals = <int, double>{};
    for (final expense in expenses) {
      if (expense.date.year == month.year && expense.date.month == month.month) {
        if (isIncomeCategory(expense.category) || isTransferCategory(expense.category)) {
          continue;
        }
        final week = ((expense.date.day - 1) / 7).floor();
        totals[week] = (totals[week] ?? 0) + expense.amount;
      }
    }
    return List.generate(4, (i) {
      final value = totals[i] ?? 0;
      return _BarPoint(label: 'W${i + 1}', value: value);
    });
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.7),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(icon, color: scheme.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<_BarPoint> data;
  final String currencySymbol;

  const _MonthlyBarChart({required this.data, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 100),
                  painter: _MonthlyBarPainter(
                    data: data,
                    color: scheme.secondary,
                    currencySymbol: currencySymbol,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: data
                .map(
                  (point) => Expanded(
                    child: Text(
                      point.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final Map<String, double> totals;

  const _DonutChart({required this.totals});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = totals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return Text('No spending data yet.', style: TextStyle(color: scheme.onSurface.withOpacity(0.6)));
    }
    final top = entries.take(4).toList();
    final otherTotal = entries.skip(4).fold(0.0, (a, b) => a + b.value);
    if (otherTotal > 0) {
      top.add(MapEntry('Other', otherTotal));
    }
    final colors = top.map((entry) {
      final category = categoryByLabel(entry.key);
      return category?.color ?? scheme.secondary;
    }).toList();
    final values = top.map((e) => e.value).toList();
    final totalSum = values.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 160,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxHeight < constraints.maxWidth
                  ? constraints.maxHeight
                  : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _DonutPainter(values: values, colors: colors),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(top.length, (index) {
          final entry = top[index];
          final percent = totalSum == 0 ? 0 : (entry.value / totalSum * 100);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text('${percent.toStringAsFixed(0)}%'),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return;
    }
    final radius = (size.shortestSide / 2) - 10;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    double start = -1.5708;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.28318;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _MonthlyBarPainter extends CustomPainter {
  final List<_BarPoint> data;
  final Color color;
  final String currencySymbol;

  _MonthlyBarPainter({
    required this.data,
    required this.color,
    required this.currencySymbol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      return;
    }
    final maxValue = data.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final barCount = data.length;
    final barWidth = (size.width / barCount) * 0.5;
    final spacing = (size.width / barCount) - barWidth;
    final paint = Paint()..color = color;
    final radius = const Radius.circular(8);
    for (var i = 0; i < barCount; i++) {
      final value = data[i].value;
      final height = maxValue == 0 ? 4.0 : (value / maxValue) * (size.height - 6) + 4;
      final x = i * (barWidth + spacing) + spacing / 2;
      final rect = Rect.fromLTWH(x, size.height - height, barWidth, height);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(rrect, paint);

      final label = value == 0 ? '' : value.toStringAsFixed(0);
      if (label.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$currencySymbol$label',
            style: TextStyle(fontSize: 10, color: color),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout(maxWidth: barWidth + spacing);
        final offset = Offset(
          x + (barWidth - textPainter.width) / 2,
          size.height - height - 12,
        );
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyBarPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.currencySymbol != currencySymbol;
  }
}

class _BarPoint {
  final String label;
  final double value;

  _BarPoint({required this.label, required this.value});
}
