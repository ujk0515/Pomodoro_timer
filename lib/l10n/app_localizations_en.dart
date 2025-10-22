// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pomodoro Timer';

  @override
  String get pomodoro => 'Pomodoro';

  @override
  String get stopwatch => 'Stopwatch';

  @override
  String get clock => 'Clock';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get reset => 'Reset';

  @override
  String get stop => 'Stop';

  @override
  String get custom => 'Custom';

  @override
  String get minutes => 'min';

  @override
  String get alwaysOnTop => 'Always on Top';
}
