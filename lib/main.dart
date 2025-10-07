import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:very_berries/helpers/firebase_service.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:very_berries/models/todo_item.dart';
import 'helpers/storage_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Firebase 연결된 앱 개수:🍋 ${Firebase.apps.length}");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Very berries',
      theme: ThemeData(
        fontFamily: 'main-font',
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
    final db = FirebaseFirestore.instance;
    db
        .collection("test")
        .add({"text": "앱 시작할 때 저장됨", "date": DateTime.now()})
        .then((docRef) {
          print("🔥 저장 성공: ${docRef.id}");
        })
        .catchError((e) {
          print("❌ 저장 실패: $e");
        });
    _loadTodos();
  }

  final FirebaseService _firebaseService = FirebaseService();

  void _loadTodos() async {
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final monthLoaded = await _firebaseService.getMonthlyTodos();
    final dailyLoaded = await _firebaseService.getDailyTodos(dateKey);

    final currentMonth = monthText;
    final currentDay = todayText;

    final validMonthly =
        monthLoaded.where((todo) => todo.date == currentMonth).toList();
    final validDaily =
        dailyLoaded.where((todo) => todo.date == currentDay).toList();

    setState(() {
      // _monthlyTodos.clear();
      // _monthlyTodos.addAll(monthLoaded);
      _monthlyTodos
        ..clear()
        ..addAll(validMonthly);

      // _dailyTodos.clear();
      // _dailyTodos.addAll(dailyLoaded);

      _dailyTodos
        ..clear()
        ..addAll(validDaily);
    });
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

  void _addToMonthly() async {
    if (_controller.text.trim().isEmpty) return;

    final newTodo = TodoItem(
      id: "",
      text: _controller.text.trim(),
      isDone: false,
      date: monthText,
    );

    final docRef = await _firebaseService.addMonthlyTodo(newTodo);

    setState(() {
      _monthlyTodos.add(newTodo.copyWith(id: docRef.id));
      _controller.clear();
      FocusScope.of(context).unfocus();
    });
    // StorageHelper.saveTodos(_monthlyTodos);
  }

  void _addToDaily() async {
    if (_controller.text.trim().isEmpty) return;

    final newTodo = TodoItem(
      id: "",
      text: _controller.text.trim(),
      isDone: false,
      date: todayText,
    );

    final docRef = await _firebaseService.addDailyTodo(newTodo, todayText);

    setState(() {
      _dailyTodos.add(newTodo.copyWith(id: docRef.id));
      _controller.clear();
      FocusScope.of(context).unfocus();
    });
    // StorageHelper.saveDailyTodos(_dailyTodos, _todayKey);
  }

  Widget _buildTodoBox(
    String title,
    List<TodoItem> todos,
    Color color, {
    required bool isMonthly,
  }) {
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
                key: Key(todo.id), // Firestore 문서 ID 사용
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  setState(() {
                    todos.removeAt(index);
                  });

                  // ✅ Firestore 삭제
                  await _firebaseService.deleteTodo(
                    'users/testUser/${isMonthly ? "monthly" : "daily"}/${todo.id}',
                  );
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
                  onChanged: (bool? value) async {
                    setState(() {
                      todo.isDone = value ?? false;
                    });

                    // ✅ Firestore 업데이트
                    if (isMonthly) {
                      await _firebaseService.updateMonthlyTodoIsDone(
                        todo.id,
                        todo.isDone,
                      );
                    } else {
                      await _firebaseService.updateDailyTodoIsDone(
                        todo.id,
                        todo.isDone,
                      );
                    }
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
      // appBar: AppBar(title: const Text('One Berry at a Day🍓')),
      body: Stack(
        children: [
          // ✅ 배경 이미지 추가
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg-autumn-1.png',
              fit: BoxFit.cover,
            ),
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
                            labelStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: _addToMonthly,
                            child: Text(AppLocalizations.of(context)!.addMonth),
                          ),
                          ElevatedButton(
                            onPressed: _addToDaily,
                            child: Text(AppLocalizations.of(context)!.addToday),
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
                            isMonthly: true,
                            Colors.purple,
                          ),
                          _buildTodoBox(
                            "$todayText - ${AppLocalizations.of(context)!.dailyGoals}",
                            _dailyTodos,
                            isMonthly: false,
                            Color(0xFFF7E8C8),
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
