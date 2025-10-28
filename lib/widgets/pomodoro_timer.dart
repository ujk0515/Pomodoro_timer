import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/sound_player.dart';
import 'running_animation.dart';

// 플랫폼별 window_flash
import '../utils/window_flash.dart'
    if (dart.library.html) '../utils/window_flash_web.dart';

class PomodoroTimer extends StatefulWidget {
  final Function(bool isRunning, bool isCompleted)? onStatusChanged;

  const PomodoroTimer({super.key, this.onStatusChanged});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

enum TimerMode { work, rest }

class _PomodoroTimerState extends State<PomodoroTimer> with SingleTickerProviderStateMixin {
  int _totalSeconds = 600; // 기본 10분
  int _remainingSeconds = 600;
  bool _isRunning = false;
  Timer? _timer;
  int _customMinutes = 10;
  late AnimationController _blinkController;

  final List<int> _presetMinutes = [10, 20, 30, 40, 50, 60];

  // 업무/쉬는시간 설정
  TimerMode _settingMode = TimerMode.work; // 현재 설정 중인 모드
  TimerMode _currentMode = TimerMode.work; // 현재 실행 중인 모드
  int _workMinutes = 10; // 업무 시간
  int _restMinutes = 10;  // 쉬는 시간

  // 반복 설정
  int _repeatCount = 1; // 반복 횟수 (최소 1)
  int _currentCycle = 1; // 현재 회차

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
          _onTimerComplete();
        }
      });
    });
  }

  void _onTimerComplete() {
    _stopTimer();
    _flashTaskbar();

    final isWorkMode = _currentMode == TimerMode.work;

    // 최종 완료 조건 체크
    // 업무 모드이고, 현재 회차가 설정한 반복 횟수에 도달했으면 종료
    if (isWorkMode && _currentCycle >= _repeatCount) {
      // 최종 완료 - 무한 알림
      _playCompletionSound();
      _blinkController.repeat(reverse: true);
      widget.onStatusChanged?.call(false, true);
      return; // 더 이상 진행하지 않음
    }

    // 중간 완료 - 알림음 1회만 (3초)
    _playCompletionSoundOnce();

    // 3초 후 다음 단계로 자동 전환 (알림음 재생 완료 후)
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _switchToNextPhase();
      }
    });
  }

  void _switchToNextPhase() {
    if (_currentMode == TimerMode.work) {
      // 업무 → 쉬는시간 (회차는 유지)
      setState(() {
        _currentMode = TimerMode.rest;
        _totalSeconds = _restMinutes * 60;
        _remainingSeconds = _restMinutes * 60;
      });
      _startTimer();
    } else {
      // 쉬는시간 → 업무 (회차 증가)
      setState(() {
        _currentCycle++;
        _currentMode = TimerMode.work;
        _totalSeconds = _workMinutes * 60;
        _remainingSeconds = _workMinutes * 60;
      });
      _startTimer();
    }
  }

  void _playCompletionSoundOnce() {
    // 1회만 재생 (3초)
    SoundPlayer.playCompletionSound();
    Future.delayed(const Duration(milliseconds: 3000), () {
      SoundPlayer.stopSound();
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
      _currentMode = TimerMode.work;
      _currentCycle = 1;
      _totalSeconds = _workMinutes * 60;
      _remainingSeconds = _workMinutes * 60;
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
    setState(() {
      if (_settingMode == TimerMode.work) {
        _workMinutes = minutes;
        // 타이머가 시작되지 않았으면 타이머 초기값도 업데이트
        if (!_isRunning && _remainingSeconds == _totalSeconds) {
          _totalSeconds = minutes * 60;
          _remainingSeconds = minutes * 60;
        }
      } else {
        _restMinutes = minutes;
      }
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
      // 업무 중이면 달리기, 쉬는 시간이면 수면
      return _currentMode == TimerMode.work
          ? AnimationState.running
          : AnimationState.sleeping;
    } else if (_remainingSeconds < _totalSeconds) {
      return AnimationState.resting; // 일시정지
    } else {
      return AnimationState.ready; // 시작 전
    }
  }

  Color _getTimerColor() {
    if (_currentMode == TimerMode.rest) {
      return Colors.green.shade600; // 쉬는 시간은 초록색
    }
    return Colors.deepPurple; // 업무 시간은 보라색
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 토글(왼쪽) + 타이머(중앙) + 반복 카운터(오른쪽) (가로 배치)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 업무/쉬는시간 토글 스위치 (왼쪽)
              Column(
                children: [
                  IgnorePointer(
                    ignoring: _isRunning || _remainingSeconds < _totalSeconds,
                    child: Opacity(
                      opacity: (_isRunning || _remainingSeconds < _totalSeconds) ? 0.4 : 1.0,
                      child: _buildToggleSwitch(),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 20),

              // 타이머 디스플레이 (중앙)
              Column(
                children: [
                  // 진행 상태 표시
                  if (_isRunning || _remainingSeconds < _totalSeconds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _currentMode == TimerMode.work
                            ? '업무 시간 ($_currentCycle/$_repeatCount회차)'
                            : '쉬는 시간 ($_currentCycle/$_repeatCount회차)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getTimerColor(),
                        ),
                      ),
                    ),
                  AnimatedBuilder(
                    animation: _blinkController,
                    builder: (context, child) {
                      final isCompleted = _remainingSeconds == 0;
                      final baseColor = _getTimerColor();
                      final blinkColor = isCompleted
                          ? Color.lerp(
                              baseColor,
                              const Color(0xFFD32F2F),
                              _blinkController.value,
                            )!
                          : baseColor;

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
                ],
              ),

              const SizedBox(width: 20),

              // 반복 카운터 (오른쪽)
              Opacity(
                opacity: (_isRunning || _remainingSeconds < _totalSeconds) ? 0.4 : 1.0,
                child: Column(
                  children: [
                    // + 버튼
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: (_isRunning || _remainingSeconds < _totalSeconds) ? null : () {
                          setState(() {
                            _repeatCount++;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        color: Colors.deepPurple,
                      ),
                    ),
                    // 카운트 표시
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$_repeatCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                    // - 버튼
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: (_isRunning || _remainingSeconds < _totalSeconds) ? null : () {
                          if (_repeatCount > 1) {
                            setState(() {
                              _repeatCount--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 24),
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          IgnorePointer(
            ignoring: _isRunning || _remainingSeconds < _totalSeconds,
            child: Opacity(
              opacity: (_isRunning || _remainingSeconds < _totalSeconds) ? 0.4 : 1.0,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _presetMinutes.map((minutes) {
                  final isSelected = (_settingMode == TimerMode.work
                      ? _workMinutes
                      : _restMinutes) == minutes;
                  return _buildPresetButton(minutes, isSelected);
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 커스텀 시간 설정
          Opacity(
            opacity: (_isRunning || _remainingSeconds < _totalSeconds) ? 0.4 : 1.0,
            child: Row(
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
                  onPressed: (_isRunning || _remainingSeconds < _totalSeconds) ? null : _decrementCustomTime,
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
                  onPressed: (_isRunning || _remainingSeconds < _totalSeconds) ? null : _incrementCustomTime,
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
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    final isWork = _settingMode == TimerMode.work;
    return GestureDetector(
      onTap: () {
        setState(() {
          _settingMode = _settingMode == TimerMode.work
              ? TimerMode.rest
              : TimerMode.work;
          // 토글 전환시 customMinutes도 업데이트
          _customMinutes = _settingMode == TimerMode.work
              ? _workMinutes
              : _restMinutes;
        });
      },
      child: Container(
        width: 60,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade400, width: 2),
        ),
        child: Stack(
          children: [
            // 활성화된 배경
            AnimatedAlign(
              alignment: isWork ? Alignment.topCenter : Alignment.bottomCenter,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 50,
                height: 46,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
            ),
            // 텍스트들
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 업무
                Center(
                  child: Text(
                    '업무',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isWork ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                // 쉬는시간
                Center(
                  child: Text(
                    '휴식',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: !isWork ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
