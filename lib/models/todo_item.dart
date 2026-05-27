class TodoItem {
  String id;
  String text;
  bool isDone;
  String date;
  DateTime createdAt;

  TodoItem({
    required this.id,
    required this.text,
    this.isDone = false,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isDone': isDone,
      'date': date,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map, String documentId) {
    final createdAtValue = map['createdAt'];

    return TodoItem(
      id: (map['id'] as String?)?.isNotEmpty == true
          ? map['id'] as String
          : documentId,
      text: map['text'] ?? '',
      isDone: map['isDone'] as bool? ?? map['isCompleted'] as bool? ?? false,
      date: map['date'] as String? ?? map['periodKey'] as String? ?? '',
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem.fromMap(json, json['id'] as String? ?? '');
  }

  Map<String, dynamic> toJson() => toMap();

  TodoItem copyWith({
    String? id,
    String? text,
    bool? isDone,
    String? date,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
