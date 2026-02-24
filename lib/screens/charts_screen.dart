import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../widgets/category_definitions.dart';
import '../widgets/currency.dart';
import '../widgets/empty_state.dart';

enum ChartRange { week, month, year }

class ChartsScreen extends StatefulWidget {
  final List<Expense> expenses;
  final DateTime selectedDate;
  final String currencySymbol;

  const ChartsScreen({
    super.key,
    required this.expenses,
    required this.selectedDate,
    required this.currencySymbol,
  });

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  ChartRange _range = ChartRange.month;
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.expenses
        .where((e) => !isIncomeCategory(e.category) && !isTransferCategory(e.category))
        .toList();
    final hasData = filtered.isNotEmpty;
    final bars = _buildBarData(filtered, _range, widget.selectedDate);
    final pie = _buildPieData(filtered);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            const Text(
              'Charts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ChartRange>(
              segments: const [
                ButtonSegment(value: ChartRange.week, label: Text('Week')),
                ButtonSegment(value: ChartRange.month, label: Text('Month')),
                ButtonSegment(value: ChartRange.year, label: Text('Year')),
              ],
              selected: <ChartRange>{_range},
              onSelectionChanged: (value) {
                setState(() => _range = value.first);
              },
            ),
            const SizedBox(height: 20),
            if (!hasData)
              const EmptyStateCard(
                title: 'No records yet',
                subtitle: 'Add your first transaction',
                icon: Icons.pie_chart_outline,
              )
            else ...[
              _ChartCard(
                title: 'Expenses Over Time',
                child: RepaintBoundary(child: _BarChart(bars: bars)),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Category Distribution',
                child: RepaintBoundary(
                  child: _PieChart(
                    data: pie,
                    currencySymbol: widget.currencySymbol,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_BarData> _buildBarData(List<Expense> expenses, ChartRange range, DateTime anchor) {
    final now = anchor;
    if (range == ChartRange.week) {
      return List.generate(7, (index) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
        final label = DateFormat('E').format(day);
        final total = _sumForDay(expenses, day);
        return _BarData(label: label, value: total);
      });
    }
    if (range == ChartRange.year) {
      return List.generate(12, (index) {
        final month = DateTime(now.year, now.month - (11 - index));
        final label = DateFormat('MMM').format(month);
        final total = _sumForMonth(expenses, month);
        return _BarData(label: label, value: total);
      });
    }
    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - (5 - index));
      final label = DateFormat('MMM').format(month);
      final total = _sumForMonth(expenses, month);
      return _BarData(label: label, value: total);
    });
  }

  Map<String, double> _buildPieData(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  double _sumForDay(List<Expense> expenses, DateTime day) {
    double total = 0;
    for (final expense in expenses) {
      if (DateUtils.isSameDay(expense.date, day)) {
        total += expense.amount;
      }
    }
    return total;
  }

  double _sumForMonth(List<Expense> expenses, DateTime month) {
    double total = 0;
    for (final expense in expenses) {
      if (expense.date.year == month.year && expense.date.month == month.month) {
        total += expense.amount;
      }
    }
    return total;
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shadow = Theme.of(context).shadowColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: shadow.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final double value;

  const _BarData({required this.label, required this.value});
}

class _BarChart extends StatelessWidget {
  final List<_BarData> bars;

  const _BarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    final maxValue = bars.map((b) => b.value).fold<double>(0, max);
    return SizedBox(
      height: 180,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = (constraints.maxWidth / bars.length).clamp(32, 60).toDouble();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: bars.map((bar) {
              final heightFactor = maxValue == 0 ? 0.05 : (bar.value / maxValue).clamp(0.05, 1.0);
              return SizedBox(
                width: barWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 140 * heightFactor,
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bar.label,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _PieChart extends StatefulWidget {
  final Map<String, double> data;
  final String currencySymbol;

  const _PieChart({
    required this.data,
    required this.currencySymbol,
  });

  @override
  State<_PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<_PieChart> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late final AnimationController _highlightController;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    final total = widget.data.values.fold<double>(0, (sum, value) => sum + value);
    final entries = widget.data.entries.where((entry) => entry.value > 0).toList();
    final slices = _buildSlices(entries, total == 0 ? 1 : total);
    final selected = _selectedIndex != null && _selectedIndex! < slices.length
        ? slices[_selectedIndex!]
        : null;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleTap(details, constraints.biggest, slices),
                child: AnimatedBuilder(
                  animation: _highlightController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _PiePainter(
                        slices: slices,
                        highlight: _highlightController.value,
                        selectedIndex: _selectedIndex,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: selected == null
                              ? Text(
                                  CurrencyFormatter.format(total, widget.currencySymbol),
                                  key: const ValueKey('total'),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                )
                              : Column(
                                  key: ValueKey(selected.label),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selected.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      CurrencyFormatter.format(
                                        selected.value,
                                        widget.currencySymbol,
                                      ),
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(selected.value / (total == 0 ? 1 : total) * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 12, color: muted),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ...slices.take(5).toList().asMap().entries.map((entry) {
          final slice = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: slice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slice.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  '${(slice.value / (total == 0 ? 1 : total) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<_PieSlice> _buildSlices(List<MapEntry<String, double>> entries, double total) {
    double start = -pi / 2;
    return entries.asMap().entries.map((entry) {
      final label = entry.value.key;
      final value = entry.value.value;
      final sweep = (value / total) * 2 * pi;
      final color = categoryByLabel(label)?.color ?? Theme.of(context).colorScheme.secondary;
      final slice = _PieSlice(
        label: label,
        value: value,
        color: color,
        startAngle: start,
        sweepAngle: sweep,
      );
      start += sweep;
      return slice;
    }).toList();
  }

  void _handleTap(TapDownDetails details, Size size, List<_PieSlice> slices) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final local = details.localPosition;
    final distance = (local - center).distance;
    if (distance > radius) {
      _resetSelection();
      return;
    }
    double angle = atan2(local.dy - center.dy, local.dx - center.dx);
    angle = angle + (pi / 2);
    if (angle < 0) {
      angle += 2 * pi;
    }
    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final start = slice.startAngle + pi / 2;
      final end = start + slice.sweepAngle;
      if (angle >= start && angle <= end) {
        if (_selectedIndex != i) {
          setState(() => _selectedIndex = i);
          _highlightController.forward(from: 0);
        }
        return;
      }
    }
    _resetSelection();
  }

  void _resetSelection() {
    if (_selectedIndex != null) {
      setState(() => _selectedIndex = null);
      _highlightController.reverse(from: 1);
    }
  }
}

class _PiePainter extends CustomPainter {
  final List<_PieSlice> slices;
  final double highlight;
  final int? selectedIndex;

  _PiePainter({
    required this.slices,
    required this.highlight,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final isSelected = selectedIndex == i;
      final boost = isSelected ? 8 * highlight : 0;
      final rect = Rect.fromCircle(center: center, radius: radius + boost);
      paint.color = slice.color;
      canvas.drawArc(rect, slice.startAngle, slice.sweepAngle, true, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.highlight != highlight ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _PieSlice {
  final String label;
  final double value;
  final Color color;
  final double startAngle;
  final double sweepAngle;

  const _PieSlice({
    required this.label,
    required this.value,
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
  });
}
