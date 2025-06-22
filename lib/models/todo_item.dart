class TodoItem {
  String text;
  bool isDone;

  TodoItem({required this.text, this.isDone = false});

  TodoItem.empty() : text = '', isDone = false;

  Map<String, dynamic> toJson() => {'text': text, 'isDone': isDone};

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      TodoItem(text: json['text'], isDone: json['isDone']);
}
