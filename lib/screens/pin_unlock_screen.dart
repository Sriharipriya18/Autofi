import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'pin_setup_screen.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final _pinController = TextEditingController();
  bool _isChecking = false;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  final _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    final enabled = await AuthService().isBiometricsEnabled();
    final available = await _isBiometricAvailable();
    setState(() {
      _biometricsEnabled = enabled;
      _biometricsAvailable = available;
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      _showError('Enter your PIN.');
      return;
    }
    setState(() => _isChecking = true);
    final ok = await AuthService().verifyPin(pin);
    setState(() => _isChecking = false);
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showError('Invalid PIN.');
    }
  }

  Future<void> _unlockWithBiometrics() async {
    try {
      final available = await _isBiometricAvailable();
      if (!available) {
        _showError('Biometrics not available on this device.');
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock your expense manager',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!mounted) {
        return;
      }
      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on PlatformException catch (e) {
      _showError(e.message ?? 'Biometric auth failed.');
    } catch (_) {
      _showError('Biometric auth failed.');
    }
  }

  Future<bool> _isBiometricAvailable() async {
    final isSupported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    if (!isSupported || !canCheck) {
      return false;
    }
    final available = await _auth.getAvailableBiometrics();
    return available.isNotEmpty;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock'),
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
              'Welcome back',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your PIN to unlock your data.',
              style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'PIN'),
              onSubmitted: (_) => _unlockWithPin(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isChecking ? null : _unlockWithPin,
              child: _isChecking
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unlock'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _resetPinFlow,
              child: const Text('Forgot PIN? Reset'),
            ),
            if (_biometricsEnabled && _biometricsAvailable) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _unlockWithBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use Biometrics'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resetPinFlow() async {
    final questions = await AuthService().getRecoveryQuestions();
    if (questions.length < 2) {
      _showError('No recovery questions found. Reset from Settings.');
      return;
    }
    final answer1 = TextEditingController();
    final answer2 = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(questions[0]),
            const SizedBox(height: 8),
            TextField(
              controller: answer1,
              decoration: const InputDecoration(labelText: 'Answer 1'),
            ),
            const SizedBox(height: 12),
            Text(questions[1]),
            const SizedBox(height: 8),
            TextField(
              controller: answer2,
              decoration: const InputDecoration(labelText: 'Answer 2'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await AuthService()
          .verifyRecoveryAnswers([answer1.text, answer2.text]);
      if (!ok) {
        _showError('Recovery answers did not match.');
        return;
      }
      await AuthService().clearPin();
      await AuthService().setDemoMode(false);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
    }
  }
}
