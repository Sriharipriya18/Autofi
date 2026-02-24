import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../models/expense.dart';
import '../widgets/category_definitions.dart';
import '../widgets/category_grid.dart';
import '../widgets/hero_tags.dart';
import '../services/categorizer_service.dart';

enum TransactionType { expense, income, transfer }

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _selectedCategory = expenseCategories.first.label;
  DateTime _selectedDate = DateTime.now();
  String _fromAccount = transferAccounts.first;
  String _toAccount = transferAccounts[1];
  bool _learnCategory = true;
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _notesFade;
  bool get _isEditing => widget.existingExpense != null;

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExpense;
    if (existing != null) {
      _titleController.text = existing.title;
      _amountController.text = _formatAmount(existing.amount);
      _selectedCategory = existing.category;
      _selectedDate = existing.date;
      _merchantController.text = existing.merchant ?? '';
      _notesController.text = existing.notes ?? '';
      _paymentController.text = existing.paymentMethod ?? '';
      if (isTransferCategory(existing.category)) {
        _type = TransactionType.transfer;
      } else {
        _type = isIncomeCategory(existing.category)
            ? TransactionType.income
            : TransactionType.expense;
      }
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _notesFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  Future<void> _maybeSuggestCategory() async {
    if (_type != TransactionType.expense) {
      return;
    }
    final suggestion = await CategorizerService().suggestCategory(
      title: _titleController.text,
      merchant: _merchantController.text,
    );
    if (suggestion != null && mounted) {
      setState(() => _selectedCategory = suggestion);
    }
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      final enteredAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
      if (enteredAmount == null || enteredAmount == 0) {
        _showError('Please enter a valid amount.');
        return;
      }

      final isTransfer = _type == TransactionType.transfer;
      if (isTransfer && _fromAccount == _toAccount) {
        _showError('From and To accounts must be different.');
        return;
      }
      final title = _titleController.text.trim().isEmpty && isTransfer
          ? 'Transfer: $_fromAccount -> $_toAccount'
          : _titleController.text.trim();
      if (title.isEmpty) {
        _showError('Please enter a title.');
        return;
      }

      final expense = Expense(
        id: widget.existingExpense?.id,
        title: title,
        amount: enteredAmount.abs(),
        category: isTransfer ? transferCategory.label : _selectedCategory,
        date: _selectedDate,
        merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        paymentMethod:
            _paymentController.text.trim().isEmpty ? null : _paymentController.text.trim(),
        createdAt: DateTime.now(),
      );

      if (_isEditing) {
        await AppDatabase().updateExpense(expense);
      } else {
        await AppDatabase().addExpense(expense);
      }
      if (_learnCategory && _type == TransactionType.expense) {
        final keyword = _merchantController.text.trim().isNotEmpty
            ? _merchantController.text.trim()
            : _titleController.text.trim();
        if (keyword.isNotEmpty) {
          await CategorizerService().addOverride(keyword: keyword, category: _selectedCategory);
        }
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid Entry'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true) {
      final id = widget.existingExpense?.id;
      if (id != null) {
        await AppDatabase().deleteExpense(id);
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  void _handleKeyTap(String value) {}

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.6);
    final isTransfer = _type == TransactionType.transfer;
    final categories = _type == TransactionType.income ? incomeCategories : expenseCategories;
    if (!categories.any((c) => c.label == _selectedCategory) && !isTransfer) {
      _selectedCategory = categories.first.label;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteExpense,
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Hero(
        tag: kAddExpenseFabHeroTag,
        transitionOnUserGestures: true,
        createRectTween: (begin, end) => MaterialRectCenterArcTween(begin: begin, end: end),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: _submitExpense,
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          child: const Icon(Icons.check),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                  ButtonSegment(value: TransactionType.income, label: Text('Income')),
                  ButtonSegment(value: TransactionType.transfer, label: Text('Transfer')),
                ],
                selected: <TransactionType>{_type},
                onSelectionChanged: (value) {
                  setState(() => _type = value.first);
                  _maybeSuggestCategory();
                },
              ),
              const SizedBox(height: 20),
              if (!isTransfer) ...[
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slideUp,
                    child: CategoryGrid(
                      categories: categories,
                      selected: _selectedCategory,
                      onSelected: (item) => setState(() => _selectedCategory = item.label),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                _TransferSelector(
                  fromAccount: _fromAccount,
                  toAccount: _toAccount,
                  onFromChanged: (value) => setState(() => _fromAccount = value),
                  onToChanged: (value) => setState(() => _toAccount = value),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _type == TransactionType.income ? 'Income' : 'Expense',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.replaceAll(',', '') ?? '');
                  if (parsed == null || parsed == 0) {
                    return 'Please enter a valid amount.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _notesFade,
                child: TextFormField(
                  controller: _titleController,
                  maxLength: 50,
                  onChanged: (_) => _maybeSuggestCategory(),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                  validator: (value) {
                    if (_type == TransactionType.transfer) {
                      return null;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _merchantController,
                onChanged: (_) => _maybeSuggestCategory(),
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paymentController,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _learnCategory,
                onChanged: (value) => setState(() => _learnCategory = value),
                title: const Text('Learn from my choice'),
                subtitle: const Text('Use this to improve auto categorization.'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 18),
                          const SizedBox(width: 8),
                          Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() => _selectedDate = DateTime.now()),
                            child: const Text('Today'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _presentDatePicker,
                    icon: const Icon(Icons.edit_calendar),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final isWhole = amount == amount.roundToDouble();
    return isWhole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  }
}

class _TransferSelector extends StatelessWidget {
  final String fromAccount;
  final String toAccount;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;

  const _TransferSelector({
    required this.fromAccount,
    required this.toAccount,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transfer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AccountDropdown(
                label: 'From',
                value: fromAccount,
                onChanged: onFromChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AccountDropdown(
                label: 'To',
                value: toAccount,
                onChanged: onToChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _AccountDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: scheme.surface,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: transferAccounts
              .map((account) => DropdownMenuItem(
                    value: account,
                    child: Text(account),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
