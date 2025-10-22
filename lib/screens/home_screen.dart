import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/stopwatch_widget.dart';
import '../widgets/clock_widget.dart';
import '../widgets/custom_title_bar.dart';

enum AppMode { pomodoro, stopwatch, clock }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener, TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPomodoroRunning = false;
  bool _isPomodoroCompleted = false;
  late AnimationController _blinkController;
  late AnimationController _rotationController;
  late AnimationController _completedBlinkController;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // 깜빡임 애니메이션 컨트롤러 (실행 중)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // 회전 테두리 애니메이션 컨트롤러
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // 완료 시 깜빡임 애니메이션 컨트롤러
    _completedBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _blinkController.dispose();
    _rotationController.dispose();
    _completedBlinkController.dispose();
    super.dispose();
  }

  void _updatePomodoroStatus(bool isRunning, bool isCompleted) {
    setState(() {
      _isPomodoroRunning = isRunning;
      _isPomodoroCompleted = isCompleted;

      if (isCompleted) {
        _completedBlinkController.repeat(reverse: true);
      } else {
        _completedBlinkController.stop();
        _completedBlinkController.reset();
      }
    });
  }

  AppMode get _currentMode {
    switch (_currentIndex) {
      case 0:
        return AppMode.pomodoro;
      case 1:
        return AppMode.stopwatch;
      case 2:
        return AppMode.clock;
      default:
        return AppMode.pomodoro;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom Title Bar
          const CustomTitleBar(),

          // Mode Selection
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton(
                  icon: Icons.timer,
                  label: l10n.pomodoro,
                  mode: AppMode.pomodoro,
                ),
                const SizedBox(width: 20),
                _buildModeButton(
                  icon: Icons.av_timer,
                  label: l10n.stopwatch,
                  mode: AppMode.stopwatch,
                ),
                const SizedBox(width: 20),
                _buildModeButton(
                  icon: Icons.access_time,
                  label: l10n.clock,
                  mode: AppMode.clock,
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Main Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                PomodoroTimer(
                  onStatusChanged: _updatePomodoroStatus,
                ),
                const StopwatchWidget(),
                const ClockWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required AppMode mode,
  }) {
    final isSelected = _currentMode == mode;
    final isPomodoroAndRunning = mode == AppMode.pomodoro && _isPomodoroRunning;
    final isPomodoroAndCompleted = mode == AppMode.pomodoro && _isPomodoroCompleted;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = mode.index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isPomodoroAndCompleted
            ? AnimatedBuilder(
                animation: _completedBlinkController,
                builder: (context, child) {
                  final blinkColor = Color.lerp(
                    Colors.deepPurple,
                    const Color(0xFFD32F2F), // 진한 빨간색
                    _completedBlinkController.value,
                  )!;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: blinkColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 24,
                          color: blinkColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: blinkColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : isPomodoroAndRunning
                ? AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _RotatingBorderPainter(
                          progress: _rotationController.value,
                          color: Colors.deepPurple,
                          borderWidth: 2,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _blinkController,
                                builder: (context, child) {
                                  return Icon(
                                    icon,
                                    size: 24,
                                    color: Color.lerp(
                                      Colors.deepPurple.withValues(alpha: 0.3),
                                      Colors.deepPurple,
                                      _blinkController.value,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 24,
                          color: isSelected ? Colors.deepPurple : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.deepPurple : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _RotatingBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderWidth;

  _RotatingBorderPainter({
    required this.progress,
    required this.color,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final radius = 8.0;
    final width = size.width;
    final height = size.height;

    // 전체 테두리 길이 계산
    final topLength = width - 2 * radius;
    final rightLength = height - 2 * radius;
    final bottomLength = width - 2 * radius;
    final leftLength = height - 2 * radius;
    final cornerLength = (3.14159 * radius / 2); // 각 모서리 호의 길이

    final totalLength = topLength + cornerLength + rightLength + cornerLength +
                       bottomLength + cornerLength + leftLength + cornerLength;

    final currentLength = totalLength * progress;

    final path = Path();
    var accumulatedLength = 0.0;

    // 상단 중앙에서 시작
    path.moveTo(width / 2, 0);

    // 1. 상단 우측으로
    final topRightLength = topLength / 2;
    if (currentLength > accumulatedLength) {
      final drawLength = (currentLength - accumulatedLength).clamp(0.0, topRightLength);
      path.lineTo(width / 2 + drawLength, 0);
    }
    accumulatedLength += topRightLength;
    if (currentLength <= accumulatedLength) {
      canvas.drawPath(path, paint);
      return;
    }

    // 2. 우측 상단 모서리
    path.lineTo(width - radius, 0);
    if (currentLength > accumulatedLength) {
      final drawAngle = ((currentLength - accumulatedLength) / cornerLength * 90).clamp(0.0, 90.0);
      path.arcToPoint(
        Offset(width, radius),
        radius: Radius.circular(radius),
        clockwise: true,
        rotation: drawAngle,
      );
    }
    accumulatedLength += cornerLength;
    if (currentLength <= accumulatedLength) {
      canvas.drawPath(path, paint);
      return;
    }

    // 3. 우측 세로
    path.arcToPoint(Offset(width, radius), radius: Radius.circular(radius), clockwise: true);
    if (currentLength > accumulatedLength) {
      final drawLength = (currentLength - accumulatedLength).clamp(0.0, rightLength);
      path.lineTo(width, radius + drawLength);
    }
    accumulatedLength += rightLength;
    if (currentLength <= accumulatedLength) {
      canvas.drawPath(path, paint);
      return;
    }

    // 4. 우측 하단 모서리
    path.lineTo(width, height - radius);
    if (currentLength > accumulatedLength) {
      path.arcToPoint(
        Offset(width - radius, height),
        radius: Radius.circular(radius),
        clockwise: true,
      );
    }
    accumulatedLength += cornerLength;
    if (currentLength <= accumulatedLength) {
      canvas.drawPath(path, paint);
      return;
    }

    // 5. 하단 가로
    path.arcToPoint(Offset(width - radius, height), radius: Radius.circular(radius), clockwise: true);
    if (currentLength > accumulatedLength) {
      final drawLength = (currentLength - accumulatedLength).clamp(0.0, bottomLength);
      path.lineTo(width - radius - drawLength, height);
    }
    accumulatedLength += bottomLength;
    if (currentLength <= accumulatedLength) {
      canvas.drawPath(path, paint);
      return;
    }

    // 6. 좌측 하단 모서리
    path.lineTo(radius, height);
    if (currentLength > accumulatedLength) {
      path.arcToPoint(
        Offset(0, height - radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
    }
    accumulatedLength += cornerLength;
    if (currentLength <= accumulatedLength) {
      canvas.drawPath(path, paint);
      return;
    }

    // 7. 좌측 세로
    path.arcToPoint(Offset(0, height - radius), radius: Radius.circular(radius), clockwise: true);
    if (currentLength > accumulatedLength) {
      final drawLength = (currentLength - accumulatedLength).clamp(0.0, leftLength);
      path.lineTo(0, height - radius - drawLength);
    }
    accumulatedLength += leftLength;
    if (currentLength <= accumulatedLength) {
      canvas.drawPath(path, paint);
      return;
    }

    // 8. 좌측 상단 모서리
    path.lineTo(0, radius);
    if (currentLength > accumulatedLength) {
      path.arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
        clockwise: true,
      );
    }
    accumulatedLength += cornerLength;
    if (currentLength <= accumulatedLength) {
      canvas.drawPath(path, paint);
      return;
    }

    // 9. 상단 좌측에서 중앙까지
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius), clockwise: true);
    final topLeftLength = topLength / 2;
    if (currentLength > accumulatedLength) {
      final drawLength = (currentLength - accumulatedLength).clamp(0.0, topLeftLength);
      path.lineTo(radius + drawLength, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RotatingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
