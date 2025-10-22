// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '뽀모도로 타이머';

  @override
  String get pomodoro => '뽀모도로';

  @override
  String get stopwatch => '스톱워치';

  @override
  String get clock => '시계';

  @override
  String get start => '시작';

  @override
  String get pause => '일시정지';

  @override
  String get reset => '초기화';

  @override
  String get stop => '정지';

  @override
  String get custom => '커스텀';

  @override
  String get minutes => '분';

  @override
  String get alwaysOnTop => '맨 앞에 고정';
}
