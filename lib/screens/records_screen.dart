import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../models/expense.dart';
import '../widgets/category_definitions.dart';
import '../widgets/empty_state.dart';
import '../widgets/summary_header.dart';
import '../widgets/transaction_card.dart';
import 'add_expense_screen.dart';

class RecordsScreen extends StatefulWidget {
  final List<Expense> expenses;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final String currencySymbol;
  final VoidCallback onExpensesChanged;

  const RecordsScreen({
    super.key,
    required this.expenses,
    required this.selectedDate,
    required this.onDateChanged,
    required this.currencySymbol,
    required this.onExpensesChanged,
  });

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedMonth;
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  final Set<int> _dismissedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('MMM yyyy').format(widget.selectedDate);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RecordsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _selectedMonth = DateFormat('MMM yyyy').format(widget.selectedDate);
    }
    if (oldWidget.expenses.length != widget.expenses.length) {
      final ids = widget.expenses.map((e) => e.id).whereType<int>().toSet();
      _dismissedIds.removeWhere((id) => ids.contains(id) == false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthOptions = _buildMonthOptions(widget.expenses);
    final activeMonth = monthOptions.contains(_selectedMonth) ? _selectedMonth : monthOptions.first;
    final visibleExpenses = _filterByMonth(widget.expenses, activeMonth);
    final totalExpense = _sumAmounts(visibleExpenses, income: false);
    final totalIncome = _sumAmounts(visibleExpenses, income: true);
    final balance = totalIncome - totalExpense;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: ListView(
            key: ValueKey(activeMonth + visibleExpenses.length.toString()),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              SummaryHeader(
                expenses: totalExpense,
                income: totalIncome,
                balance: balance,
                selectedMonth: activeMonth,
                monthOptions: monthOptions,
                onMonthChanged: (value) => setState(() => _selectedMonth = value),
                onCalendarPressed: () => _openCalendar(context),
                currencySymbol: widget.currencySymbol,
              ),
              const SizedBox(height: 20),
              if (visibleExpenses.isEmpty)
                const EmptyStateCard(
                  title: 'No records yet',
                  subtitle: 'Add your first transaction',
                  icon: Icons.receipt_long,
                )
              else
                ..._buildGroupedList(visibleExpenses),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildMonthOptions(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return [DateFormat('MMM yyyy').format(DateTime.now())];
    }
    final months = expenses
        .map((e) => DateFormat('MMM yyyy').format(e.date))
        .toSet()
        .toList();
    months.sort((a, b) {
      final aDate = DateFormat('MMM yyyy').parse(a);
      final bDate = DateFormat('MMM yyyy').parse(b);
      return bDate.compareTo(aDate);
    });
    return months;
  }

  List<Expense> _filterByMonth(List<Expense> expenses, String month) {
    final target = DateFormat('MMM yyyy').parse(month);
    return expenses
        .where(
          (e) => e.date.year == target.year && e.date.month == target.month,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double _sumAmounts(List<Expense> expenses, {required bool income}) {
    double total = 0;
    for (final expense in expenses) {
      if (isTransferCategory(expense.category)) {
        continue;
      }
      final isIncome = isIncomeCategory(expense.category);
      if (income == isIncome) {
        total += expense.amount;
      }
    }
    return total;
  }

  List<Widget> _buildGroupedList(List<Expense> expenses) {
    final Map<String, List<Expense>> grouped = {};
    for (final expense in expenses.where((e) => !_dismissedIds.contains(e.id))) {
      final key = DateFormat('EEEE, MMM d').format(expense.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(expense);
    }

    final keys = grouped.keys.toList();
    return keys.map((dateKey) {
      final items = grouped[dateKey]!;
      final scheme = Theme.of(context).colorScheme;
      final muted = scheme.onSurface.withOpacity(0.6);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              dateKey,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ),
          ...items.map(
            (expense) => _buildDismissibleCard(expense),
          ),
          const SizedBox(height: 6),
        ],
      );
    }).toList();
  }

  Widget _buildDismissibleCard(Expense expense) {
    final scheme = Theme.of(context).colorScheme;
    final id = expense.id;
    if (id == null) {
      return TransactionCard(
        expense: expense,
        currencySymbol: widget.currencySymbol,
      );
    }
    return Dismissible(
      key: ValueKey('expense-$id'),
      direction: DismissDirection.horizontal,
      background: _SwipeAction(
        color: const Color(0xFFF5C518),
        icon: Icons.edit,
        label: 'Edit',
        alignStart: true,
      ),
      secondaryBackground: _SwipeAction(
        color: scheme.error,
        icon: Icons.delete,
        label: 'Delete',
        alignStart: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _openEdit(expense);
          return false;
        }
        final shouldDelete = await _confirmDelete();
        return shouldDelete ?? false;
      },
      onDismissed: (direction) async {
        _dismissedIds.add(id);
        await AppDatabase().deleteExpense(id);
        widget.onExpensesChanged();
      },
      child: TransactionCard(
        expense: expense,
        currencySymbol: widget.currencySymbol,
      ),
    );
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This action cannot be undone.'),
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
  }

  Future<void> _openEdit(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(existingExpense: expense),
      ),
    );
    widget.onExpensesChanged();
  }

  Future<void> _openCalendar(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1, 12),
    );
    if (pickedDate != null) {
      widget.onDateChanged(pickedDate);
      setState(() {
        _selectedMonth = DateFormat('MMM yyyy').format(pickedDate);
      });
    }
  }
}

class _SwipeAction extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool alignStart;

  const _SwipeAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Align(
        alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
