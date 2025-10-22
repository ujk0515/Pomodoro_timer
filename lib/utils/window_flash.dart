import 'package:windows_taskbar/windows_taskbar.dart';

// Windows 작업표시줄 깜빡임 유틸리티
class WindowFlash {
  // 작업표시줄 깜빡임 시작 (타이머 완료 시)
  static Future<void> flashWindow() async {
    await WindowsTaskbar.setFlashTaskbarAppIcon(
      mode: TaskbarFlashMode.all | TaskbarFlashMode.timernofg,
      timeout: const Duration(milliseconds: 500),
    );
  }

  // 작업표시줄 깜빡임 중지
  static Future<void> stopFlash() async {
    await WindowsTaskbar.resetFlashTaskbarAppIcon();
  }
}
