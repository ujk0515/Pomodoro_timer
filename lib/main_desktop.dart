import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initializeDesktop() async {
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(480, 640),
    minimumSize: Size(480, 640),
    maximumSize: Size(480, 640),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
