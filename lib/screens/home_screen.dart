import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/expense.dart';
import '../models/alert_item.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';
import 'budgets_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/hero_tags.dart';
import '../services/analytics_service.dart';
import '../services/backup_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Expense>> _expensesFuture;
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadCurrency();
  }

  void _loadExpenses() {
    setState(() {
      _expensesFuture = AppDatabase().getExpenses().then((expenses) async {
        await _syncAlerts(expenses);
        try {
          await BackupService().exportAutoBackupJson();
        } catch (_) {
          // Auto backup should never block app usage.
        }
        return expenses;
      });
    });
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    });
  }

  Future<void> _openAddScreen() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) => const AddExpenseScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    _loadExpenses();
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(currencySymbol: _currencySymbol),
      ),
    );
    if (result == true) {
      _loadExpenses();
    } else if (result is String) {
      setState(() => _currencySymbol = result);
    }
  }

  Future<void> _syncAlerts(List<Expense> expenses) async {
    final budgets = await AppDatabase().getBudgets();
    final risks = AnalyticsService().overspendRisks(
      expenses: expenses,
      budgets: budgets,
      month: DateTime.now(),
    );
    await AppDatabase().clearAlerts();
    for (final risk in risks) {
      await AppDatabase().addAlert(
        AlertItem(
          type: 'overspend',
          message:
              '${risk.category} forecast is above budget. Consider adjusting your limit.',
          category: risk.category,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Hero(
        tag: kAddExpenseFabHeroTag,
        transitionOnUserGestures: true,
        createRectTween: (begin, end) => MaterialRectCenterArcTween(begin: begin, end: end),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: _openAddScreen,
          elevation: 6,
          backgroundColor: scheme.secondary,
          shape: const CircleBorder(),
          child: Icon(Icons.add, color: scheme.onSecondary, size: 28),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Expense>>(
          future: _expensesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final expenses = snapshot.data ?? [];
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildScreen(expenses, key: ValueKey(_currentIndex)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScreen(List<Expense> expenses, {required Key key}) {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          key: key,
          expenses: expenses,
          currencySymbol: _currencySymbol,
        );
      case 1:
        return RecordsScreen(
          key: key,
          expenses: expenses,
          selectedDate: _selectedDate,
          onDateChanged: (value) => setState(() => _selectedDate = value),
          currencySymbol: _currencySymbol,
          onExpensesChanged: _loadExpenses,
        );
      case 2:
        return BudgetsScreen(
          key: key,
          expenses: expenses,
          currencySymbol: _currencySymbol,
        );
      case 3:
        return ProfileScreen(
          key: key,
          onSettingsTap: _openSettings,
          currencySymbol: _currencySymbol,
        );
      default:
        return RecordsScreen(
          key: key,
          expenses: expenses,
          selectedDate: _selectedDate,
          onDateChanged: (value) => setState(() => _selectedDate = value),
          currencySymbol: _currencySymbol,
          onExpensesChanged: _loadExpenses,
        );
    }
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    return BottomAppBar(
      color: scheme.surface,
      elevation: 6,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 70,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.receipt_long,
                  label: 'Records',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                const SizedBox(width: 56),
                _NavItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Budgets',
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  selected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? scheme.secondary : muted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? scheme.secondary : muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
