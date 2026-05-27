// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get noPlan => 'There is no plan ahead';

  @override
  String get enterTodo => 'Please enter your to-do!';

  @override
  String get addToday => 'add today';

  @override
  String get addMonth => 'add this month';

  @override
  String get dailyGoals => 'Daily Goals🍓';

  @override
  String get monthlyGoals => 'Monthly Goals🫐';
}
