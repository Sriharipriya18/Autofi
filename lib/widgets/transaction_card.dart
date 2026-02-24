import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'category_definitions.dart';
import '../models/expense.dart';
import 'currency.dart';

class TransactionCard extends StatelessWidget {
  final Expense expense;
  final String currencySymbol;

  const TransactionCard({
    super.key,
    required this.expense,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final category = categoryByLabel(expense.category);
    final isIncome = isIncomeCategory(expense.category);
    final scheme = Theme.of(context).colorScheme;
    final amountColor = isIncome ? scheme.tertiary : scheme.error;
    final currency = CurrencyFormatter.format(expense.amount, currencySymbol);
    final iconColor = category?.color ?? scheme.secondary;
    final muted = scheme.onSurface.withOpacity(0.6);
    final subtitle = expense.merchant?.isNotEmpty == true ? expense.merchant : expense.notes;
    final dateText = DateFormat('MMM d, yyyy').format(expense.date);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.18),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Icon(
              category?.icon ?? Icons.category,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (subtitle != null && subtitle!.trim().isNotEmpty)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  dateText,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isIncome ? '+$currency' : '-$currency',
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

}
