import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../models/todo_item.dart';

enum GoalBucket { daily, monthly }

class GoalSnapshot {
  const GoalSnapshot({
    this.dailyGoals = const [],
    this.monthlyGoals = const [],
  });

  final List<TodoItem> dailyGoals;
  final List<TodoItem> monthlyGoals;
}

abstract class GoalRepository {
  Future<GoalSnapshot> loadVisibleGoals({DateTime? now});

  Future<TodoItem> addGoal({
    required GoalBucket bucket,
    required String text,
    DateTime? now,
  });

  Future<void> updateGoal({
    required GoalBucket bucket,
    required TodoItem goal,
  });

  Future<void> deleteGoal({
    required GoalBucket bucket,
    required TodoItem goal,
  });
}

class StorageHelper {
  StorageHelper._();

  static const String dailyGoalsStorageKey = 'dailyGoalsByDate';
  static const String monthlyGoalsStorageKey = 'monthlyGoalsByMonth';

  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static String todayKey([DateTime? now]) {
    final effectiveNow = now ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(effectiveNow);
  }

  static String currentMonthKey([DateTime? now]) {
    final effectiveNow = now ?? DateTime.now();
    return DateFormat('yyyy-MM').format(effectiveNow);
  }

  static Future<Map<String, List<TodoItem>>> loadDailyGoalsByDate() {
    return _loadGoalsByPeriod(dailyGoalsStorageKey);
  }

  static Future<Map<String, List<TodoItem>>> loadMonthlyGoalsByMonth() {
    return _loadGoalsByPeriod(monthlyGoalsStorageKey);
  }

  static Future<void> saveDailyGoalsByDate(
    Map<String, List<TodoItem>> dailyGoalsByDate,
  ) {
    return _saveGoalsByPeriod(dailyGoalsStorageKey, dailyGoalsByDate);
  }

  static Future<void> saveMonthlyGoalsByMonth(
    Map<String, List<TodoItem>> monthlyGoalsByMonth,
  ) {
    return _saveGoalsByPeriod(monthlyGoalsStorageKey, monthlyGoalsByMonth);
  }

  static GoalSnapshot resetVisibleGoalsByDateMonth({
    required DateTime now,
    required Map<String, List<TodoItem>> dailyGoalsByDate,
    required Map<String, List<TodoItem>> monthlyGoalsByMonth,
  }) {
    final visibleDailyGoals = List<TodoItem>.from(
      dailyGoalsByDate[todayKey(now)] ?? const [],
    )..sort(sortByCreatedAt);

    final visibleMonthlyGoals = List<TodoItem>.from(
      monthlyGoalsByMonth[currentMonthKey(now)] ?? const [],
    )..sort(sortByCreatedAt);

    return GoalSnapshot(
      dailyGoals: visibleDailyGoals,
      monthlyGoals: visibleMonthlyGoals,
    );
  }

  static int sortByCreatedAt(TodoItem a, TodoItem b) {
    return a.createdAt.compareTo(b.createdAt);
  }

