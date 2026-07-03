import 'dart:convert';

enum QRType { generated, scanned }

class QRHistoryItem {
  final String id;
  final String content;
  final QRType type;
  final DateTime createdAt;
  final String? label;

  QRHistoryItem({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
    this.label,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'label': label,
    };
  }

  factory QRHistoryItem.fromMap(Map<String, dynamic> map) {
    return QRHistoryItem(
      id: map['id'],
      content: map['content'],
      type: QRType.values.firstWhere((e) => e.name == map['type']),
      createdAt: DateTime.parse(map['createdAt']),
      label: map['label'],
    );
  }

  String toJson() => json.encode(toMap());
  factory QRHistoryItem.fromJson(String source) =>
      QRHistoryItem.fromMap(json.decode(source));
}
