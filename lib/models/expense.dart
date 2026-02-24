class Expense {
  int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String? merchant;
  final String? paymentMethod;
  final DateTime? createdAt;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.merchant,
    this.paymentMethod,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'merchant': merchant,
      'payment_method': paymentMethod,
      'created_at': (createdAt ?? date).toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      merchant: map['merchant'],
      paymentMethod: map['payment_method'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
