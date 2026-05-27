// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Very berries';

  @override
  String month(String month) {
    return '$month';
  }

  @override
  String monthDate(String month, String date) {
    return '$month $date';
  }

  @override
  String get noPlan => '予定がないです。';

  @override
  String get enterTodo => 'やることを入力してください!';

  @override
  String get addToday => '今日に追加';

  @override
  String get addMonth => '今月に追加';

  @override
  String get dailyGoals => '今日の目標🍓';

  @override
  String get monthlyGoals => '今月の目標🫐';
}
