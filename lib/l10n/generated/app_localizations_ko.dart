// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

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
  String get noPlan => '일정이 없습니다.';

  @override
  String get enterTodo => '할 일을 입력해주세요!';

  @override
  String get addToday => '오늘에 추가';

  @override
  String get addMonth => '이번 달에 추가';

  @override
  String get dailyGoals => '오늘의 목표🍓';

  @override
  String get monthlyGoals => '이번 달의 목표🫐';
}
