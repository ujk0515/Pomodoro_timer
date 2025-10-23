import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/window_flash.dart';
import '../utils/sound_player.dart';
import 'running_animation.dart';

class PomodoroTimer extends StatefulWidget {
  final Function(bool isRunning, bool isCompleted)? onStatusChanged;

  const PomodoroTimer({super.key, this.onStatusChanged});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> with SingleTickerProviderStateMixin {
  int _totalSeconds = 600; // 기본 10분
  int _remainingSeconds = 600;
  bool _isRunning = false;
  Timer? _timer;
  int _customMinutes = 10;
  late AnimationController _blinkController;

  final List<int> _presetMinutes = [10, 20, 30, 40, 50, 60];

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });
    widget.onStatusChanged?.call(true, false);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _flashTaskbar();
          _playCompletionSound();
          _blinkController.repeat(reverse: true); // 깜빡임 시작
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    widget.onStatusChanged?.call(false, _remainingSeconds == 0);
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    widget.onStatusChanged?.call(false, _remainingSeconds == 0);
  }

  void _resetTimer() {
    _timer?.cancel();
    _blinkController.stop();
    _blinkController.reset();
    SoundPlayer.stopSound(); // 사운드 중지
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
    widget.onStatusChanged?.call(false, false);
  }

  void _flashTaskbar() {
    // 작업표시줄 깜빡임
    WindowFlash.flashWindow();
  }

  void _playCompletionSound() {
    // 완료 알림음 재생
    SoundPlayer.playCompletionSound();
  }

  void _setPresetTime(int minutes) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remainingSeconds = minutes * 60;
      _isRunning = false;
      _customMinutes = minutes;
    });
  }

  void _incrementCustomTime() {
    if (_customMinutes < 99) {
      _setPresetTime(_customMinutes + 1);
    }
  }

  void _decrementCustomTime() {
    if (_customMinutes > 1) {
      _setPresetTime(_customMinutes - 1);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  AnimationState _getAnimationState() {
    if (_remainingSeconds == 0) {
      return AnimationState.completed; // 완료
    } else if (_isRunning) {
      return AnimationState.running; // 달리기
    } else if (_remainingSeconds < _totalSeconds) {
      return AnimationState.resting; // 일시정지 (시작했다가 멈춤)
    } else {
      return AnimationState.ready; // 시작 전
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 타이머 디스플레이
          AnimatedBuilder(
            animation: _blinkController,
            builder: (context, child) {
              final isCompleted = _remainingSeconds == 0;
              final blinkColor = isCompleted
                  ? Color.lerp(
                      Colors.deepPurple,
                      const Color(0xFFD32F2F), // 진한 빨간색
                      _blinkController.value,
                    )!
                  : Colors.deepPurple;

              return Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: blinkColor,
                    width: 6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blinkColor.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: blinkColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // 애니메이션
          RunningAnimation(state: _getAnimationState()),

          const SizedBox(height: 12),

          // 컨트롤 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                label: _isRunning ? l10n.pause : l10n.start,
                onPressed: _isRunning ? _pauseTimer : _startTimer,
              ),
              const SizedBox(width: 16),
              _buildControlButton(
                icon: Icons.refresh,
                label: l10n.reset,
                onPressed: _resetTimer,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 프리셋 시간 선택
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _presetMinutes.map((minutes) {
              final isSelected = _totalSeconds == minutes * 60;
              return _buildPresetButton(minutes, isSelected);
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 커스텀 시간 설정
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.custom,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _decrementCustomTime,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.deepPurple,
                iconSize: 28,
              ),
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_customMinutes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _incrementCustomTime,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.deepPurple,
                iconSize: 28,
              ),
              Text(
                l10n.minutes,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildPresetButton(int minutes, bool isSelected) {
    return InkWell(
      onTap: () => _setPresetTime(minutes),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$minutes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
