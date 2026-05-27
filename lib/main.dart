import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'helpers/storage_helper.dart';
import 'models/todo_item.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository, this.locale});

  final GoalRepository? repository;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
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
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return const Locale('en');
        }

        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }

        return const Locale('en');
      },
      home: TodoListPage(
        repository: repository ?? const SecureStorageGoalRepository(),
      ),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key, required this.repository});

  final GoalRepository repository;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final List<TodoItem> _monthlyTodos = [];
  final List<TodoItem> _dailyTodos = [];

  late String _visibleTodayKey;
  late String _visibleMonthKey;
  Timer? _periodTimer;

  String get _todayKey => StorageHelper.todayKey();

  String get _monthKey => StorageHelper.currentMonthKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visibleTodayKey = _todayKey;
    _visibleMonthKey = _monthKey;
    _loadTodos();
    _periodTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshVisibleGoalsIfPeriodChanged(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshVisibleGoalsIfPeriodChanged(force: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final snapshot = await widget.repository.loadVisibleGoals();

    if (!mounted) {
      return;
    }

    setState(() {
      _visibleTodayKey = _todayKey;
      _visibleMonthKey = _monthKey;
      _monthlyTodos
        ..clear()
        ..addAll(snapshot.monthlyGoals);
      _dailyTodos
        ..clear()
        ..addAll(snapshot.dailyGoals);
    });
  }

  Future<void> _refreshVisibleGoalsIfPeriodChanged({bool force = false}) async {
    final todayKey = _todayKey;
    final monthKey = _monthKey;

    if (!force &&
        todayKey == _visibleTodayKey &&
        monthKey == _visibleMonthKey) {
      return;
    }

    await _loadTodos();
  }

  String get todayText {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();

    final month =
        locale.startsWith('en')
            ? DateFormat.MMMM(locale).format(now)
            : DateFormat.M(locale).format(now);
    final date = DateFormat.d(locale).format(now);

    return AppLocalizations.of(context)!.monthDate(month, date);
  }

  String get monthText {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();

    final month =
        locale.startsWith('en')
            ? DateFormat.MMMM(locale).format(now)
            : DateFormat.M(locale).format(now);
    return AppLocalizations.of(context)!.month(month);
  }

  Future<void> _addToMonthly() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }

    await _refreshVisibleGoalsIfPeriodChanged();
    final newTodo = await widget.repository.addGoal(
      bucket: GoalBucket.monthly,
      text: _controller.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _monthlyTodos.add(newTodo);
      _controller.clear();
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _addToDaily() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }

    await _refreshVisibleGoalsIfPeriodChanged();
    final newTodo = await widget.repository.addGoal(
      bucket: GoalBucket.daily,
      text: _controller.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyTodos.add(newTodo);
      _controller.clear();
      FocusScope.of(context).unfocus();
    });
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
        color: color.withValues(alpha: 0.05),
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
                key: Key(todo.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  final removedTodo = todo;

                  setState(() {
                    todos.removeAt(index);
                  });

                  await widget.repository.deleteGoal(
                    bucket:
                        isMonthly ? GoalBucket.monthly : GoalBucket.daily,
                    goal: removedTodo,
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

                    await widget.repository.updateGoal(
                      bucket:
                          isMonthly ? GoalBucket.monthly : GoalBucket.daily,
                      goal: todo,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                            Colors.purple,
                            isMonthly: true,
                          ),
                          _buildTodoBox(
                            "$todayText - ${AppLocalizations.of(context)!.dailyGoals}",
                            _dailyTodos,
                            const Color(0xFFF7E8C8),
                            isMonthly: false,
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