  static Future<Map<String, List<TodoItem>>> _loadGoalsByPeriod(
    String storageKey,
  ) async {
    try {
      final rawValue = await _storage.read(key: storageKey);
      if (rawValue == null || rawValue.isEmpty) {
        return {};
      }

      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      return decoded.map((periodKey, value) {
        final items = value is List ? value : const [];
        final goals = items
            .whereType<Map>()
            .map(
              (item) => TodoItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort(sortByCreatedAt);
        return MapEntry(periodKey, goals);
      });
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveGoalsByPeriod(
    String storageKey,
    Map<String, List<TodoItem>> goalsByPeriod,
  ) async {
    final payload = goalsByPeriod.map((periodKey, goals) {
      final encodedGoals = goals.map((goal) => goal.toJson()).toList();
      return MapEntry(periodKey, encodedGoals);
    });

    await _storage.write(key: storageKey, value: jsonEncode(payload));
  }
}

class SecureStorageGoalRepository implements GoalRepository {
  const SecureStorageGoalRepository();

  @override
  Future<GoalSnapshot> loadVisibleGoals({DateTime? now}) async {
    final effectiveNow = now ?? DateTime.now();
    final dailyGoalsByDate = await StorageHelper.loadDailyGoalsByDate();
    final monthlyGoalsByMonth = await StorageHelper.loadMonthlyGoalsByMonth();

    return StorageHelper.resetVisibleGoalsByDateMonth(
      now: effectiveNow,
      dailyGoalsByDate: dailyGoalsByDate,
      monthlyGoalsByMonth: monthlyGoalsByMonth,
    );
  }

  @override
  Future<TodoItem> addGoal({
    required GoalBucket bucket,
    required String text,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final goalsByPeriod = await _loadGoals(bucket);
    final periodKey =
        bucket == GoalBucket.daily
            ? StorageHelper.todayKey(effectiveNow)
            : StorageHelper.currentMonthKey(effectiveNow);

    final newGoal = TodoItem(
      id: '${bucket.name}-${effectiveNow.microsecondsSinceEpoch}',
      text: text,
      isDone: false,
      date: periodKey,
      createdAt: effectiveNow,
    );

    final updatedGoals = List<TodoItem>.from(goalsByPeriod[periodKey] ?? const [])
      ..add(newGoal)
      ..sort(StorageHelper.sortByCreatedAt);

    if (bucket == GoalBucket.daily) {
      goalsByPeriod[periodKey] = updatedGoals;
      await StorageHelper.saveDailyGoalsByDate(goalsByPeriod);
    } else {
      goalsByPeriod[periodKey] = updatedGoals;
      await StorageHelper.saveMonthlyGoalsByMonth(goalsByPeriod);
    }

    return newGoal;
  }

  @override
  Future<void> updateGoal({
    required GoalBucket bucket,
    required TodoItem goal,
  }) async {
    final goalsByPeriod = await _loadGoals(bucket);
    final updatedGoals = List<TodoItem>.from(goalsByPeriod[goal.date] ?? const []);
    final index = updatedGoals.indexWhere((item) => item.id == goal.id);

    if (index == -1) {
      return;
    }

    updatedGoals[index] = goal;
    updatedGoals.sort(StorageHelper.sortByCreatedAt);

    if (updatedGoals.isEmpty) {
      goalsByPeriod.remove(goal.date);
    } else {
      goalsByPeriod[goal.date] = updatedGoals;
    }

    await _saveGoals(bucket, goalsByPeriod);
  }

  @override
  Future<void> deleteGoal({
    required GoalBucket bucket,
    required TodoItem goal,
  }) async {
    final goalsByPeriod = await _loadGoals(bucket);
    final updatedGoals = List<TodoItem>.from(goalsByPeriod[goal.date] ?? const [])
      ..removeWhere((item) => item.id == goal.id);

    if (updatedGoals.isEmpty) {
      goalsByPeriod.remove(goal.date);
    } else {
      goalsByPeriod[goal.date] = updatedGoals;
    }

    await _saveGoals(bucket, goalsByPeriod);
  }

  Future<Map<String, List<TodoItem>>> _loadGoals(GoalBucket bucket) {
    switch (bucket) {
      case GoalBucket.daily:
        return StorageHelper.loadDailyGoalsByDate();
      case GoalBucket.monthly:
        return StorageHelper.loadMonthlyGoalsByMonth();
    }
  }

  Future<void> _saveGoals(
    GoalBucket bucket,
    Map<String, List<TodoItem>> goalsByPeriod,
  ) {
    switch (bucket) {
      case GoalBucket.daily:
        return StorageHelper.saveDailyGoalsByDate(goalsByPeriod);
      case GoalBucket.monthly:
        return StorageHelper.saveMonthlyGoalsByMonth(goalsByPeriod);
    }
  }
}

class InMemoryGoalRepository implements GoalRepository {
  InMemoryGoalRepository({
    Map<String, List<TodoItem>>? dailyGoalsByDate,
    Map<String, List<TodoItem>>? monthlyGoalsByMonth,
  }) : _dailyGoalsByDate = _clone(dailyGoalsByDate),
       _monthlyGoalsByMonth = _clone(monthlyGoalsByMonth);

  final Map<String, List<TodoItem>> _dailyGoalsByDate;
  final Map<String, List<TodoItem>> _monthlyGoalsByMonth;

  @override
  Future<GoalSnapshot> loadVisibleGoals({DateTime? now}) async {
    final effectiveNow = now ?? DateTime.now();
    return StorageHelper.resetVisibleGoalsByDateMonth(
      now: effectiveNow,
      dailyGoalsByDate: _dailyGoalsByDate,
      monthlyGoalsByMonth: _monthlyGoalsByMonth,
    );
  }

  @override
  Future<TodoItem> addGoal({
    required GoalBucket bucket,
    required String text,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final periodKey =
        bucket == GoalBucket.daily
            ? StorageHelper.todayKey(effectiveNow)
            : StorageHelper.currentMonthKey(effectiveNow);
    final newGoal = TodoItem(
      id: '${bucket.name}-${effectiveNow.microsecondsSinceEpoch}',
      text: text,
      isDone: false,
      date: periodKey,
      createdAt: effectiveNow,
    );

    final goalsByPeriod =
        bucket == GoalBucket.daily ? _dailyGoalsByDate : _monthlyGoalsByMonth;
    final updatedGoals = List<TodoItem>.from(goalsByPeriod[periodKey] ?? const [])
      ..add(newGoal)
      ..sort(StorageHelper.sortByCreatedAt);
    goalsByPeriod[periodKey] = updatedGoals;

    return newGoal;
  }

  @override
  Future<void> updateGoal({
    required GoalBucket bucket,
    required TodoItem goal,
  }) async {
    final goalsByPeriod =
        bucket == GoalBucket.daily ? _dailyGoalsByDate : _monthlyGoalsByMonth;
    final updatedGoals = List<TodoItem>.from(goalsByPeriod[goal.date] ?? const []);
    final index = updatedGoals.indexWhere((item) => item.id == goal.id);

    if (index == -1) {
      return;
    }

    updatedGoals[index] = goal;
    updatedGoals.sort(StorageHelper.sortByCreatedAt);
    goalsByPeriod[goal.date] = updatedGoals;
  }

  @override
  Future<void> deleteGoal({
    required GoalBucket bucket,
    required TodoItem goal,
  }) async {
    final goalsByPeriod =
        bucket == GoalBucket.daily ? _dailyGoalsByDate : _monthlyGoalsByMonth;
    final updatedGoals = List<TodoItem>.from(goalsByPeriod[goal.date] ?? const [])
      ..removeWhere((item) => item.id == goal.id);

    if (updatedGoals.isEmpty) {
      goalsByPeriod.remove(goal.date);
    } else {
      goalsByPeriod[goal.date] = updatedGoals;
    }
  }

  static Map<String, List<TodoItem>> _clone(
    Map<String, List<TodoItem>>? source,
  ) {
    if (source == null) {
      return {};
    }

    return source.map((key, value) => MapEntry(key, List<TodoItem>.from(value)));
  }
}
