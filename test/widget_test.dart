import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:very_berries/helpers/storage_helper.dart';
import 'package:very_berries/main.dart';
import 'package:very_berries/models/todo_item.dart';

void main() {
  group('goal reset logic', () {
    test('shows only the current day goals for the requested date', () async {
      final may27 = DateTime(2026, 5, 27, 21);
      final may28 = DateTime(2026, 5, 28, 9);
      final may27Key = StorageHelper.todayKey(may27);
      final may28Key = StorageHelper.todayKey(may28);

      final repository = InMemoryGoalRepository(
        dailyGoalsByDate: {
          may27Key: [
            TodoItem(
              id: 'day-27',
              text: 'May 27 goal',
              isDone: false,
              date: may27Key,
              createdAt: may27,
            ),
          ],
          may28Key: [
            TodoItem(
              id: 'day-28',
              text: 'May 28 goal',
              isDone: false,
              date: may28Key,
              createdAt: may28,
            ),
          ],
        },
      );

      final may27Snapshot = await repository.loadVisibleGoals(now: may27);
      final may28Snapshot = await repository.loadVisibleGoals(now: may28);

      expect(may27Snapshot.dailyGoals.map((goal) => goal.text), ['May 27 goal']);
      expect(may28Snapshot.dailyGoals.map((goal) => goal.text), ['May 28 goal']);
    });

    test('shows only the current month goals for the requested month', () async {
      final may = DateTime(2026, 5, 31, 21);
      final june = DateTime(2026, 6, 1, 9);
      final mayKey = StorageHelper.currentMonthKey(may);
      final juneKey = StorageHelper.currentMonthKey(june);

      final repository = InMemoryGoalRepository(
        monthlyGoalsByMonth: {
          mayKey: [
            TodoItem(
              id: 'may-goal',
              text: 'May goal',
              isDone: false,
              date: mayKey,
              createdAt: may,
            ),
          ],
          juneKey: [
            TodoItem(
              id: 'june-goal',
              text: 'June goal',
              isDone: false,
              date: juneKey,
              createdAt: june,
            ),
          ],
        },
      );

      final maySnapshot = await repository.loadVisibleGoals(now: may);
      final juneSnapshot = await repository.loadVisibleGoals(now: june);

      expect(maySnapshot.monthlyGoals.map((goal) => goal.text), ['May goal']);
      expect(juneSnapshot.monthlyGoals.map((goal) => goal.text), ['June goal']);
    });
  });

  group('localization', () {
    testWidgets('defaults to English for unsupported locale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MyApp(
          repository: InMemoryGoalRepository(),
          locale: const Locale('fr'),
        ),
      );
      await tester.pump();

      expect(find.text('Please enter your to-do!'), findsOneWidget);
      expect(find.text('add today'), findsOneWidget);
      expect(find.text('add this month'), findsOneWidget);
    });

    testWidgets('shows Japanese strings for Japanese locale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MyApp(
          repository: InMemoryGoalRepository(),
          locale: const Locale('ja'),
        ),
      );
      await tester.pump();

      expect(find.text('やることを入力してください!'), findsOneWidget);
      expect(find.text('今日に追加'), findsOneWidget);
      expect(find.text('今月に追加'), findsOneWidget);
    });

    testWidgets('shows Korean strings for Korean locale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MyApp(
          repository: InMemoryGoalRepository(),
          locale: const Locale('ko'),
        ),
      );
      await tester.pump();

      expect(find.text('할 일을 입력해주세요!'), findsOneWidget);
      expect(find.text('오늘에 추가'), findsOneWidget);
      expect(find.text('이번 달에 추가'), findsOneWidget);
    });
  });

  testWidgets('main screen shows only current day and month goals', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final todayKey = StorageHelper.todayKey(now);
    final yesterdayKey = StorageHelper.todayKey(
      now.subtract(const Duration(days: 1)),
    );
    final thisMonthKey = StorageHelper.currentMonthKey(now);
    final lastMonthKey = StorageHelper.currentMonthKey(
      DateTime(now.year, now.month - 1, 1),
    );

    final repository = InMemoryGoalRepository(
      dailyGoalsByDate: {
        todayKey: [
          TodoItem(
            id: 'today-goal',
            text: 'Today goal',
            isDone: false,
            date: todayKey,
            createdAt: now,
          ),
        ],
        yesterdayKey: [
          TodoItem(
            id: 'yesterday-goal',
            text: 'Yesterday goal',
            isDone: false,
            date: yesterdayKey,
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      },
      monthlyGoalsByMonth: {
        thisMonthKey: [
          TodoItem(
            id: 'this-month-goal',
            text: 'This month goal',
            isDone: false,
            date: thisMonthKey,
            createdAt: now,
          ),
        ],
        lastMonthKey: [
          TodoItem(
            id: 'last-month-goal',
            text: 'Last month goal',
            isDone: false,
            date: lastMonthKey,
            createdAt: DateTime(now.year, now.month - 1, 1),
          ),
        ],
      },
    );

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pump();

    expect(find.text('Today goal'), findsOneWidget);
    expect(find.text('This month goal'), findsOneWidget);
    expect(find.text('Yesterday goal'), findsNothing);
    expect(find.text('Last month goal'), findsNothing);
  });
}
