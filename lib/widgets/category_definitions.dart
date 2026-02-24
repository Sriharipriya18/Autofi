import 'package:flutter/material.dart';

class CategoryItem {
  final String label;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}

final List<CategoryItem> expenseCategories = [
  const CategoryItem(label: 'Shopping', icon: Icons.shopping_bag, color: Color(0xFF14B8A6)),
  CategoryItem(label: 'Food', icon: Icons.restaurant, color: Color(0xFFF97316)),
  CategoryItem(label: 'Travel', icon: Icons.flight_takeoff, color: Color(0xFF38BDF8)),
  CategoryItem(label: 'Health', icon: Icons.favorite, color: Color(0xFFFB7185)),
  CategoryItem(label: 'Education', icon: Icons.school, color: Color(0xFF60A5FA)),
  CategoryItem(label: 'Transport', icon: Icons.directions_car, color: Color(0xFF34D399)),
  CategoryItem(label: 'Home', icon: Icons.home, color: Color(0xFF818CF8)),
  CategoryItem(label: 'Bills', icon: Icons.receipt_long, color: Color(0xFFF59E0B)),
  CategoryItem(label: 'Other', icon: Icons.category, color: Color(0xFF9CA3AF)),
];

const CategoryItem transferCategory =
    CategoryItem(label: 'Transfer', icon: Icons.swap_horiz, color: Color(0xFF38BDF8));

final List<CategoryItem> incomeCategories = [
  const CategoryItem(label: 'Salary', icon: Icons.payments, color: Color(0xFF22D3EE)),
  CategoryItem(label: 'Bonus', icon: Icons.card_giftcard, color: Color(0xFF22D3EE)),
  CategoryItem(label: 'Interest', icon: Icons.savings, color: Color(0xFFA3E635)),
  CategoryItem(label: 'Refund', icon: Icons.replay, color: Color(0xFF38BDF8)),
  CategoryItem(label: 'Investment', icon: Icons.trending_up, color: Color(0xFF34D399)),
];

const List<String> transferAccounts = [
  'Cash',
  'Card',
  'Bank',
  'Savings',
];

bool isIncomeCategory(String category) {
  for (final item in incomeCategories) {
    if (item.label == category) {
      return true;
    }
  }
  return false;
}

bool isTransferCategory(String category) {
  return category == transferCategory.label;
}

CategoryItem? categoryByLabel(String label) {
  for (final item in expenseCategories) {
    if (item.label == label) {
      return item;
    }
  }
  if (label == transferCategory.label) {
    return transferCategory;
  }
  for (final item in incomeCategories) {
    if (item.label == label) {
      return item;
    }
  }
  return null;
}
