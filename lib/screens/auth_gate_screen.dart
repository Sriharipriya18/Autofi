import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'pin_setup_screen.dart';
import 'pin_unlock_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthGateState>(
      future: _loadState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final state = snapshot.data ?? _AuthGateState(hasPin: false, demoMode: false);
        if (state.hasPin) {
          return const PinUnlockScreen();
        }
        if (state.demoMode) {
          return const HomeScreen();
        }
        return const PinSetupScreen();
      },
    );
  }

  Future<_AuthGateState> _loadState() async {
    final auth = AuthService();
    final hasPin = await auth.hasPin();
    final demoMode = await auth.isDemoMode();
    return _AuthGateState(hasPin: hasPin, demoMode: demoMode);
  }
}

class _AuthGateState {
  final bool hasPin;
  final bool demoMode;

  _AuthGateState({required this.hasPin, required this.demoMode});
}
