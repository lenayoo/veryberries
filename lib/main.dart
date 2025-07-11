import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:very_berries/models/todo_item.dart';
import 'models/todo_item.dart';
import 'helpers/storage_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Very berries',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TextEditingController _controller = TextEditingController();
  final List<TodoItem> _monthlyTodos = [];
  final List<TodoItem> _dailyTodos = [];

  String get _todayKey {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    return 'dailyTodos_${formatter.format(now)}';
  }

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() async {
    final monthLoaded = await StorageHelper.loadTodos();
    final dailyLoaded = await StorageHelper.loadDailyTodos(_todayKey);

    setState(() {
      _monthlyTodos.addAll(monthLoaded);
      _dailyTodos.addAll(dailyLoaded);
    });
  }

  void _saveDailyTodos() {
    StorageHelper.saveDailyTodos(_dailyTodos, _todayKey);
  }

  final String today = DateFormat('M월 d일').format(DateTime.now());
  final String month = DateFormat('M월').format(DateTime.now());

  void _addToMonthly() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _monthlyTodos.add(TodoItem(text: _controller.text.trim()));
      _controller.clear();
    });
    StorageHelper.saveTodos(_monthlyTodos);
  }

  void _addToDaily() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _dailyTodos.add(TodoItem(text: _controller.text.trim()));
      _controller.clear();
    });
    _saveDailyTodos();
  }

  Widget _buildTodoBox(String title, List<TodoItem> todos, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: color.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (todos.isEmpty) const Text("할 일이 없습니다."),
            ...todos.asMap().entries.map((entry) {
              final index = entry.key;
              final todo = entry.value;
              return Dismissible(
                key: Key(todo.text + index.toString()), // 고유 키 필수
                direction: DismissDirection.endToStart, // 왼쪽 → 오른쪽 슬라이드
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  setState(() {
                    todos.removeAt(index);
                  });
                  StorageHelper.saveTodos(todos); // 저장소 반영
                },
                child: CheckboxListTile(
                  title: Text(
                    todo.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration:
                          todo.isDone ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey,
                      decorationThickness: 2.0,
                      color: todo.isDone ? Colors.grey : Colors.black,
                    ),
                  ),
                  value: todo.isDone,
                  onChanged: (bool? value) {
                    setState(() {
                      todo.isDone = value ?? false;
                    });
                    StorageHelper.saveTodos(todos); // 체크 상태 저장
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Very Berries🫐🍓')),
      body: Stack(
        children: [
          // ✅ 배경 이미지 추가
          Positioned.fill(
            child: Image.asset('assets/images/main-bg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 입력창과 버튼
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            labelText: '할 일을 입력하세요',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: _addToMonthly,
                            child: const Text("이번 달에 추가"),
                          ),
                          ElevatedButton(
                            onPressed: _addToDaily,
                            child: const Text("오늘에 추가"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTodoBox(
                            "$month 목표🌸",
                            _monthlyTodos,
                            Colors.purple,
                          ),
                          _buildTodoBox(
                            "$today - to do list🌟",
                            _dailyTodos,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
