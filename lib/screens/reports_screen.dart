import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/category_definitions.dart';
import '../widgets/currency.dart';
import '../widgets/empty_state.dart';

class ReportsScreen extends StatelessWidget {
  final List<Expense> expenses;
  final String currencySymbol;

  const ReportsScreen({
    super.key,
    required this.expenses,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: const [
          Text(
            'Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 20),
          EmptyStateCard(
            title: 'No records yet',
            subtitle: 'Add your first transaction',
            icon: Icons.bar_chart_outlined,
          ),
        ],
      );
    }
    final totals = _calculateTotals(expenses);
    return DefaultTabController(
      length: 2,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          const Text(
            'Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TabBar(
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: const [
              Tab(text: 'Analytics'),
              Tab(text: 'Accounts'),
            ],
          ),
          SizedBox(
            height: 480,
            child: TabBarView(
              children: [
                _AnalyticsTab(
                  totals: totals,
                  currencySymbol: currencySymbol,
                ),
                _AccountsTab(currencySymbol: currencySymbol),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  final _Totals totals;
  final String currencySymbol;

  const _AnalyticsTab({
    required this.totals,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final budget = totals.expenses * 1.4;
    final remaining = (budget - totals.expenses).clamp(0, budget).toDouble();
    final percent = budget == 0 ? 0.0 : totals.expenses / budget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Monthly Statistics',
          child: Row(
            children: [
              _StatItem(
                label: 'Expenses',
                value: CurrencyFormatter.format(totals.expenses, currencySymbol),
                color: scheme.error,
              ),
              _StatItem(
                label: 'Income',
                value: CurrencyFormatter.format(totals.income, currencySymbol),
                color: scheme.tertiary,
              ),
              _StatItem(
                label: 'Balance',
                value: CurrencyFormatter.format(totals.balance, currencySymbol),
                color: scheme.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Budget',
          child: Row(
            children: [
              SizedBox(
                height: 90,
                width: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percent.clamp(0, 1),
                      strokeWidth: 10,
                      backgroundColor: scheme.surface.withOpacity(0.6),
                      color: scheme.secondary,
                    ),
                    Center(
                      child: Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BudgetRow(
                      label: 'Remaining',
                      value: CurrencyFormatter.format(remaining, currencySymbol),
                      color: scheme.tertiary,
                    ),
                    _BudgetRow(
                      label: 'Budget',
                      value: CurrencyFormatter.format(budget, currencySymbol),
                      color: scheme.secondary,
                    ),
                    _BudgetRow(
                      label: 'Expenses',
                      value: CurrencyFormatter.format(totals.expenses, currencySymbol),
                      color: scheme.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountsTab extends StatelessWidget {
  final String currencySymbol;

  const _AccountsTab({required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Accounts',
          child: Column(
            children: [
              _AccountRow(name: 'Cash', balance: 1250, currencySymbol: currencySymbol),
              _AccountRow(name: 'Bank', balance: 4880, currencySymbol: currencySymbol),
              _AccountRow(name: 'Card', balance: 860, currencySymbol: currencySymbol),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String name;
  final double balance;
  final String currencySymbol;

  const _AccountRow({
    required this.name,
    required this.balance,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.7),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(Icons.account_balance_wallet, size: 18, color: scheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            CurrencyFormatter.format(balance, currencySymbol),
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: muted),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Totals {
  final double expenses;
  final double income;
  final double balance;

  const _Totals({
    required this.expenses,
    required this.income,
    required this.balance,
  });
}

_Totals _calculateTotals(List<Expense> expenses) {
  double totalExpenses = 0;
  double totalIncome = 0;
  for (final expense in expenses) {
    if (isIncomeCategory(expense.category)) {
      totalIncome += expense.amount;
    } else {
      totalExpenses += expense.amount;
    }
  }
  return _Totals(
    expenses: totalExpenses,
    income: totalIncome,
    balance: totalIncome - totalExpenses,
  );
}
