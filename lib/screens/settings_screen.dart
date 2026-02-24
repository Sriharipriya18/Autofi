import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../database/app_database.dart';
import '../services/backup_service.dart';
import '../services/auth_service.dart';
import '../services/recovery_questions.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'pin_setup_screen.dart';
import 'ai_tuning_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currencySymbol;

  const SettingsScreen({
    super.key,
    required this.currencySymbol,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _currencyOptions = <Map<String, String>>[
    {'label': 'INR (₹)', 'value': '₹'},
    {'label': 'USD (\$)', 'value': r'$'},
    {'label': 'EUR (€)', 'value': '€'},
    {'label': 'GBP (£)', 'value': '£'},
  ];

  late String _selectedCurrency;
  bool _biometricsEnabled = false;
  bool _isDemoMode = false;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currencySymbol;
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    final auth = AuthService();
    final demo = await auth.isDemoMode();
    final enabled = await AuthService().isBiometricsEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _isDemoMode = demo;
      _biometricsEnabled = enabled;
    });
  }

  Future<void> _saveCurrency(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
  }

  Future<void> _openAiTuning() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AiTuningScreen()),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text('This will delete all records. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AppDatabase().clearAll();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<String?> _promptForPin({required String title}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePin() async {
    final currentPin = await _promptForPin(title: 'Enter current PIN');
    if (currentPin == null || currentPin.isEmpty) {
      return;
    }
    final ok = await AuthService().verifyPin(currentPin);
    if (!ok && mounted) {
      _showInfo('Invalid PIN.');
      return;
    }
    final newPin = await _promptForPin(title: 'Set new PIN');
    if (newPin == null || newPin.length < 4) {
      if (mounted) {
        _showInfo('PIN must be at least 4 digits.');
      }
      return;
    }
    await AuthService().setPin(newPin);
    if (mounted) {
      _showInfo('PIN updated.');
    }
  }

  Future<void> _changeName() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed == true) {
      final name = controller.text.trim();
      if (name.isEmpty) {
        _showInfo('Name cannot be empty.');
        return;
      }
      await AuthService().setUsername(name);
      if (mounted) {
        _showInfo('Name updated.');
      }
    }
  }

  Future<void> _changeIncome() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update average income'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Average monthly income'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed == true) {
      final value = double.tryParse(controller.text.trim());
      if (value == null || value <= 0) {
        _showInfo('Enter a valid income amount.');
        return;
      }
      await AuthService().setAvgMonthlyIncome(value);
      if (mounted) {
        _showInfo('Income updated.');
      }
    }
  }

  Future<void> _updateRecoveryQuestions() async {
    final currentPin = await _promptForPin(title: 'Enter current PIN');
    if (currentPin == null || currentPin.isEmpty) {
      return;
    }
    final ok = await AuthService().verifyPin(currentPin);
    if (!ok && mounted) {
      _showInfo('Invalid PIN.');
      return;
    }
    final question1 = ValueNotifier<String>(kRecoveryQuestions.first);
    final question2 = ValueNotifier<String>(kRecoveryQuestions[1]);
    final answer1 = TextEditingController();
    final answer2 = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Recovery Questions'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: question1.value,
                decoration: const InputDecoration(labelText: 'Question 1'),
                items: kRecoveryQuestions
                    .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => question1.value = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: answer1,
                decoration: const InputDecoration(labelText: 'Answer 1'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: question2.value,
                decoration: const InputDecoration(labelText: 'Question 2'),
                items: kRecoveryQuestions
                    .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => question2.value = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: answer2,
                decoration: const InputDecoration(labelText: 'Answer 2'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true) {
      if (question1.value == question2.value) {
        _showInfo('Choose two different questions.');
        return;
      }
      if (answer1.text.trim().isEmpty || answer2.text.trim().isEmpty) {
        _showInfo('Please answer both questions.');
        return;
      }
      await AuthService().setRecoveryQuestions(
        questions: [question1.value, question2.value],
        answers: [answer1.text, answer2.text],
      );
      if (mounted) {
        _showInfo('Recovery questions updated.');
      }
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      if (!isSupported || !canCheck || available.isEmpty) {
        if (mounted) {
          _showInfo('Biometrics are not available on this device.');
        }
        return;
      }
    }
    await AuthService().setBiometricsEnabled(value);
    setState(() => _biometricsEnabled = value);
  }

  Future<void> _goToCreateAccount() async {
    await AuthService().setDemoMode(false);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      (route) => false,
    );
  }

  Future<void> _exitDemoMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Demo Mode'),
        content: const Text('You will leave demo mode and return to account setup.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await AuthService().setDemoMode(false);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      (route) => false,
    );
  }

  Future<void> _backupData() async {
    final filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Backup File',
      fileName: 'autofi.backup.json',
    );
    if (filePath == null) {
      return;
    }
    final pin = await _promptForPin(title: 'Enter PIN to encrypt');
    if (pin == null || pin.isEmpty) {
      return;
    }
    await BackupService().exportBackup(filePath: filePath, pin: pin);
    if (mounted) {
      _showInfo('Backup saved.');
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Backup File',
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final filePath = result.files.single.path;
    if (filePath == null) {
      return;
    }
    final pin = await _promptForPin(title: 'Enter PIN to decrypt');
    if (pin == null || pin.isEmpty) {
      return;
    }
    try {
      final outcome = await BackupService().importBackup(
        filePath: filePath,
        pin: pin,
        strategy: ImportStrategy.merge,
      );
      if (mounted) {
        await _showInfo('Imported ${outcome.added} items, updated ${outcome.updated}.');
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (_) {
      if (mounted) {
        await _showInfo('Import failed. Check your PIN and file.');
      }
    }
  }

  Future<void> _showInfo(String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    final themeProvider = context.watch<ThemeProvider>();
    final currencyValue = _currencyOptions.any((c) => c['value'] == _selectedCurrency)
        ? _selectedCurrency
        : '₹';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_exchange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Currency',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DropdownButton<String>(
                  value: currencyValue,
                  dropdownColor: scheme.surface,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCurrency = value);
                      _saveCurrency(value);
                      Navigator.pop(context, value);
                    }
                  },
                  items: _currencyOptions
                      .map(
                        (currency) => DropdownMenuItem(
                          value: currency['value'],
                          child: Text(currency['label']!),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Tuning (Offline)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(onPressed: _openAiTuning, child: const Text('Open')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isDemoMode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Demo Mode', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_add_alt_1),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Continue by creating an account')),
                      TextButton(onPressed: _goToCreateAccount, child: const Text('Create')),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.logout, color: scheme.error),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Exit demo mode')),
                      TextButton(
                        onPressed: _exitDemoMode,
                        child: Text('Exit', style: TextStyle(color: scheme.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                DropdownButtonFormField<ThemeModeSetting>(
                  value: themeProvider.modeSetting,
                  decoration: const InputDecoration(labelText: 'Theme mode'),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeModeSetting.system,
                      child: Text('System default'),
                    ),
                    DropdownMenuItem(
                      value: ThemeModeSetting.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeModeSetting.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setModeSetting(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ThemePalette>(
                  value: themeProvider.palette,
                  decoration: const InputDecoration(labelText: 'Color palette'),
                  items: const [
                    DropdownMenuItem(
                      value: ThemePalette.navyTeal,
                      child: Text('Navy + Teal'),
                    ),
                    DropdownMenuItem(
                      value: ThemePalette.charcoalBlue,
                      child: Text('Charcoal + Blue'),
                    ),
                    DropdownMenuItem(
                      value: ThemePalette.slateEmerald,
                      child: Text('Slate + Emerald'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setPalette(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.lock_outline),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Change PIN')),
                    TextButton(onPressed: _changePin, child: const Text('Update')),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Change name')),
                    TextButton(onPressed: _changeName, child: const Text('Update')),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Average monthly income')),
                    TextButton(onPressed: _changeIncome, child: const Text('Update')),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.help_outline),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Recovery questions')),
                    TextButton(onPressed: _updateRecoveryQuestions, child: const Text('Update')),
                  ],
                ),
                const Divider(height: 24),
                SwitchListTile(
                  value: _biometricsEnabled,
                  onChanged: _toggleBiometrics,
                  title: const Text('Enable biometrics'),
                  subtitle: const Text('Use fingerprint or face unlock'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Backup & Import', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.upload_file),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Backup data to file')),
                    TextButton(onPressed: _backupData, child: const Text('Backup')),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Import from file')),
                    TextButton(onPressed: _importData, child: const Text('Import')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.delete_forever, color: scheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reset Data',
                    style: TextStyle(fontWeight: FontWeight.w600, color: scheme.error),
                  ),
                ),
                TextButton(
                  onPressed: _resetData,
                  child: Text('Clear', style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}



