import 'package:flutter/material.dart';

enum AnimationState {
  ready,      // 시작 전 준비 자세
  running,    // 달리기 (업무 중)
  resting,    // 일시정지 휴식
  completed,  // 완료 (골)
  sleeping,   // 쉬는 시간 (수면)
}

class RunningAnimation extends StatefulWidget {
  final AnimationState state;

  const RunningAnimation({super.key, required this.state});

  @override
  State<RunningAnimation> createState() => _RunningAnimationState();
}

class _RunningAnimationState extends State<RunningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _getDuration(),
      vsync: this,
    );

    if (widget.state == AnimationState.running ||
        widget.state == AnimationState.completed ||
        widget.state == AnimationState.sleeping) {
      _controller.repeat();
    } else if (widget.state == AnimationState.resting) {
      _controller.repeat(reverse: true);
    }
  }

  Duration _getDuration() {
    switch (widget.state) {
      case AnimationState.running:
        return const Duration(milliseconds: 600); // 달리기 전체 사이클
      case AnimationState.completed:
        return const Duration(milliseconds: 600); // 완료 시에도 달리기 속도
      case AnimationState.sleeping:
        return const Duration(milliseconds: 2000); // 수면 zzZ 애니메이션
      case AnimationState.resting:
        return const Duration(milliseconds: 800); // 숨쉬기
      default:
        return const Duration(milliseconds: 800);
    }
  }

  @override
  void didUpdateWidget(RunningAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _controller.stop();
      _controller.duration = _getDuration();

      if (widget.state == AnimationState.running ||
          widget.state == AnimationState.completed ||
          widget.state == AnimationState.sleeping) {
        _controller.repeat();
      } else if (widget.state == AnimationState.resting) {
        _controller.repeat(reverse: true);
      } else {
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return _getWidget();
          },
        ),
      ),
    );
  }

  Widget _getWidget() {
    switch (widget.state) {
      case AnimationState.ready:
        return CustomPaint(
          size: const Size(50, 50),
          painter: ReadyPersonPainter(),
        );
      case AnimationState.running:
        // 4개 이미지 프레임 순차 애니메이션
        final frame = (_controller.value * 4).floor() % 4;
        return Image.asset(
          'assets/run_${frame + 1}.png',
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        );
      case AnimationState.resting:
        return CustomPaint(
          size: const Size(50, 50),
          painter: RestingPersonPainter(_controller.value),
        );
      case AnimationState.completed:
        // 완료 시 골 세레모니 애니메이션 (goal_1~4 반복)
        final frame = (_controller.value * 4).floor() % 4;
        return Image.asset(
          'assets/goal_${frame + 1}.png',
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        );
      case AnimationState.sleeping:
        // 쉬는 시간 수면 애니메이션
        return CustomPaint(
          size: const Size(60, 60),
          painter: SleepingPersonPainter(_controller.value),
        );
    }
  }
}

// 수면 애니메이션 (누워서 자는 사람 + zzZ)
class SleepingPersonPainter extends CustomPainter {
  final double animationValue;

  SleepingPersonPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade600
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 누워있는 사람
    // 머리 (왼쪽)
    canvas.drawCircle(
      Offset(centerX - 12, centerY + 2),
      5,
      paint,
    );

    // 몸통 (가로로 누움)
    canvas.drawLine(
      Offset(centerX - 7, centerY + 2),
      Offset(centerX + 15, centerY + 2),
      paint,
    );

    // 팔 (위쪽, 아래쪽)
    canvas.drawLine(
      Offset(centerX - 2, centerY + 2),
      Offset(centerX - 2, centerY - 3),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 8, centerY + 2),
      Offset(centerX + 8, centerY + 7),
      paint,
    );

    // 다리 (오른쪽으로 뻗음)
    canvas.drawLine(
      Offset(centerX + 15, centerY + 2),
      Offset(centerX + 20, centerY + 4),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 15, centerY + 2),
      Offset(centerX + 20, centerY),
      paint,
    );

    // zzZ 애니메이션 (위로 올라감)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 3개의 Z를 다른 위치에 그림
    final zPositions = [
      Offset(centerX + 10, centerY - 15 - animationValue * 8),
      Offset(centerX + 15, centerY - 10 - animationValue * 6),
      Offset(centerX + 20, centerY - 5 - animationValue * 4),
    ];

    for (int i = 0; i < 3; i++) {
      textPainter.text = TextSpan(
        text: 'z',
        style: TextStyle(
          color: Colors.green.shade600,
          fontSize: 12 + i * 2,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, zPositions[i]);
    }
  }

  @override
  bool shouldRepaint(SleepingPersonPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// 시작 전 준비 자세 (출발 대기)
class ReadyPersonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 머리
    canvas.drawCircle(
      Offset(centerX + 4, centerY - 8),
      6,
      paint,
    );

    // 몸통 (앞으로 많이 숙임)
    canvas.drawLine(
      Offset(centerX + 4, centerY - 2),
      Offset(centerX + 6, centerY + 12),
      paint,
    );

    // 왼팔 (앞으로 뻗어 땅에 손)
    canvas.drawLine(
      Offset(centerX + 4, centerY + 2),
      Offset(centerX - 6, centerY + 8),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - 6, centerY + 8),
      Offset(centerX - 10, centerY + 18),
      paint,
    );

    // 오른팔 (앞으로 뻗어 땅에 손)
    canvas.drawLine(
      Offset(centerX + 4, centerY + 2),
      Offset(centerX + 14, centerY + 8),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 14, centerY + 8),
      Offset(centerX + 18, centerY + 18),
      paint,
    );

    // 왼다리 (무릎 꿇은 자세)
    canvas.drawLine(
      Offset(centerX + 6, centerY + 12),
      Offset(centerX - 4, centerY + 18),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - 4, centerY + 18),
      Offset(centerX - 8, centerY + 26),
      paint,
    );

    // 오른다리 (뒤로 뻗음)
    canvas.drawLine(
      Offset(centerX + 6, centerY + 12),
      Offset(centerX + 12, centerY + 20),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 12, centerY + 20),
      Offset(centerX + 16, centerY + 24),
      paint,
    );
  }

  @override
  bool shouldRepaint(ReadyPersonPainter oldDelegate) => false;
}

