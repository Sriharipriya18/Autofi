import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/recovery_questions.dart';
import 'home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _incomeController = TextEditingController();
  final _recoveryAnswer1 = TextEditingController();
  final _recoveryAnswer2 = TextEditingController();
  String _recoveryQuestion1 = kRecoveryQuestions.first;
  String _recoveryQuestion2 = kRecoveryQuestions[1];
  bool _enableBiometrics = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    _incomeController.dispose();
    _recoveryAnswer1.dispose();
    _recoveryAnswer2.dispose();
    super.dispose();
  }

  Future<void> _setPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pin.length < 4) {
      _showError('PIN must be at least 4 digits.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    final income = double.tryParse(_incomeController.text.trim());
    if (income == null || income <= 0) {
      _showError('Please enter your average monthly income.');
      return;
    }
    if (pin != confirm) {
      _showError('PINs do not match.');
      return;
    }
    if (_recoveryQuestion1 == _recoveryQuestion2) {
      _showError('Choose two different recovery questions.');
      return;
    }
    if (_recoveryAnswer1.text.trim().isEmpty || _recoveryAnswer2.text.trim().isEmpty) {
      _showError('Please answer both recovery questions.');
      return;
    }
    setState(() => _isSaving = true);
    await AuthService().setPin(pin);
    await AuthService().setUsername(_nameController.text.trim());
    await AuthService().setAvgMonthlyIncome(income);
    await AuthService().setRecoveryQuestions(
      questions: [_recoveryQuestion1, _recoveryQuestion2],
      answers: [_recoveryAnswer1.text, _recoveryAnswer2.text],
    );
    await AuthService().setBiometricsEnabled(_enableBiometrics);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _continueDemo() async {
    await AuthService().setDemoMode(true);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN setup'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const Text(
              'Secure your wallet',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'Set a local PIN to protect your expense data.',
              style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Average monthly income'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Create PIN'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recovery questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _recoveryQuestion1,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Question 1'),
              items: kRecoveryQuestions
                  .map(
                    (q) => DropdownMenuItem(
                      value: q,
                      child: Text(q, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _recoveryQuestion1 = value);
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recoveryAnswer1,
              decoration: const InputDecoration(labelText: 'Answer 1'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _recoveryQuestion2,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Question 2'),
              items: kRecoveryQuestions
                  .map(
                    (q) => DropdownMenuItem(
                      value: q,
                      child: Text(q, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _recoveryQuestion2 = value);
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recoveryAnswer2,
              decoration: const InputDecoration(labelText: 'Answer 2'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _enableBiometrics,
              onChanged: (value) => setState(() => _enableBiometrics = value),
              title: const Text('Enable biometrics'),
              subtitle: const Text('Use fingerprint or face unlock when available.'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _setPin,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Set PIN'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSaving ? null : _continueDemo,
              child: const Text('Continue as Demo'),
            ),
          ],
        ),
      ),
    );
  }
}
