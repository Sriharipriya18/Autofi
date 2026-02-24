class AlertItem {
  int? id;
  final String type;
  final String message;
  final String? category;
  final DateTime createdAt;
  final bool isRead;

  AlertItem({
    this.id,
    required this.type,
    required this.message,
    this.category,
    required this.createdAt,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory AlertItem.fromMap(Map<String, dynamic> map) {
    return AlertItem(
      id: map['id'],
      type: map['type'],
      message: map['message'],
      category: map['category'],
      createdAt: DateTime.parse(map['created_at']),
      isRead: (map['is_read'] ?? 0) == 1,
    );
  }
}