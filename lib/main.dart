import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'todolist',
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
  final List<String> _monthlyTodos = [];
  final List<String> _dailyTodos = [];

  final String today = DateFormat('M월 d일').format(DateTime.now());
  final String month = DateFormat('M월').format(DateTime.now());

  void _addToMonthly() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _monthlyTodos.add(_controller.text.trim());
      _controller.clear();
    });
  }

  void _addToDaily() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _dailyTodos.add(_controller.text.trim());
      _controller.clear();
    });
  }

  Widget _buildTodoBox(String title, List<String> todos, Color color) {
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
            ...todos.map(
              (todo) => ListTile(
                title: Text(todo),
                leading: const Icon(Icons.check_box_outline_blank),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.tealAccent[300],
      appBar: AppBar(
        title: const Text('LENA\'s to do list 🌳'),
        backgroundColor: Colors.teal[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 입력창과 버튼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: '할 일을 입력하세요'),
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
                    _buildTodoBox("$month 목표🌸", _monthlyTodos, Colors.purple),
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
    );
  }
}
