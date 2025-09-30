class TodoItem {
  String id;
  String text;
  bool isDone;
  String date;

  TodoItem({
    required this.id,
    required this.text,
    this.isDone = false,
    required this.date,
  });

  // Firestore에 저장할 때 → Map 변환
  Map<String, dynamic> toMap() {
    return {'text': text, 'isDone': isDone, 'date': date};
  }

  // Firestore에서 읽어올 때 → TodoItem 변환
  factory TodoItem.fromMap(Map<String, dynamic> map, String documentId) {
    return TodoItem(
      id: documentId,
      text: map['text'] ?? '',
      isDone: map['isDone'] ?? false,
      date: map['date'] ?? '',
    );
  }

  TodoItem copyWith({String? id, String? text, bool? isDone, String? date}) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
      date: date ?? this.date,
    );
  }
}
