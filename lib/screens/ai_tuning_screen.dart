import 'package:flutter/material.dart';
import '../services/offline_ai_service.dart';

class AiTuningScreen extends StatefulWidget {
  const AiTuningScreen({super.key});

  @override
  State<AiTuningScreen> createState() => _AiTuningScreenState();
}

class _AiTuningScreenState extends State<AiTuningScreen> {
  int _monthlyRise = OfflineAiService.defaultTuning.monthlyRisePercent;
  double _anomalyZ = OfflineAiService.defaultTuning.anomalyZThreshold;
  int _recurringMin = OfflineAiService.defaultTuning.recurringMinCount;
  double _recurringCv = OfflineAiService.defaultTuning.recurringCvLimit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tuning = await OfflineAiService.loadTuning();
    final monthlyRise = tuning.monthlyRisePercent.clamp(10, 80);
    final anomalyZ = tuning.anomalyZThreshold.clamp(2.5, 6.0);
    final recurringMin = tuning.recurringMinCount.clamp(2, 6);
    final recurringCv = tuning.recurringCvLimit.clamp(0.05, 0.40);
    if (!mounted) {
      return;
    }
    setState(() {
      _monthlyRise = monthlyRise;
      _anomalyZ = anomalyZ;
      _recurringMin = recurringMin;
      _recurringCv = recurringCv;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final tuning = OfflineAiTuning(
      monthlyRisePercent: _monthlyRise,
      anomalyZThreshold: _anomalyZ,
      recurringMinCount: _recurringMin,
      recurringCvLimit: _recurringCv,
    );
    await OfflineAiService.saveTuning(tuning);
    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _resetDefaults() async {
    await OfflineAiService.saveTuning(OfflineAiService.defaultTuning);
    setState(() {
      _monthlyRise = OfflineAiService.defaultTuning.monthlyRisePercent;
      _anomalyZ = OfflineAiService.defaultTuning.anomalyZThreshold;
      _recurringMin = OfflineAiService.defaultTuning.recurringMinCount;
      _recurringCv = OfflineAiService.defaultTuning.recurringCvLimit;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tuning (Offline)'),
        actions: [
          TextButton(onPressed: _resetDefaults, child: const Text('Reset')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: const Text(
              'Tune local AI behavior. No internet, no cloud model. Changes apply to dashboard suggestions and AI insights.',
            ),
          ),
          const SizedBox(height: 16),
          _sliderCard(
            context: context,
            title: 'Monthly rise threshold',
            subtitle: 'Alert when month-over-month increase crosses this %',
            valueLabel: '$_monthlyRise%',
            child: Slider(
              value: _monthlyRise.toDouble(),
              min: 10,
              max: 80,
              divisions: 14,
              label: '$_monthlyRise%',
              onChanged: (v) => setState(() => _monthlyRise = v.round()),
            ),
          ),
          const SizedBox(height: 12),
          _sliderCard(
            context: context,
            title: 'Anomaly sensitivity',
            subtitle: 'Lower value = more anomaly alerts',
            valueLabel: _anomalyZ.toStringAsFixed(1),
            child: Slider(
              value: _anomalyZ,
              min: 2.5,
              max: 6.0,
              divisions: 14,
              label: _anomalyZ.toStringAsFixed(1),
              onChanged: (v) => setState(() => _anomalyZ = v),
            ),
          ),
          const SizedBox(height: 12),
          _sliderCard(
            context: context,
            title: 'Recurring minimum hits',
            subtitle: 'How many repeated charges before marking recurring',
            valueLabel: _recurringMin.toString(),
            child: Slider(
              value: _recurringMin.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              label: _recurringMin.toString(),
              onChanged: (v) => setState(() => _recurringMin = v.round()),
            ),
          ),
          const SizedBox(height: 12),
          _sliderCard(
            context: context,
            title: 'Recurring variance limit',
            subtitle: 'Lower value = stricter recurring match',
            valueLabel: _recurringCv.toStringAsFixed(2),
            child: Slider(
              value: _recurringCv,
              min: 0.05,
              max: 0.40,
              divisions: 14,
              label: _recurringCv.toStringAsFixed(2),
              onChanged: (v) => setState(() => _recurringCv = v),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save and Apply'),
          ),
        ],
      ),
    );
  }

  Widget _sliderCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String valueLabel,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(valueLabel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: scheme.onSurface.withOpacity(0.65), fontSize: 12),
          ),
          child,
        ],
      ),
    );
  }
}
