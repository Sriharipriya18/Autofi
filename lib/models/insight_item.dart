class InsightItem {
  int? id;
  final String type;
  final String payloadJson;
  final DateTime createdAt;

  InsightItem({
    this.id,
    required this.type,
    required this.payloadJson,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'payload_json': payloadJson,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InsightItem.fromMap(Map<String, dynamic> map) {
    return InsightItem(
      id: map['id'],
      type: map['type'],
      payloadJson: map['payload_json'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}