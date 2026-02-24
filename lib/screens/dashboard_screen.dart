import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/analytics_service.dart';
import '../services/offline_ai_service.dart';
import '../widgets/currency.dart';

class DashboardScreen extends StatelessWidget {
  final List<Expense> expenses;
  final String currencySymbol;

  const DashboardScreen({
    super.key,
    required this.expenses,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Budget>>(
      future: AppDatabase().getBudgets(),
      builder: (context, snapshot) {
        return FutureBuilder<OfflineAiTuning>(
          future: OfflineAiService.loadTuning(),
          builder: (context, tuningSnapshot) {
        final budgets = snapshot.data ?? [];
        final tuning = tuningSnapshot.data ?? OfflineAiService.defaultTuning;
        final service = AnalyticsService();
        final month = DateTime.now();
        final income = service.totalForMonth(expenses, month, income: true);
        final spending = service.totalForMonth(expenses, month, income: false);
        final health = service.healthScore(expenses: expenses, budgets: budgets, month: month);
        final risks = service.overspendRisks(expenses: expenses, budgets: budgets, month: month);
        final suggestions = OfflineAiService().buildInsights(
          expenses: expenses,
          now: month,
          tuning: tuning,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              income: income,
              spending: spending,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: 16),
            _HealthCard(score: health),
            const SizedBox(height: 16),
            _SectionTitle(title: 'AI Suggestions'),
            const SizedBox(height: 8),
            ...suggestions.map((item) => _SuggestionCard(item: item)),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Alerts & Predictions'),
            const SizedBox(height: 8),
            if (risks.isEmpty)
              const _EmptyCard(message: 'No active alerts right now.')
            else
              ...risks.map((risk) => _RiskCard(risk: risk, currencySymbol: currencySymbol)),
          ],
        );
          },
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income;
  final double spending;
  final String currencySymbol;

  const _SummaryRow({
    required this.income,
    required this.spending,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _MetricCard(
          label: 'Income',
          value: CurrencyFormatter.format(income, currencySymbol),
          color: scheme.tertiary,
        ),
        const SizedBox(width: 12),
        _MetricCard(
          label: 'Spending',
          value: CurrencyFormatter.format(spending, currencySymbol),
          color: scheme.error,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: scheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final HealthScore score;

  const _HealthCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.secondary.withOpacity(0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              '${score.score}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: scheme.secondary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Financial Health', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  score.label,
                  style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
  }
}

class _RiskCard extends StatelessWidget {
  final OverspendRisk risk;
  final String currencySymbol;

  const _RiskCard({required this.risk, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${risk.category} forecast exceeds budget',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            CurrencyFormatter.format(risk.forecast, currencySymbol),
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final OfflineAiInsight item;

  const _SuggestionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(item.detail, style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Text(message, style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
    );
  }
}