// 휴식 중인 사람 그리기 (무릎에 손 올리고 숨 헐떡이기)
class RestingPersonPainter extends CustomPainter {
  final double animationValue;

  RestingPersonPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 숨쉬기 효과 (상체 위아래로 움직임)
    final breathOffset = animationValue * 3;

    // 머리 (숨쉴 때 함께 움직임)
    canvas.drawCircle(
      Offset(centerX, centerY - 10 + breathOffset),
      6,
      paint,
    );

    // 몸통 (앞으로 많이 숙임)
    final bodyTopX = centerX;
    final bodyTopY = centerY - 4 + breathOffset;
    final bodyBottomX = centerX + 5;
    final bodyBottomY = centerY + 14 + breathOffset * 0.5;

    canvas.drawLine(
      Offset(bodyTopX, bodyTopY),
      Offset(bodyBottomX, bodyBottomY),
      paint,
    );

    // 왼팔 (어깨 -> 팔꿈치 -> 손 -> 무릎)
    final leftShoulderX = centerX;
    final leftShoulderY = centerY - 2 + breathOffset;
    final leftElbowX = centerX - 8;
    final leftElbowY = centerY + 8 + breathOffset * 0.7;
    final leftHandX = centerX - 6;
    final leftHandY = centerY + 18; // 무릎 위치

    canvas.drawLine(Offset(leftShoulderX, leftShoulderY), Offset(leftElbowX, leftElbowY), paint);
    canvas.drawLine(Offset(leftElbowX, leftElbowY), Offset(leftHandX, leftHandY), paint);

    // 오른팔 (어깨 -> 팔꿈치 -> 손 -> 무릎)
    final rightShoulderX = centerX;
    final rightShoulderY = centerY - 2 + breathOffset;
    final rightElbowX = centerX + 10;
    final rightElbowY = centerY + 8 + breathOffset * 0.7;
    final rightHandX = centerX + 12;
    final rightHandY = centerY + 18; // 무릎 위치

    canvas.drawLine(Offset(rightShoulderX, rightShoulderY), Offset(rightElbowX, rightElbowY), paint);
    canvas.drawLine(Offset(rightElbowX, rightElbowY), Offset(rightHandX, rightHandY), paint);

    // 왼다리 (엉덩이 -> 무릎 -> 발) - 구부린 자세
    final leftHipX = centerX + 5;
    final leftHipY = centerY + 14 + breathOffset * 0.5;
    final leftKneeX = centerX - 6;
    final leftKneeY = centerY + 18;
    final leftFootX = centerX - 8;
    final leftFootY = centerY + 26;

    canvas.drawLine(Offset(leftHipX, leftHipY), Offset(leftKneeX, leftKneeY), paint);
    canvas.drawLine(Offset(leftKneeX, leftKneeY), Offset(leftFootX, leftFootY), paint);

    // 오른다리 (엉덩이 -> 무릎 -> 발) - 구부린 자세
    final rightHipX = centerX + 5;
    final rightHipY = centerY + 14 + breathOffset * 0.5;
    final rightKneeX = centerX + 12;
    final rightKneeY = centerY + 18;
    final rightFootX = centerX + 14;
    final rightFootY = centerY + 26;

    canvas.drawLine(Offset(rightHipX, rightHipY), Offset(rightKneeX, rightKneeY), paint);
    canvas.drawLine(Offset(rightKneeX, rightKneeY), Offset(rightFootX, rightFootY), paint);
  }

  @override
  bool shouldRepaint(RestingPersonPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
