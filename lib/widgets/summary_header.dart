import 'package:flutter/material.dart';
import 'currency.dart';

class SummaryHeader extends StatelessWidget {
  final double expenses;
  final double income;
  final double balance;
  final String selectedMonth;
  final List<String> monthOptions;
  final ValueChanged<String> onMonthChanged;
  final VoidCallback onCalendarPressed;
  final String currencySymbol;

  const SummaryHeader({
    super.key,
    required this.expenses,
    required this.income,
    required this.balance,
    required this.selectedMonth,
    required this.monthOptions,
    required this.onMonthChanged,
    required this.onCalendarPressed,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Autofi',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMonth,
                  dropdownColor: scheme.surface,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: TextStyle(color: scheme.onSurface),
                  onChanged: (value) {
                    if (value != null) {
                      onMonthChanged(value);
                    }
                  },
                  items: monthOptions
                      .map(
                        (month) => DropdownMenuItem<String>(
                          value: month,
                          child: Text(
                            month,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onCalendarPressed,
              icon: const Icon(Icons.calendar_month),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SummaryCard(
              label: 'Expenses',
              value: CurrencyFormatter.format(expenses, currencySymbol),
              color: scheme.error,
            ),
            const SizedBox(width: 12),
            _SummaryCard(
              label: 'Income',
              value: CurrencyFormatter.format(income, currencySymbol),
              color: scheme.tertiary,
            ),
            const SizedBox(width: 12),
            _BalanceCard(
              label: 'Balance',
              value: CurrencyFormatter.format(balance, currencySymbol),
              balance: balance,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    final shadow = Theme.of(context).shadowColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: shadow.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final String value;
  final double balance;

  const _BalanceCard({
    required this.label,
    required this.value,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    final shadow = Theme.of(context).shadowColor;
    final glowColor = balance > 0
        ? const Color(0xFF22C55E)
        : balance < 0
            ? const Color(0xFFF87171)
            : scheme.onSurface.withOpacity(0.35);
    final glowStrength = balance == 0 ? 0.0 : 0.45;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: shadow.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            if (glowStrength > 0)
              BoxShadow(
                color: glowColor.withOpacity(glowStrength),
                blurRadius: 18,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: balance > 0
                    ? const Color(0xFF22C55E)
                    : balance < 0
                        ? const Color(0xFFF87171)
                        : muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
