import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/expense.dart';
import '../models/alert_item.dart';
import '../services/offline_ai_service.dart';

class AiSuggestionsScreen extends StatefulWidget {
  final List<Expense> expenses;

  const AiSuggestionsScreen({
    super.key,
    required this.expenses,
  });

  @override
  State<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends State<AiSuggestionsScreen> {
  late Future<List<AlertItem>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _alertsFuture = AppDatabase().getAlerts();
  }

  Future<void> _markRead(AlertItem alert) async {
    final updated = AlertItem(
      id: alert.id,
      type: alert.type,
      message: alert.message,
      category: alert.category,
      createdAt: alert.createdAt,
      isRead: true,
    );
    await AppDatabase().updateAlert(updated);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OfflineAiTuning>(
      future: OfflineAiService.loadTuning(),
      builder: (context, snapshot) {
        final tuning = snapshot.data ?? OfflineAiService.defaultTuning;
        final suggestions = OfflineAiService().buildInsights(
          expenses: widget.expenses,
          now: DateTime.now(),
          tuning: tuning,
        );
        return FutureBuilder<List<AlertItem>>(
          future: _alertsFuture,
          builder: (context, alertSnapshot) {
            final alerts = alertSnapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                const Text(
                  'AI Suggestions',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...suggestions.map((item) => _SuggestionCard(item: item)),
                const SizedBox(height: 16),
                const Text(
                  'Alerts & Predictions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (alerts.isEmpty)
                  const _EmptyAlertCard()
                else
                  ...alerts.map((alert) => _AlertCard(alert: alert, onRead: () => _markRead(alert))),
              ],
            );
          },
        );
      },
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

class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback onRead;

  const _AlertCard({required this.alert, required this.onRead});

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
          Icon(alert.isRead ? Icons.check_circle : Icons.notifications_active,
              color: alert.isRead ? scheme.tertiary : scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (!alert.isRead)
            TextButton(onPressed: onRead, child: const Text('Mark read')),
        ],
      ),
    );
  }
}

class _EmptyAlertCard extends StatelessWidget {
  const _EmptyAlertCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Text(
        'No alerts yet. We will notify you if a budget risk is detected.',
        style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
      ),
    );
  }
}
