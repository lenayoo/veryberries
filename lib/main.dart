import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:very_berries/models/todo_item.dart';
import 'helpers/storage_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Very berries',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ko'), Locale('ja')],
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

  String formatToday(BuildContext context) {
    final now = DateTime.now();
    final month = DateFormat.MMMM(
      Localizations.localeOf(context).toString(),
    ).format(now);

    final date = DateFormat.d(
      Localizations.localeOf(context).toString(),
    ).format(now);

    return AppLocalizations.of(context)?.monthDate(month, date) ?? "";
  }

  /// 오늘 날짜를 로컬라이즈된 형식으로 리턴
  String get todayText {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();

    final month =
        locale.startsWith('en')
            ? DateFormat.MMMM(locale).format(now) // September
            : DateFormat.M(locale).format(now);
    final date = DateFormat.d(
      Localizations.localeOf(context).toString(),
    ).format(now);

    // arb에 정의된 monthDate 사용 → "{month}월 {date}일"
    return AppLocalizations.of(context)!.monthDate(month, date);
  }

  /// 이번 달 이름만 로컬라이즈된 형식으로 리턴
  String get monthText {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();

    final month =
        locale.startsWith('en')
            ? DateFormat.MMMM(locale).format(now) // September
            : DateFormat.M(locale).format(now);
    // arb에 정의된 month 사용 → "{month}월"
    return AppLocalizations.of(context)!.month(month);
  }

  void _addToMonthly() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _monthlyTodos.add(TodoItem(text: _controller.text.trim()));
      _controller.clear();
      FocusScope.of(context).unfocus();
    });
    StorageHelper.saveTodos(_monthlyTodos);
  }

  void _addToDaily() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _dailyTodos.add(TodoItem(text: _controller.text.trim()));
      _controller.clear();
      FocusScope.of(context).unfocus();
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
            if (todos.isEmpty) Text(AppLocalizations.of(context)!.noPlan),
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
      appBar: AppBar(title: const Text('One Berry at a Day🍓')),
      body: Stack(
        children: [
          // ✅ 배경 이미지 추가
          Positioned.fill(
            child: Image.asset('assets/images/sub-bg.png', fit: BoxFit.cover),
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
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.enterTodo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: _addToMonthly,
                            child: Text(AppLocalizations.of(context)!.addToday),
                          ),
                          ElevatedButton(
                            onPressed: _addToDaily,
                            child: Text(AppLocalizations.of(context)!.addMonth),
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
                            "$monthText - ${AppLocalizations.of(context)!.monthlyGoals}",
                            _monthlyTodos,
                            Colors.purple,
                          ),
                          _buildTodoBox(
                            "$todayText - ${AppLocalizations.of(context)!.dailyGoals}",
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
